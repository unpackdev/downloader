//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  Copyright 2021 Archer DAO: Chris Piatt (chris@archerdao.io).
*/

import "./IERC20Extended.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV3Pool.sol";
import "./IUniV3Router.sol";
import "./IWETH.sol";
import "./RouteLib.sol";
import "./TransferHelper.sol";
import "./SafeCast.sol";
import "./Path.sol";
import "./CallbackValidation.sol";
import "./ArchRouterImmutableState.sol";
import "./PaymentsWithFee.sol";
import "./Multicall.sol";
import "./SelfPermit.sol";

/**
 * @title ArcherSwapRouter
 * @dev Allows Uniswap V2/V3 Router-compliant trades to be paid via tips instead of gas
 */
contract ArcherSwapRouter is
    IUniV3Router,
    ArchRouterImmutableState,
    PaymentsWithFee,
    Multicall,
    SelfPermit
{
    using Path for bytes;
    using SafeCast for uint256;

    /// @dev Used as the placeholder value for amountInCached, because the computed amount in for an exact output swap
    /// can never actually be this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Trade details
    struct Trade {
        uint amountIn;
        uint amountOut;
        address[] path;
        address payable to;
        uint256 deadline;
    }

    /// @notice Uniswap V3 Swap Callback 
    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    /**
     * @notice Construct new ArcherSwap Router
     * @param _uniV3Factory Uni V3 Factory address
     * @param _WETH WETH address
     */
    constructor(address _uniV3Factory, address _WETH) ArchRouterImmutableState(_uniV3Factory, _WETH) {}

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function swapExactTokensForETHAndTipAmount(
        address factory,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        require(trade.path[trade.path.length - 1] == WETH, 'ArchRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            trade.path[0], msg.sender, RouteLib.pairFor(factory, trade.path[0], trade.path[1]), trade.amountIn
        );
        _exactInputSwap(factory, trade.path, address(this));
        uint256 amountOut = IWETH(WETH).balanceOf(address(this));
        require(amountOut >= trade.amountOut, 'ArchRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);

        tip(tipAmount);
        TransferHelper.safeTransferETH(trade.to, amountOut - tipAmount);
    }

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function swapTokensForExactETHAndTipAmount(
        address factory,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        require(trade.path[trade.path.length - 1] == WETH, 'ArchRouter: INVALID_PATH');
        uint[] memory amounts = RouteLib.getAmountsIn(factory, trade.amountOut, trade.path);
        require(amounts[0] <= trade.amountIn, 'ArchRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            trade.path[0], msg.sender, RouteLib.pairFor(factory, trade.path[0], trade.path[1]), amounts[0]
        );
        _exactOutputSwap(factory, amounts, trade.path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);

        tip(tipAmount);
        TransferHelper.safeTransferETH(trade.to, trade.amountOut - tipAmount);
    }

    /**
     * @notice Swap ETH for tokens and pay % of ETH input as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     * @param tipAmount amount of ETH to pay as tip
     */
    function swapExactETHForTokensAndTipAmount(
        address factory,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        tip(tipAmount);
        require(trade.path[0] == WETH, 'ArchRouter: INVALID_PATH');
        uint256 inputAmount = msg.value - tipAmount;
        IWETH(WETH).deposit{value: inputAmount}();
        assert(IWETH(WETH).transfer(RouteLib.pairFor(factory, trade.path[0], trade.path[1]), inputAmount));
        uint256 balanceBefore = IERC20Extended(trade.path[trade.path.length - 1]).balanceOf(trade.to);
        _exactInputSwap(factory, trade.path, trade.to);
        require(
            IERC20Extended(trade.path[trade.path.length - 1]).balanceOf(trade.to) - balanceBefore >= trade.amountOut,
            'ArchRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @notice Swap ETH for tokens and pay amount of ETH input as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     * @param tipAmount amount of ETH to pay as tip
     */
    function swapETHForExactTokensAndTipAmount(
        address factory,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        tip(tipAmount);
        require(trade.path[0] == WETH, 'ArchRouter: INVALID_PATH');
        uint[] memory amounts = RouteLib.getAmountsIn(factory, trade.amountOut, trade.path);
        uint256 inputAmount = msg.value - tipAmount;
        require(amounts[0] <= inputAmount, 'ArchRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(RouteLib.pairFor(factory, trade.path[0], trade.path[1]), amounts[0]));
        _exactOutputSwap(factory, amounts, trade.path, trade.to);

        if (inputAmount > amounts[0]) {
            TransferHelper.safeTransferETH(msg.sender, inputAmount - amounts[0]);
        }
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function swapExactTokensForTokensAndTipAmount(
        address factory,
        Trade calldata trade
    ) external payable {
        tip(msg.value);
        _swapExactTokensForTokens(factory, trade);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     * @param pathToEth Path to ETH for tip
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapExactTokensForTokensAndTipPct(
        address factory,
        Trade calldata trade,
        address[] calldata pathToEth,
        uint32 tipPct
    ) external payable {
        _swapExactTokensForTokens(factory, trade);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        TransferHelper.safeTransfer(pathToEth[0], trade.to, contractTokenBalance - tipAmount);
        _tipWithTokens(factory, pathToEth);
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function swapTokensForExactTokensAndTipAmount(
        address factory,
        Trade calldata trade
    ) external payable {
        tip(msg.value);
        _swapTokensForExactTokens(factory, trade);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     * @param pathToEth Path to ETH for tip
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapTokensForExactTokensAndTipPct(
        address factory,
        Trade calldata trade,
        address[] calldata pathToEth,
        uint32 tipPct
    ) external payable {
        _swapTokensForExactTokens(factory, trade);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        TransferHelper.safeTransfer(pathToEth[0], trade.to, contractTokenBalance - tipAmount);
        _tipWithTokens(factory, pathToEth);
    }

    /** 
     * @notice Returns the pool for the given token pair and fee. The pool contract may or may not exist.
     * @param tokenA First token
     * @param tokenB Second token
     * @param fee Pool fee
     * @return Uniswap V3 Pool 
     */ 
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(RouteLib.computeAddress(uniV3Factory, RouteLib.getPoolKey(tokenA, tokenB, fee)));
    }

    /**
     * @notice Uniswap V3 Callback function that validates and pays for trade
     * @dev Called by Uni V3 pool contract
     * @param amount0Delta Delta for token 0
     * @param amount1Delta Delta for token 1
     * @param _data Swap callback data
     */
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();
        CallbackValidation.verifyCallback(uniV3Factory, tokenIn, tokenOut, fee);

        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0
                ? (tokenIn < tokenOut, uint256(amount0Delta))
                : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) {
            pay(tokenIn, data.payer, msg.sender, amountToPay);
        } else {
            // either initiate the next swap or pay
            if (data.path.hasMultiplePools()) {
                data.path = data.path.skipToken();
                _exactOutputInternal(amountToPay, msg.sender, 0, data);
            } else {
                amountInCached = amountToPay;
                tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
                pay(tokenIn, data.payer, msg.sender, amountToPay);
            }
        }
    }

    /// @inheritdoc IUniV3Router
    function exactInputSingle(ExactInputSingleParams calldata params)
        public
        payable
        override
        returns (uint256 amountOut)
    {
        amountOut = _exactInputInternal(
            params.amountIn,
            params.recipient,
            params.sqrtPriceLimitX96,
            SwapCallbackData({path: abi.encodePacked(params.tokenIn, params.fee, params.tokenOut), payer: msg.sender})
        );
        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /**
     * @notice Performs a single exact input Uni V3 swap and tips an amount of ETH
     * @param params Swap params
     * @param tipAmount Tip amount
     */
    function exactInputSingleAndTipAmount(ExactInputSingleParams calldata params, uint256 tipAmount)
        external
        payable
        returns (uint256 amountOut)
    {
        amountOut = exactInputSingle(params);
        tip(tipAmount);
    }

    /// @inheritdoc IUniV3Router
    function exactInput(ExactInputParams memory params)
        public
        payable
        override
        returns (uint256 amountOut)
    {
        address payer = msg.sender; // msg.sender pays for the first hop

        while (true) {
            bool hasMultiplePools = params.path.hasMultiplePools();

            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = _exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
                0,
                SwapCallbackData({
                    path: params.path.getFirstPool(), // only the first pool in the path is necessary
                    payer: payer
                })
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this); // at this point, the caller has paid
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /**
     * @notice Performs multiple exact input Uni V3 swaps and tips an amount of ETH
     * @param params Swap params
     * @param tipAmount Tip amount
     */
    function exactInputAndTipAmount(ExactInputParams calldata params, uint256 tipAmount)
        external
        payable
        returns (uint256 amountOut)
    {
        amountOut = exactInput(params);
        tip(tipAmount);
    }

    /// @inheritdoc IUniV3Router
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        public
        payable
        override
        returns (uint256 amountIn)
    {
        // avoid an SLOAD by using the swap return data
        amountIn = _exactOutputInternal(
            params.amountOut,
            params.recipient,
            params.sqrtPriceLimitX96,
            SwapCallbackData({path: abi.encodePacked(params.tokenOut, params.fee, params.tokenIn), payer: msg.sender})
        );

        require(amountIn <= params.amountInMaximum, 'Too much requested');
        // has to be reset even though we don't use it in the single hop case
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /**
     * @notice Performs an exact output Uni V3 swap and tips an amount of ETH
     * @param params Swap params
     * @param tipAmount Tip amount
     */
    function exactOutputSingleAndTipAmount(ExactOutputSingleParams calldata params, uint256 tipAmount)
        external
        payable
        returns (uint256 amountIn)
    {
        amountIn = exactOutputSingle(params);
        tip(tipAmount);
    }

    /// @inheritdoc IUniV3Router
    function exactOutput(ExactOutputParams calldata params)
        public
        payable
        override
        returns (uint256 amountIn)
    {
        // it's okay that the payer is fixed to msg.sender here, as they're only paying for the "final" exact output
        // swap, which happens first, and subsequent swaps are paid for within nested callback frames
        _exactOutputInternal(
            params.amountOut,
            params.recipient,
            0,
            SwapCallbackData({path: params.path, payer: msg.sender})
        );

        amountIn = amountInCached;
        require(amountIn <= params.amountInMaximum, 'Too much requested');
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /**
     * @notice Performs multiple exact output Uni V3 swaps and tips an amount of ETH
     * @param params Swap params
     * @param tipAmount Tip amount
     */
    function exactOutputAndTipAmount(ExactOutputParams calldata params, uint256 tipAmount)
        external
        payable
        returns (uint256 amountIn)
    {
        amountIn = exactOutput(params);
        tip(tipAmount);
    }

    /**
     * @notice Performs a single exact input Uni V3 swap
     * @param amountIn Amount of input token
     * @param recipient Recipient of swap result
     * @param sqrtPriceLimitX96 Price limit
     * @param data Swap callback data
     */
    function _exactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256 amountOut) {
        // allow swapping to the router address with address 0
        if (recipient == address(0)) recipient = address(this);

        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) =
            getPool(tokenIn, tokenOut, fee).swap(
                recipient,
                zeroForOne,
                amountIn.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encode(data)
            );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    /**
     * @notice Performs a single exact output Uni V3 swap
     * @param amountOut Amount of output token
     * @param recipient Recipient of swap result
     * @param sqrtPriceLimitX96 Price limit
     * @param data Swap callback data
     */
    function _exactOutputInternal(
        uint256 amountOut,
        address recipient,
        uint160 sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256 amountIn) {
        // allow swapping to the router address with address 0
        if (recipient == address(0)) recipient = address(this);

        (address tokenOut, address tokenIn, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0Delta, int256 amount1Delta) =
            getPool(tokenIn, tokenOut, fee).swap(
                recipient,
                zeroForOne,
                -amountOut.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encode(data)
            );

        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == amountOut);
    }

    /**
     * @notice Internal implementation of swap tokens for tokens
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function _swapExactTokensForTokens(
        address factory,
        Trade calldata trade
    ) internal {
        TransferHelper.safeTransferFrom(
            trade.path[0], msg.sender, RouteLib.pairFor(factory, trade.path[0], trade.path[1]), trade.amountIn
        );
        uint balanceBefore = IERC20Extended(trade.path[trade.path.length - 1]).balanceOf(trade.to);
        _exactInputSwap(factory, trade.path, trade.to);
        require(
            IERC20Extended(trade.path[trade.path.length - 1]).balanceOf(trade.to) - balanceBefore >= trade.amountOut,
            'ArchRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @notice Internal implementation of swap tokens for tokens
     * @param factory Uniswap V2-compliant Factory contract
     * @param trade Trade details
     */
    function _swapTokensForExactTokens(
        address factory,
        Trade calldata trade
    ) internal {
        uint[] memory amounts = RouteLib.getAmountsIn(factory, trade.amountOut, trade.path);
        require(amounts[0] <= trade.amountIn, 'ArchRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            trade.path[0], msg.sender, RouteLib.pairFor(factory, trade.path[0], trade.path[1]), amounts[0]
        );
        _exactOutputSwap(factory, amounts, trade.path, trade.to);
    }

    /**
     * @notice Internal implementation of exact input Uni V2/Sushi swap
     * @param factory Uniswap V2-compliant Factory contract
     * @param path Trade path
     * @param _to Trade recipient
     */
    function _exactInputSwap(
        address factory, 
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = RouteLib.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(RouteLib.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            {
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20Extended(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = RouteLib.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? RouteLib.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /**
     * @notice Internal implementation of exact output Uni V2/Sushi swap
     * @param factory Uniswap V2-compliant Factory contract
     * @param amounts Output amounts
     * @param path Trade path
     * @param _to Trade recipient
     */
    function _exactOutputSwap(
        address factory, 
        uint[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = RouteLib.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? RouteLib.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(RouteLib.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /**
     * @notice Convert a token balance into ETH and then tip
     * @param factory Factory address
     * @param path Path for swap
     */
    function _tipWithTokens(
        address factory,
        address[] memory path
    ) internal {
        _exactInputSwap(factory, path, address(this));
        uint256 amountOut = IWETH(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amountOut);

        tip(address(this).balance);
    }
}