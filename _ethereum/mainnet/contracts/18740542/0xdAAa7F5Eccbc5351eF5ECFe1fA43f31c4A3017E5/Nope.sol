// https://etherscan.io/

pragma solidity =0.8.19;

abstract contract ERC20 {

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    string public name;
    string public symbol;
    uint8 public immutable decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;
        unchecked {
            totalSupply -= amount;
        }
        emit Transfer(from, address(0), amount);
    }
}

abstract contract Ownable {

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/**
 * @notice Interface for UniV2 router.
 */
interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


contract Nope is Ownable, ERC20 {

  uint256 private constant MAX_SUPPLY = 100_000_000 ether;
  IUniswapV2Router02 public router;
  bool public hasLimits;
  address public pair;
  uint256 public maxBuy;
  bool init;

  error MaxBuy();
  error Init();

  constructor(address _routerAddress, string memory _name, string memory _symbol) ERC20(_name, _symbol, 18) Ownable(msg.sender) {
    router = IUniswapV2Router02(_routerAddress);
    hasLimits = true;
    maxBuy = MAX_SUPPLY / 100;
    pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
  }

  function addLiquidity() external payable onlyOwner {
    if(init) {
      revert Init();
    }
    _mint(address(this), MAX_SUPPLY);
    _approve(address(this), address(router), type(uint256).max);
    router.addLiquidityETH{
      value: msg.value
    }(address(this), MAX_SUPPLY, 0, 0, msg.sender, block.timestamp);
    init = true;
  }

  function removeLimits() external onlyOwner {
    hasLimits = false;
  }

  function transfer(address to, uint256 amount) public override returns (bool) {
    _limits(msg.sender, to, amount);
    return super.transfer(to, amount);
  }

  function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
    _limits(from, to, amount);
    return super.transferFrom(from, to, amount);
  }

  function _limits(address sender, address recipient, uint256 amount) private view {
    if (hasLimits && sender != owner && sender != address(this)) {
        if (!_immune(recipient) && balanceOf[recipient] + amount > maxBuy) {
            revert MaxBuy();
        }
    }
  }

  function _immune(address receiver) private view returns (bool) {
    return
        receiver == address(this) ||
        receiver == pair ||
        receiver == address(router) ||
        receiver == address(0) ||
        receiver == address(0xdead) ||
        receiver == owner;
  }
}