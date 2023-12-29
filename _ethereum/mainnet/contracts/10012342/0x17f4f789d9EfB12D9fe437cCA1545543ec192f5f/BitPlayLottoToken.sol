pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender,uint256 value);
}

contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

library SafeMath {

  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    //assert(a == 0 || c / a == b);
     require(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    //assert(b > 0);
    require(b > 0);
    uint256 c = a / b;
    //assert(a == b * c + a % b);
    require(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b <= a);
     require(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    //assert(c>=a && c>=b);
    require(c>=a && c>=b);
    return c;
  }
/*
  function assert(bool assertion) internal {
    if (!assertion) {
      //throw;
      revert();
    }
  }*/
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner,address _spender)public view returns (uint256)
  {
    return allowed[_owner][_spender];
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }
  
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.safeAdd(_amount);
    balances[_to] = balances[_to].safeAdd(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

}

contract BitPlayLottoToken is MintableToken {
  string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;
 uint256 public deploymentTime = now;
 uint256 public burnTime ;

    mapping (address => bool) public frozenAccount;
   
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;
    //event increaseSupply(uint amount);
    event Burn(address indexed from, uint256 value);
    
    

    /* Initializes contract with initial supply tokens to the creator of the contract */
   
   // function FinalToken(
       constructor(
        uint256 initialSupply
       // string tokenName,
        //uint8 decimalUnits,
        //string tokenSymbol
        ) public {
        initialSupply =21000000000*100000000; 
        balanceOf[msg.sender] = initialSupply;             // Give the creator all initial tokens
        //totalSupply = 10000000000;                         // Update total supply
        totalSupply = initialSupply;
        name = "BitPlayLotto";                                   // Set the name for display purposes
        symbol = "BPL";                               // Set the symbol for display purposes
        decimals = 8;                            // Amount of decimals for display purposes
		owner = msg.sender;
		 emit Transfer(0x0, owner, totalSupply);
    }

    function increaseSupply(uint value) public returns (bool) {
        if (msg.sender != owner) throw;
        totalSupply = SafeMath.safeAdd(totalSupply, value); // throws if overflow
        balanceOf[owner] = SafeMath.safeAdd(balanceOf[owner], value);  // throws if overflow
        return true;
    }
    
    /* Send coins */
    function transfer(address _to, uint256 _value) public {
       require (_to == 0x0);  
      //if (_to == 0x0) throw; 
		//if (_value <= 0) throw; 
		require (_value <= 0);
       // if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
       // if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        require (balanceOf[msg.sender] < _value);           
        require (balanceOf[_to] + _value < balanceOf[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
       emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		require (_value <= 0) ; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
        require (_to == 0x0);                                // Prevent transfer to 0x0 address. Use burn() instead
	require (_value <= 0); 
        require (balanceOf[_from] < _value);                 // Check if the sender has enough
       require (balanceOf[_to] + _value < balanceOf[_to]);  // Check for overflows
        require (_value > allowance[_from][msg.sender]);     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
       emit Transfer(_from, _to, _value);
        return true;
    }

     function burn(uint256 _value) public returns (bool success) {
      if (burnTime <= now)
      {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
      }
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
	
	// can accept ether
	function()public payable {
    }

}