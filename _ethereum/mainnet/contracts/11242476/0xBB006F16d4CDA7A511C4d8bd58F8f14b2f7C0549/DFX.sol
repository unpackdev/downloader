pragma solidity 0.4.18;


//Library
library SafeMath {

    //Functions
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } 
        uint256 c = a * b; 
        assert(c / a == b); 
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b; 
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a); 
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; 
        assert(c >= a); 
        return c;
    }
}

contract RespectingBitcoin {
    using SafeMath for uint256;
    
    //Variables

    uint8 public decimals;
    
    address public owner;
    
    address public deflaxPioneers;
    
    uint256 public supplyCap;
    uint256 public totalSupply;
    
    bool private mintable = true;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    //Events

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Mintable(address indexed from, bool enabled);
    event OwnerChanged(address newOwner);
    event ContractChanged(address indexed from, address newContract);

    //Modifiers

    modifier oO(){
        require(msg.sender == owner);
        _;
    }
    
    modifier oOOrContract(){
        require(msg.sender == owner || msg.sender == deflaxPioneers); 
        _;
    }
    
    modifier onlyMintable() {
        require(mintable); 
        _;
    }
    
    //Constructor
    
    function RespectingBitcoin(uint256 _supplyCap, uint8 _decimals) public {
        owner = msg.sender; 
        decimals = _decimals;
        supplyCap = _supplyCap * (10 ** uint256(decimals));
    }
    
    //Functions

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0)); 
        require(_value <= balances[msg.sender]); 
        
        balances[msg.sender] = balances[msg.sender].sub(_value); 
        balances[_to] = balances[_to].add(_value); 
        
        Transfer(msg.sender, _to, _value); 
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0)); 
        require(_value <= balances[_from]); 
        require(_value <= allowed[_from][msg.sender]); 
        
        balances[_from] = balances[_from].sub(_value); 
        balances[_to] = balances[_to].add(_value); 
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); 
        
        Transfer(_from, _to, _value); 
        return true;
    }
   
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value; 
        
        Approval(msg.sender, _spender, _value); 
        return true;
    }
   
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
  
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue); 
        
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
        return true;
    }
  
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender]; 
        
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        } 
        
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
        return true;
    }
  
    function mint(address _to, uint256 _amount) public oOOrContract onlyMintable returns (bool) {
        require(totalSupply.add(_amount) <= supplyCap); 
        
        totalSupply = totalSupply.add(_amount); 
        balances[_to] = balances[_to].add(_amount); 
        Mint(_to, _amount); 
        
        Transfer(address(0), _to, _amount); 
        return true;
    }
  
    function burn(uint256 _value) external {
        require(_value <= balances[msg.sender]); 
        
        address burner = msg.sender; 
        balances[burner] = balances[burner].sub(_value); 
        totalSupply = totalSupply.sub(_value);
        
        Burn(msg.sender, _value);
    }
    
    function setMintable(bool _isMintable) external oO {
        mintable = _isMintable;
        
        Mintable(msg.sender, _isMintable);
    }
    
    function setOwner(address _newOwner) external oO {
        require(_newOwner != address(0)); 
        
        owner = _newOwner;
        
        OwnerChanged(_newOwner);
    }
  
    function setContract(address _newContract) external oO {
        require(_newContract != address(0)); 
        
        deflaxPioneers = _newContract; 
        
        ContractChanged(msg.sender, _newContract);
    }
}

contract DFX is RespectingBitcoin(20968750, 15) {
    
    //Token Details
    
    string public constant name = "DEFLAx";
    string public constant symbol = "DFX";
}

contract bDFP is RespectingBitcoin(3355, 8) {
    
    //Token Details
    
    string public constant name = "DEFLAxP";
    string public constant symbol = "bDFP";
}