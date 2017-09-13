pragma solidity ^0.4.11;
//Copyright by Kochergin Valery

contract artToken {
      function transfer(address _to, uint256 _value);
}

//Разрешешнные авторы которые могут добавлять фотографии
contract artToken_authors {

    address public owner;
    uint public authors_count;
    address public last_author;
    mapping (uint => address) public authorIterator;

    mapping (address => bool) public authors;


    function artToken_authors() {
       //Назначить владельца контракта
       owner = msg.sender;
       addAuthor( owner );
    }

    function isAllowedAuthors(address _author) constant returns (bool allowed){
          return authors[ _author ];
    }


    function addAuthor( address _newAuthor ) onlyOwner{
          authors[ _newAuthor ] = true;
          authorIterator[ authors_count ] = _newAuthor;
          authors_count++;
          last_author = _newAuthor;
   }

   function removeAuthor( address _author ) onlyOwner{
         authors[ _author ] = false;
         authors_count--;
  }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }

}

contract artToken_base {
          address public owner;
          address public allow;

          //Картинки автора
          /*mapping (address => Picture[] ) public authorPictures;*/
          mapping (address => bytes32[] ) public authorPictures;

          //хэш Картины => Токены картинок
          /*mapping (uint => PictureToken[] ) public pictureTokens;*/
          mapping (bytes32 => bytes32[] ) public pictureTokens;

          //хеш картины => данные картины
          mapping (bytes32 => Picture ) public pictures;

          //хеш токена => данные токена
          mapping (bytes32 => Token ) public tokens;



          //Список авторов
          mapping (uint => address) public authorPicturesIterator;
          mapping (uint => bytes32) public picturesIterator;
          mapping (uint => bytes32) public tokenIterator;

          //токен картины=>картина (к какому объекту принадлежит токен)
          mapping (uint => uint) public parentToken;

          //hashPic => numPic
          /*mapping (bytes32 => uint) public hashPics;

          //hashTokenPic => numToken
          mapping (bytes32 => uint) public hashTokens;*/

          //токен картины=>провенанс
          mapping (bytes32 => Provenance[] ) public provenance;

          uint public authorCount;
          uint public picturesCount;
          uint public tokensCount;

          function artToken_base() {
             //Назначить владельца контракта
             owner = msg.sender;
             picturesCount = 0;
             authorCount = 0;
             tokensCount = 0;
          }


          struct Picture{
                uint tokenCount;
                uint quota;
                uint timeAdd;
                bytes32 hashDesc;
                address author;
                uint pictureType;
          }

          /*struct PictureToken{*/
          struct Token{
                bytes32 hashPic;
                bytes32 hashDesc;
                address owner;
                uint price;
                uint timeAdd;
                uint state;
                address author;
          }

          struct Provenance{
                address createBy;
                string act;
                string desc;
                uint timeAdd;
                /*bytes32 hashProven;*/
          }

          //Создать картину

          function createPicture( address _author, bytes32 _hashPic, uint _quota, bytes32 _hashDesc, uint _pictureType ) onlyAllow{
          /*function createPicture( address _author, bytes32 _hashPic, uint _quota, bytes32 _hashDesc ) onlyAllow{*/

               //Записать картинку к автору
                authorPictures[_author].length++;
                uint countPicture = authorPictures[_author].length;
                authorPictures[_author][ countPicture - 1 ] = _hashPic;


                pictures[ _hashPic ].tokenCount = 0;
                pictures[ _hashPic ].quota = _quota;
                pictures[ _hashPic ].timeAdd = now;
                pictures[ _hashPic ].hashDesc = _hashDesc;
                pictures[ _hashPic ].author = _author;
                pictures[ _hashPic ].pictureType = _pictureType;

                //Сколько всего авторов загрузили работы
                if( countPicture - 1 == 0){
                      authorCount++;
                      authorPicturesIterator[ authorCount - 1 ] = _author;
                }

                //Кол-во загруженных картинок
                picturesCount++;

                picturesIterator[ picturesCount - 1 ] = _hashPic;


          }

          //Создать токен
          function createPictureToken(address _author, bytes32 _hashPic, bytes32 _hashToken, bytes32 _hashDesc, uint _price) onlyAllow{

                tokensCount++;

                tokenIterator[ tokensCount - 1 ] = _hashToken;

                tokens[ _hashToken ].hashPic = _hashPic;
                tokens[ _hashToken ].hashDesc = _hashDesc;
                tokens[ _hashToken ].owner = _author;
                tokens[ _hashToken ].author = _author;
                tokens[ _hashToken ].price = _price;
                tokens[ _hashToken ].timeAdd = now;
                tokens[ _hashToken ].state = 1;


                //Список токенов картины
                pictureTokens[_hashPic].length++;
                var countTokens = pictureTokens[_hashPic].length;
                pictureTokens[ _hashPic ][ countTokens - 1 ] = _hashToken;

                //Увеличить кол-во токенов картины
                pictures[ _hashPic ].tokenCount++;

                addProvenance( _hashToken, "tokenCreate", _author, "Create picture token" );
                addProvenance( _hashToken, "setOwner", _author, addressToString( _author ) );
         }

         function addProvenance( bytes32 _hashToken, string _act, address _createBy, string _desc ) private {
               provenance[ _hashToken ].length++;
               uint countProvenance = provenance[ _hashToken ].length;
               //Записать провенанс
               provenance[ _hashToken ][ countProvenance - 1 ].createBy = _createBy;
               provenance[ _hashToken ][ countProvenance - 1 ].act = _act;
               provenance[ _hashToken ][ countProvenance - 1 ].desc = _desc;
               provenance[ _hashToken ][ countProvenance - 1 ].timeAdd = now;

         }

         function changePictureTokenOwner( bytes32 _hashToken, address _authorChange, address _toOwner ) onlyAllow {
            /*uint uniqNum = parentToken[ _tokenNum ];*/
            uint stateNow = tokens[ _hashToken ].state;

            require( stateNow == 1 );

            tokens[ _hashToken ].owner = _toOwner;
            tokens[ _hashToken ].state = 0;
            uint priceNow = tokens[ _hashToken ].price;

            addProvenance( _hashToken, "buyPriceArt", _authorChange, uintToString( priceNow ) );
            addProvenance( _hashToken, "setOwner", _authorChange, addressToString( _toOwner ) );
         }

         function changeSalePriceState( bytes32 _hashToken, uint _price, uint _state ) onlyAllow{
            /*_authorChange;*/
            /*uint uniqNum = parentToken[ _tokenNum ];*/

            uint priceNow = tokens[ _hashToken ].price;
            uint stateNow = tokens[ _hashToken ].state;

            if( priceNow != _price ){
                  tokens[ _hashToken ].price = _price;
            }

            if( stateNow != _state ){
                  tokens[ _hashToken ].state = _state;
            }


         }

         function addProvenanceOutside( bytes32 _hashToken, string _act, address _createBy, string _desc ) onlyAllow {
               addProvenance( _hashToken, _act, _createBy, _desc );
         }


         function getAuthorPictureCount( address _author ) public constant returns(uint) {
              return authorPictures[_author].length;
         }

        function getPictureTokenCount( bytes32 _hashPic ) public constant returns(uint) {
              return pictureTokens[ _hashPic ].length;
         }

         function getProvenanceCount( bytes32 _hashToken ) public constant returns(uint) {
               return provenance[ _hashToken ].length;
          }


      function addressToString(address x) constant returns (string) {
                bytes memory s = new bytes(40);
                for (uint i = 0; i < 20; i++) {
                    byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
                    byte hi = byte(uint8(b) / 16);
                    byte lo = byte(uint8(b) - 16 * uint8(hi));
                    s[2*i] = char(hi);
                    s[2*i+1] = char(lo);
                }
                return string(s);
            }

            function char(byte b) returns (byte c) {
                if (b < 10) return byte(uint8(b) + 0x30);
                else return byte(uint8(b) + 0x57);
            }

         function uintToString(uint v) constant returns (string str) {
              uint maxlength = 100;
              bytes memory reversed = new bytes(maxlength);
              uint i = 0;
              while (v != 0) {
                  uint remainder = v % 10;
                  v = v / 10;
                  reversed[i++] = byte(48 + remainder);
              }
              bytes memory s = new bytes(i + 1);
              for (uint j = 0; j <= i; j++) {
                  s[j] = reversed[i - j];
              }
              str = string(s);
          }

          modifier onlyAllow() {
              require(msg.sender == allow);
              _;
          }

          function transferAllow(address _new) onlyOwner {
              allow = _new;
          }

          modifier onlyOwner() {
              require(msg.sender == owner);
              _;
          }

          function transferOwnership(address newOwner) onlyOwner {
              owner = newOwner;
          }

}


//Создание токенов фотографии и хранение
contract artToken_pictureCreator {
    /* Public variables of the token */
    address public owner;
    string public log;
    /*uint g = b * (10 ** uint(decimals));*/
    uint8 public constant decimals = 8;

    address public tokenContract = 0x5d9b54f7861337aE45F7a020668a6dA299328d19;
    address public baseContract = 0x9447fa7afEE355b7A9CE15822c689Fa1b74c416a;
    address public authorsContract = 0x60daBa949D2E6111c5C3F3D45f6162Fdc97e2Bb1;
    address public artexFund = 0x00380Af0C92BeeDA2B267fe7631eC4B3115DCe64;

    uint public artex_percent = 10; // 10 = 1%
    uint public author_percent = 10; // 10 = 1%


    function artToken_pictureCreator() {
       owner = msg.sender;
    }

    /*modifier isAuthorAllowed() {*/
    function isAuthorAllowed( address _author ) constant returns (bool) {
          require(_author != 0x0 );
          require( authorsContract != 0x0 );
          artToken_authors contractA = artToken_authors( authorsContract );
          return contractA.isAllowedAuthors(_author) ;
    }

    function changeArtexPercent( uint percent ) onlyOwner{
          require( percent <= 20 ); // 20 = 2%
          require( percent >= 0 );
          artex_percent = percent;
   }

   function changeAuthorPercent( uint percent ) onlyOwner{
         require( percent <= 20 ); // 20 = 2%
         require( percent >= 0 );
         author_percent = percent;
  }

    function changeTokenContract( address _new ) onlyOwner {
          tokenContract = _new;
    }

    function changeAuthorsContract( address _new ) onlyOwner {
          authorsContract = _new;
    }

    function changeBaseContract( address _new ) onlyOwner {
          baseContract = _new;
    }

    function changeArtexFund( address _new ) onlyOwner {
          artexFund = _new;
    }

    function send_toFund( uint _amount ) onlyOwner{
          artToken contractArtToken = artToken( tokenContract );
          contractArtToken.transfer( artexFund, _amount );
    }

    //Создать картину
    function transfered(address _author, uint _amount, bytes32[] _data) onlyTokenContract {
          require(_author != 0x0 );
          uint act = stringToUint( bytes32ToString( _data[0] ) );



          //Authors create picture
          if( act == 10 ){

                artToken_base contractB = artToken_base( baseContract );
                require( isAuthorAllowed( _author ) == true );

                bytes32 hashPic = _data[1];
                uint quota = stringToUint( bytes32ToString( _data[2] ) );
                bytes32 hashDesc = _data[3];
                uint pictureType = stringToUint( bytes32ToString( _data[4] ));

                require(quota > 0 );
                require(_amount == 1000000000 ); //10 ART

                contractB.createPicture( _author, hashPic, quota, hashDesc, pictureType );
                /*contractB.createPicture( _author, hashPic, quota, hashDesc );*/

                artToken contractArtToken = artToken( tokenContract );
                contractArtToken.transfer( artexFund, 1000000000 );


          //Create picture token
         }else if( act == 15 ){
               require( _amount == 100000000 ); //1 ART

               createPictureToken( _author, _data[1], _data[2], _data[3], _data[4]);

          //Author buy picture token
          }else if( act == 20 ){

                buyPictureToken( _author, _data[1], _amount );

                /*bytes32 hashToken = _data[1];
                address toNewOwner = _author;

                var ( picOwner, picAuthor, token_price ) = getTokenPrice( hashToken );

                require( _amount == token_price );

                uint artex_reward = _amount * 1 / 100;
                uint author_reward = _amount * 5 / 1000;
                uint owner_reward = _amount - artex_reward - author_reward;
                contractArtToken.transfer( artexFund, artex_reward );
                contractArtToken.transfer( picAuthor, author_reward );
                contractArtToken.transfer( picOwner, owner_reward );

                contractB.changePictureTokenOwner( hashToken, picOwner, toNewOwner );*/
          } else{
                require( 0 == 1 );
          }
   }

    function getTokenPrice( bytes32 hashToken ) constant returns (address, address, uint){
        artToken_base contractB = artToken_base( baseContract );
        var (token_hashPic, token_hashDesc, token_owner, token_price, token_timeAdd, token_state, token_author) = contractB.tokens( hashToken );
        token_hashPic;
        token_hashDesc;
        token_timeAdd;
        token_state;
        return (token_owner, token_author, token_price);
    }

    function getTokenPrice2_start( bytes32 _hashToken ) constant returns (address, address, uint, uint){
         var ( picOwner, picAuthor, token_price ) = getTokenPrice( _hashToken );
         uint artToken_price = token_price * (10 ** uint(decimals));
         return ( picOwner, picAuthor, token_price, artToken_price );
    }

   //Создать токен
   function createPictureToken(address _author, bytes32 _hashPic, bytes32 _hashToken, bytes32 _hashDesc, bytes32 _price) private {
         artToken contractArtToken = artToken( tokenContract );
         artToken_base contractB = artToken_base( baseContract );

         uint price = stringToUint( bytes32ToString( _price ) );

         contractB.createPictureToken( _author, _hashPic, _hashToken, _hashDesc, price);
         contractArtToken.transfer( artexFund, 100000000 ); // 1ART

  }

  //Купить токен
   function buyPictureToken( address _author, bytes32 _hashToken, uint _amount ) private {
  /*function buyPictureToken(address _author, bytes32 _hashToken, bytes32 _hashDesc, bytes32 _price) private {*/
        artToken contractArtToken = artToken( tokenContract );
        artToken_base contractB = artToken_base( baseContract );

        /*bytes32 hashToken = _data[1];*/
        address toNewOwner = _author;

        var ( picOwner, picAuthor, token_price ) = getTokenPrice( _hashToken );
        uint artToken_price = token_price * (10 ** uint(decimals));
        require( _amount == artToken_price );

        uint artex_reward = _amount * artex_percent / 1000;
        uint author_reward = _amount * author_percent / 1000;
        uint owner_reward = _amount - artex_reward - author_reward;
        contractArtToken.transfer( artexFund, artex_reward );
        contractArtToken.transfer( picAuthor, author_reward );
        contractArtToken.transfer( picOwner, owner_reward );

        /*_amount;picAuthor;token_price;*/

        contractB.changePictureTokenOwner( _hashToken, picOwner, toNewOwner );

}

function bytes32ToString(bytes32 x) constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = x[j];
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function stringToUint(string s) constant returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyTokenContract() {
        require(msg.sender == tokenContract);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }

}
