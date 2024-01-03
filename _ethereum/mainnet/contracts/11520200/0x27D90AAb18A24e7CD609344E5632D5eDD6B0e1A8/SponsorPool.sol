pragma solidity =0.7.0;

contract SponsorPool {
    using SafeMathLT for uint256;

    address public owner;

    IERC20Token public tokenA;
    IERC20Token public tokenB;

    uint256 public maxTriggerTotal = 20 ether;
    uint256 public timeout = block.timestamp.add(2 hours);

    UniswapRouterV2 public constant UNISWAP_ROUTER = UniswapRouterV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // mainnet
    );
    
    event ReceiveETH(address account, uint256 amount);
    event SwapExactETHForTokens(uint256 balance, uint256 tokens);
    event AddLiquidity(uint256 amountA, uint256 amountB, uint256 liquidity);

    modifier onlyOwner() {
       require(msg.sender == owner, 'wrong sender');
        _;
    }

    constructor(IERC20Token _tokenA,IERC20Token _tokenB) {
        owner = msg.sender;
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    receive() external payable {
        emit ReceiveETH(msg.sender, msg.value);
    }

    function getTokensBalance()
        public
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 _aBalance = tokenA.balanceOf(address(this));
        uint256 _bBalance = tokenB.balanceOf(address(this));

        return (_aBalance, _bBalance);
    }

    function forwardLiquidity(/*🦄*/) public
    {
        if (address(this).balance > 0) {
            uint256[] memory amounts = UNISWAP_ROUTER.swapExactETHForTokens{value: address(this).balance}(0, getPath(), address(this), timeout);
            emit SwapExactETHForTokens(address(this).balance, amounts[1]);
        }
        
        uint256 _aBalance;
        uint256 _bBalance;

        (_aBalance, _bBalance) = getTokensBalance();

        if (_aBalance == 0 || _bBalance == 0) {
            return;
        }

        tokenA.approve(address(UNISWAP_ROUTER), _aBalance);
        tokenB.approve(address(UNISWAP_ROUTER), _bBalance);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = UNISWAP_ROUTER
            .addLiquidity(
            address(tokenA),
            address(tokenB),
            _aBalance,
            _bBalance,
            0,
            0,
            address(0x0),
            timeout
        );
        
        emit AddLiquidity(amountA, amountB, liquidity);
    }
    

    function getPath() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = UNISWAP_ROUTER.WETH();
        path[1] = address(tokenB);

        return path;
    }

    function setMaxTriggerTotal(uint256 _v) external onlyOwner {
        maxTriggerTotal = _v;
    }

    function setOwner(address _v) external onlyOwner {
        owner = _v;
    }
}

interface IUniswapV2Factory {

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (
        address pair
    );
}

interface IUniswapV2Pair {

    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function transfer(
        address to,
        uint256 value
    ) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function balanceOf(
        address owner
    ) external view returns (uint256);

    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
}

interface UniswapRouterV2 {
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenMax,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
        ) external returns (uint amountA, uint amountB, uint liquidity);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadlin
    ) external payable returns (
        uint[] memory amounts
    );
}

interface IERC20Token {
    function mint(address account, uint256 amount) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address account) external view returns (uint256);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);
}

library SafeMathLT {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "modulo by zero");
        return a % b;
    }
}