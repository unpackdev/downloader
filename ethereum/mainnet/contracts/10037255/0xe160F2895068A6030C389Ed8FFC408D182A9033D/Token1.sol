pragma solidity ^0.5.8;


//IERC20 Interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address, uint) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Owned Contract
contract Owned {
  modifier onlyOwner { 
    require(msg.sender == owner); 
    _; 
  }
  address public owner = msg.sender;
  
  event NewOwner(address indexed old, address indexed current);

  function setOwner(address _new) onlyOwner public { 
    emit NewOwner(owner, _new); 
    owner = _new; 
  }
}

// Token Contract
contract Token1 is IERC20, Owned {

    using SafeMath for uint256;

    // Coin Defaults
    string public name;                                         // Name of Coin
    string public symbol;                                       // Symbol of Coin
    uint256 public decimals  = 18;                              // Decimals
    uint256 public totalTokens  = 1000000 * (10 ** decimals);   // 1,000,000 Total

    // Mapping
    mapping(address => uint256) balances_;                          // Map balances
    mapping(address => mapping(address => uint256)) allowances_;    // Map allowances
    
    // Events
    event Approval(address indexed owner, address indexed spender, uint value); // ERC20
    event Transfer(address indexed from, address indexed to, uint256 value);    // ERC20

    // Minting event
    constructor() public{
        setOwner(msg.sender);
        balances_[msg.sender] = totalTokens;
        name = "Token";
        symbol  = "TKN";
        emit Transfer(address(0), msg.sender, totalTokens);
    }
    
    // ERC20
    function totalSupply() public view returns (uint256) {
        return totalTokens;
    }

    // ERC20
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances_[tokenOwner];
    }
    
    // ERC20
    function transfer(address to, uint256 value) public returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }

    // ERC20
    function approve(address spender, uint256 value) public returns (bool success) {
        allowances_[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    // Recommended fix for known attack on any ERC20
    function safeApprove(address _spender, uint256 _currentValue, uint256 _value) public returns (bool success) {
        // If current allowance for _spender is equal to _currentValue, then
        // overwrite it with _value and return true, otherwise return false.
        if (allowances_[msg.sender][_spender] == _currentValue) {
            return approve(_spender, _value);
        }
        return false;
    }

    // ERC20
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowances_[tokenOwner][spender];
    }

    // ERC20
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowances_[from][msg.sender]);
        allowances_[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    

    // Transfer function which includes the network fee
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balances_[_from] >= _value);
        require(balances_[_to].add(_value) >= balances_[_to]);                 // catch overflow       
        
        balances_[_from] = balances_[_from].sub(_value);                       // Subtract from sender         
        balances_[_to] = balances_[_to].add(_value);                            // Add to receiver
        
        emit Transfer(_from, _to, _value);                    // Transaction event            
    }

}