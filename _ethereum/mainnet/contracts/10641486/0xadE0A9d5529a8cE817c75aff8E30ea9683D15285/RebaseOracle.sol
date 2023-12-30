pragma solidity >=0.5.0;

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

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IRebaseableERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    
    function rebase(uint256 epoch, uint256 supplyDelta) external returns (uint256);

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
}

contract RebaseOracle is Ownable {
    using SafeMath for uint256;
    
    address public wethUSDCPair = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;  // Address of the IUniswapV2Pair for Weth / USDC;
    
    IERC20 public WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 public wethDecimals = 18;
    
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint256 public usdcDecimals = 6;
    
    uint256 public etherPricePrecision = 2;
    
    IUniswapV2Pair public wethTokenPool = IUniswapV2Pair(0x6c35c40447E8011a63aB05f088fa7cD914d66904); // Address of the IUniswapV2Pair for Weth / Token
    IRebaseableERC20 public TOKEN = IRebaseableERC20(0xf911a7ec46a2c6fa49193212fe4a2a9B95851c27);
    uint256 public tokenDecimals = 9;
    uint256 public tokenPricePrecision = 10;
    
    uint256 public lastRebase;
    uint256 public timeBetweenRebases = 24 hours;
    uint256 public lastExchangeRate = 0;
    
    constructor() public {
        lastRebase = now;
    }
    
    function calculateExchangeRate() public view returns(uint256) {
        uint256 WETHReserves_1 = WETH.balanceOf(wethUSDCPair);
        uint256 USDReserves = USDC.balanceOf(wethUSDCPair);
        
        // WETH decimals = 18, USDC decimals = 6
        // Adding 20 decimal places to USDC gives us the Ether price to a ten-thousandth.
        uint256 precision1 = wethDecimals - usdcDecimals + etherPricePrecision;
        uint256 usdEtherPrice = USDReserves.mul(10 ** precision1).div(WETHReserves_1);
        
        // WETH decimals = 18, Token decimals = 9 (for XAMP)
        uint256 WETHReserves_2 = WETH.balanceOf(address(wethTokenPool));
        uint256 TokenReserves = TOKEN.balanceOf(address(wethTokenPool));
        
        uint256 precision2 = wethDecimals - tokenDecimals + tokenPricePrecision;
        uint256 etherTokenPrice = WETHReserves_2.div(TokenReserves.mul(10 ** precision2));
        
        return usdEtherPrice * etherTokenPrice;
    }
}