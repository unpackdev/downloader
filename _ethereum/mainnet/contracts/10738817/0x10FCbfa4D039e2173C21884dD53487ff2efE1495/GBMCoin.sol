pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// Interface ERC20
// ----------------------------------------------------------------------------

contract IERC20 {
      
    function transfer(address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


// ----------------------------------------------------------------------------
// SAFE MATH LIBRARY
// ----------------------------------------------------------------------------


contract SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }     
    uint256 c = a * b;
    require(c / a == b); 
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;    
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;    
    require(c >= a);
    return c;
  }
}



// ----------------------------------------------------------------------------
// TOKEN
// ----------------------------------------------------------------------------

contract GBMCoin is IERC20, SafeMath{

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;    
    mapping(address => mapping(address => uint256)) public allowance;
    
    // initialize the contract
    constructor() public {
        name = "GBM Coin";
        symbol = "GBM";
        decimals = 18;
        totalSupply = 10000000000000000000000000000;            
        balanceOf[msg.sender] = totalSupply;        
    }
             
    /* Send coins */ 
    function transfer(address _to, uint256 _value) public returns (bool) {        
        require(_to != address(0x0)); // Prevent transfer to 0x0 address  OK     
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);        
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value);
        balanceOf[_to] = add(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0));
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
        
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);    
        require(_value <= balanceOf[_from]);                
        require(balanceOf[_to] + _value >= balanceOf[_to]);  // Check for overflows    
        require(_to != address(0));
        require(_value > 0);
        balanceOf[_from] = sub(balanceOf[_from], _value);
        balanceOf[_to] = add(balanceOf[_to], _value);
        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender], _value);        
        emit Transfer(_from, _to, _value);
        return true;
    }

}