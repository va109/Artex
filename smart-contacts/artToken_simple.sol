pragma solidity ^0.4.14;
contract tokenRecipient {
      function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract KnownContract {
      function transfered(address _sender, uint _amount, bytes32[] _data);
}

contract artToken {
    /* Public variables of the token */
    string public standard = 'ArtToken 0.1';
    string public constant name = "ArtToken";
    /*string public name;*/
    /*string public symbol;*/
    string public constant symbol = "ART";
    /*uint8 public decimals;*/
    uint8 public constant decimals = 8;
    uint public totalSupply = 100000000000000;
    string public log;

    address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public knowContracts;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function artToken(
        /*uint256 initialSupply*/
        /*string tokenName,
        uint8 decimalUnits,
        string tokenSymbol*/
        ) {
        /*totalSupply = initialSupply;                        // Update total supply*/
        balanceOf[msg.sender] = totalSupply;              // Give the creator all initial tokens
        /*name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes*/

        //Назначить владельца контракта
        owner = msg.sender;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        require(_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    //Доступ к разрешенным контрактам для операций с арткоином
    function transferToKnowContract( address _to, uint _amount, bytes32[] _data){
          var isContractAllowed = knowContracts[_to];
          require(isContractAllowed == true);
          transfer(_to, _amount);

          var knownContract = KnownContract(_to);
          knownContract.transfered(msg.sender, _amount, _data);

          //Добавить контракты в разрешенные
          //1. Добавление фотографии в базу
          //2. Продажа фотографии

   }

   function addKnowContract(address _knownContract) onlyOwner{
         knowContracts[_knownContract] = true;
   }


   function removeKnowContract(address _knownContract) onlyOwner{
         delete knowContracts[_knownContract];
   }

   modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(_to != 0x0);                                // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] > _value);                 // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require(_value < allowance[_from][msg.sender]);     // Check allowance
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] > _value);            // Check if the sender has enough
        balanceOf[msg.sender] -= _value;                      // Subtract from the sender
        totalSupply -= _value;                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        require(balanceOf[_from] > _value);                // Check if the sender has enough
        require(_value < allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        totalSupply -= _value;                               // Updates totalSupply
        Burn(_from, _value);
        return true;
    }
}
