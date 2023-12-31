// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
//pragma abicoder v2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";
import "./Math.sol";
//import "./IV3SwapRouter.sol";
//import "./console.sol";
//import "./ISwapRouter.sol";
//import "./TransferHelper.sol";
//import "./IUniswapV3Pool.sol";

interface IUniswapV3Pool {
    function initialize(uint160 sqrtPriceX96) external;
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}


interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        address recipient;
        uint deadline;
    }

    function mint(
        MintParams calldata params
    )
    external
    payable
    returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

    struct IncreaseLiquidityParams {
        uint tokenId;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint amount0, uint amount1);

    struct DecreaseLiquidityParams {
        uint tokenId;
        uint128 liquidity;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint amount0, uint amount1);

    struct CollectParams {
        uint tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(
        CollectParams calldata params
    ) external payable returns (uint amount0, uint amount1);
}

contract Hobo is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    uint public tax;
    uint256 public swapTokensAtAmount;
    uint256 public maxTaxSwap;
    address taxWallet;
    bool private swapping;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    address private constant UNISWAP_V3_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    ISwapRouter private uniswapRouter;
    IUniswapV3Factory constant UNI_FACTORY = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    address private constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet address. Adjust for different networks.
    address private constant NFPM_ADDRESS = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88; // Nonfungible Position Manager address, ensure to use the correct address for your network.

    INonfungiblePositionManager public positionManager;

    mapping(address => bool) private isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    constructor()
    ERC20("hobo", "HOBO")
    ERC20Permit("hobo")
    {
        uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);

        _mint(msg.sender, 1_000_000_000 * 10 ** decimals());

        taxWallet = msg.sender;
        tax = 50; // 5%
        swapTokensAtAmount = totalSupply() * 2 / 10000; // 0.02%
        maxTaxSwap = totalSupply() * 20 / 10000; // 0.2%

        uniswapRouter = ISwapRouter(UNISWAP_V3_ROUTER_ADDRESS);
        positionManager = INonfungiblePositionManager(NFPM_ADDRESS);

        createPool();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            automatedMarketMakerPairs[to] &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapping = true;
//            swapTokensForEth(Math.min(contractTokenBalance, maxTaxSwap));
            swapping = false;
        }

        bool takeFee = (tax > 0) && !swapping;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // Only take fees on buys/sells, do not take on wallet transfers
//        if (takeFee && (automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from])) {
        if (takeFee && automatedMarketMakerPairs[from]) {
            fees = (amount * tax) / 1000;
        }

        if (fees > 0) {
            super._transfer(from, address(this), fees);
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function setTaxPercent(uint newTax) public onlyOwner {
        require(newTax <= 50, "Can't set higher tax than 5%");
        tax = newTax;
    }

    function setMaxTaxSwap(uint256 newMax) public onlyOwner {
        maxTaxSwap = newMax;
    }

    function setTaxWallet(address newWallet) public onlyOwner {
        taxWallet = newWallet;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        automatedMarketMakerPairs[pair] = value;
    }

    IWETH private constant weth = IWETH(WETH_ADDRESS);

    int24 private constant MIN_TICK = - 887272;
    int24 private constant MAX_TICK = - MIN_TICK;
    int24 private constant TICK_SPACING = 60;

    INonfungiblePositionManager public nonfungiblePositionManager =
    INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    address private constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984; // V3 Factory address
    address private constant SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // V3 Swap Router address
    address private constant POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88; // V3 Nonfungible Position Manager address

    ISwapRouter public swapRouter;
    IUniswapV3Pool public poolObj;

    function createPool() private returns (address pool) {
        require(address(this) != address(0), "Token address is not valid");
        pool = UNI_FACTORY.createPool(address(this), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 3000); // ETH address and 0.3% fee
        poolObj = IUniswapV3Pool(pool);
        poolObj.initialize(17715955711429571636101120);
        setAutomatedMarketMakerPair(pool, true);
    }

    function mintNewPosition(
        uint amount0ToAdd, // my token
        uint amount1ToAdd // WETH
    ) public onlyOwner returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {

        transfer(address(this), amount0ToAdd);
        _approve(address(this), address(nonfungiblePositionManager), amount0ToAdd);
        weth.transferFrom(msg.sender, address(this), amount1ToAdd);
        weth.approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.MintParams
        memory params = INonfungiblePositionManager.MintParams({
            token0: address(this),
            token1: WETH_ADDRESS,
            fee: 3000,
            tickLower: - 168120,
            tickUpper: - 128940,
            amount0Desired: amount0ToAdd,
            amount1Desired: amount1ToAdd,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(
            params
        );
    }

    function swapTokensForEth(uint256 tokenAmount) public onlyOwner returns (uint256 amountOut) {
        _approve(address(this), UNISWAP_V3_ROUTER_ADDRESS, tokenAmount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
            tokenIn: address(this),
            tokenOut: WETH_ADDRESS,
            fee: 3000,
            recipient: address(taxWallet),
            deadline: block.timestamp,
            amountIn: tokenAmount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        amountOut = uniswapRouter.exactInputSingle(params);
    }

    function withdrawEth(address toAddr) public onlyOwner {
        (bool success,) = toAddr.call{
                value: address(this).balance
            } ("");
        require(success);
    }

}
