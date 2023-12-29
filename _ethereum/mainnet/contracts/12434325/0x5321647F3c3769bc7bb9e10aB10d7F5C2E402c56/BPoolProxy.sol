//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";
import "./IERC20.sol";
import "./ISwap.sol";
import "./IXToken.sol";
import "./IXTokenWrapper.sol";
import "./IBPool.sol";
import "./IBRegistry.sol";
import "./IProtocolFee.sol";
import "./IUTokenPriceFeed.sol";

/**
 * @title BPoolProxy
 * @author Protofire
 * @dev Forwarding proxy that allows users to batch execute swaps and join/exit pools.
 * User should interact with pools through this contracts as it is the one that charge
 * the protocol swap fee, and wrap/unwrap pool tokens into/from xPoolToken.
 *
 * This code is based on Balancer ExchangeProxy contract
 * https://docs.balancer.finance/smart-contracts/exchange-proxy
 * (https://etherscan.io/address/0x3E66B66Fd1d0b02fDa6C811Da9E0547970DB2f21#code)
 */
contract BPoolProxy is Ownable, ISwap, ERC1155Holder {
    using SafeMath for uint256;

    struct Pool {
        address pool;
        uint256 tokenBalanceIn;
        uint256 tokenWeightIn;
        uint256 tokenBalanceOut;
        uint256 tokenWeightOut;
        uint256 swapFee;
        uint256 effectiveLiquidity;
    }

    uint256 private constant BONE = 10**18;

    /// @dev Address of BRegistry
    IBRegistry public registry;
    /// @dev Address of ProtocolFee module
    IProtocolFee public protocolFee;
    /// @dev Address of XTokenWrapper
    IXTokenWrapper public xTokenWrapper;
    /// @dev Address of Utitlity Token Price Feed - Used as feature flag for discounted fee
    IUTokenPriceFeed public utilityTokenFeed;
    /// @dev Address who receives fees
    address public feeReceiver;
    /// @dev Address Utitlity Token - Used as feature flag for discounted fee
    address public utilityToken;

     /**
     * @dev Emitted when `joinPool` function is executed.
     */
    event JoinPool(address liquidityProvider, address bpool, uint256 shares);

    /**
     * @dev Emitted when `exitPool` function is executed.
     */
    event ExitPool(address iquidityProvider, address bpool, uint256 shares);

    /**
     * @dev Emitted when `registry` address is set.
     */
    event RegistrySet(address registry);

    /**
     * @dev Emitted when `protocolFee` address is set.
     */
    event ProtocolFeeSet(address protocolFee);

    /**
     * @dev Emitted when `feeReceiver` address is set.
     */
    event FeeReceiverSet(address feeReceiver);

    /**
     * @dev Emitted when `xTokenWrapper` address is set.
     */
    event XTokenWrapperSet(address xTokenWrapper);

    /**
     * @dev Emitted when `utilityToken` address is set.
     */
    event UtilityTokenSet(address utilityToken);

    /**
     * @dev Emitted when `utilityTokenFeed` address is set.
     */
    event UtilityTokenFeedSet(address utilityTokenFeed);

    /**
     * @dev Sets the values for {registry}, {protocolFee}, {feeReceiver},
     * {xTokenWrapper}, {utilityToken} and {utilityTokenFeed}.
     *
     * Sets ownership to the account that deploys the contract.
     *
     */
    constructor(
        address _registry,
        address _protocolFee,
        address _feeReceiver,
        address _xTokenWrapper,
        address _utilityToken,
        address _utilityTokenFeed
    ) {
        _setRegistry(_registry);
        _setProtocolFee(_protocolFee);
        _setFeeReceiver(_feeReceiver);
        _setXTokenWrapper(_xTokenWrapper);
        _setUtilityToken(_utilityToken);
        _setUtilityTokenFeed(_utilityTokenFeed);
    }

    /**
     * @dev Sets `_registry` as the new registry.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_registry` should not be the zero address.
     *
     * @param _registry The address of the registry.
     */
    function setRegistry(address _registry) external onlyOwner {
        _setRegistry(_registry);
    }

    /**
     * @dev Sets `_protocolFee` as the new protocolFee.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_protocolFee` should not be the zero address.
     *
     * @param _protocolFee The address of the protocolFee.
     */
    function setProtocolFee(address _protocolFee) external onlyOwner {
        _setProtocolFee(_protocolFee);
    }

    /**
     * @dev Sets `_feeReceiver` as the new feeReceiver.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_feeReceiver` should not be the zero address.
     *
     * @param _feeReceiver The address of the feeReceiver.
     */
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        _setFeeReceiver(_feeReceiver);
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new xTokenWrapper.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the xTokenWrapper.
     */
    function setXTokenWrapper(address _xTokenWrapper) external onlyOwner {
        _setXTokenWrapper(_xTokenWrapper);
    }

    /**
     * @dev Sets `_utilityToken` as the new utilityToken.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     *
     * @param _utilityToken The address of the utilityToken.
     */
    function setUtilityToken(address _utilityToken) external onlyOwner {
        _setUtilityToken(_utilityToken);
    }

    /**
     * @dev Sets `_utilityTokenFeed` as the new utilityTokenFeed.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     *
     * @param _utilityTokenFeed The address of the utilityTokenFeed.
     */
    function setUtilityTokenFeed(address _utilityTokenFeed) external onlyOwner {
        _setUtilityTokenFeed(_utilityTokenFeed);
    }

    /**
     * @dev Sets `_registry` as the new registry.
     *
     * Requirements:
     *
     * - `_registry` should not be the zero address.
     *
     * @param _registry The address of the registry.
     */
    function _setRegistry(address _registry) internal {
        require(_registry != address(0), "registry is the zero address");
        emit RegistrySet(_registry);
        registry = IBRegistry(_registry);
    }

    /**
     * @dev Sets `_protocolFee` as the new protocolFee.
     *
     * Requirements:
     *
     * - `_protocolFee` should not be the zero address.
     *
     * @param _protocolFee The address of the protocolFee.
     */
    function _setProtocolFee(address _protocolFee) internal {
        require(_protocolFee != address(0), "protocolFee is the zero address");
        emit ProtocolFeeSet(_protocolFee);
        protocolFee = IProtocolFee(_protocolFee);
    }

    /**
     * @dev Sets `_feeReceiver` as the new feeReceiver.
     *
     * Requirements:
     *
     * - `_feeReceiver` should not be the zero address.
     *
     * @param _feeReceiver The address of the feeReceiver.
     */
    function _setFeeReceiver(address _feeReceiver) internal {
        require(_feeReceiver != address(0), "feeReceiver is the zero address");
        emit FeeReceiverSet(_feeReceiver);
        feeReceiver = _feeReceiver;
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new xTokenWrapper.
     *
     * Requirements:
     *
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the xTokenWrapper.
     */
    function _setXTokenWrapper(address _xTokenWrapper) internal {
        require(_xTokenWrapper != address(0), "xTokenWrapper is the zero address");
        emit XTokenWrapperSet(_xTokenWrapper);
        xTokenWrapper = IXTokenWrapper(_xTokenWrapper);
    }

    /**
     * @dev Sets `_utilityToken` as the new utilityToken.
     *
     * @param _utilityToken The address of the utilityToken.
     */
    function _setUtilityToken(address _utilityToken) internal {
        emit UtilityTokenSet(_utilityToken);
        utilityToken = _utilityToken;
    }

    /**
     * @dev Sets `_utilityTokenFeed` as the new utilityTokenFeed.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     *
     * @param _utilityTokenFeed The address of the utilityTokenFeed.
     */
    function _setUtilityTokenFeed(address _utilityTokenFeed) internal {
        emit UtilityTokenFeedSet(_utilityTokenFeed);
        utilityTokenFeed = IUTokenPriceFeed(_utilityTokenFeed);
    }

    /**
     * @dev Execute single-hop swaps for swapExactIn trade type. Used for swaps
     * returned from viewSplit function and legacy off-chain SOR.
     *
     * @param swaps Array of single-hop swaps.
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param totalAmountIn Total amount of tokenIn.
     * @param minTotalAmountOut Minumum amount of tokenOut.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function batchSwapExactIn(
        Swap[] memory swaps,
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        bool useUtilityToken
    ) public returns (uint256 totalAmountOut) {
        transferFrom(tokenIn, totalAmountIn);

        for (uint256 i = 0; i < swaps.length; i++) {
            Swap memory swap = swaps[i];
            IXToken swapTokenIn = IXToken(swap.tokenIn);
            IBPool pool = IBPool(swap.pool);

            if (swapTokenIn.allowance(address(this), swap.pool) > 0) {
                swapTokenIn.approve(swap.pool, 0);
            }
            swapTokenIn.approve(swap.pool, swap.swapAmount);

            (uint256 tokenAmountOut, ) =
                pool.swapExactAmountIn(
                    swap.tokenIn,
                    swap.swapAmount,
                    swap.tokenOut,
                    swap.limitReturnAmount,
                    swap.maxPrice
                );
            totalAmountOut = tokenAmountOut.add(totalAmountOut);
        }

        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");

        transferFeeFrom(tokenIn, protocolFee.batchFee(swaps, totalAmountIn), useUtilityToken);

        transfer(tokenOut, totalAmountOut);
        transfer(tokenIn, getBalance(tokenIn));
    }

    /**
     * @dev Execute single-hop swaps for swapExactOut trade type. Used for swaps
     * returned from viewSplit function and legacy off-chain SOR.
     *
     * @param swaps Array of single-hop swaps.
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param maxTotalAmountIn Maximum total amount of tokenIn.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function batchSwapExactOut(
        Swap[] memory swaps,
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 maxTotalAmountIn,
        bool useUtilityToken
    ) public returns (uint256 totalAmountIn) {
        transferFrom(tokenIn, maxTotalAmountIn);

        for (uint256 i = 0; i < swaps.length; i++) {
            Swap memory swap = swaps[i];
            IXToken swapTokenIn = IXToken(swap.tokenIn);
            IBPool pool = IBPool(swap.pool);

            if (swapTokenIn.allowance(address(this), swap.pool) > 0) {
                swapTokenIn.approve(swap.pool, 0);
            }
            swapTokenIn.approve(swap.pool, swap.limitReturnAmount);

            (uint256 tokenAmountIn, ) =
                pool.swapExactAmountOut(
                    swap.tokenIn,
                    swap.limitReturnAmount,
                    swap.tokenOut,
                    swap.swapAmount,
                    swap.maxPrice
                );
            totalAmountIn = tokenAmountIn.add(totalAmountIn);
        }
        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");

        transferFeeFrom(tokenIn, protocolFee.batchFee(swaps, totalAmountIn), useUtilityToken);

        transfer(tokenOut, getBalance(tokenOut));
        transfer(tokenIn, getBalance(tokenIn));
    }

    /**
     * @dev Execute multi-hop swaps returned from off-chain SOR for swapExactIn trade type.
     *
     * @param swapSequences multi-hop swaps sequence.
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param totalAmountIn Total amount of tokenIn.
     * @param minTotalAmountOut Minumum amount of tokenOut.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        bool useUtilityToken
    ) external returns (uint256 totalAmountOut) {
        transferFrom(tokenIn, totalAmountIn);

        for (uint256 i = 0; i < swapSequences.length; i++) {
            uint256 tokenAmountOut;
            for (uint256 k = 0; k < swapSequences[i].length; k++) {
                Swap memory swap = swapSequences[i][k];
                IXToken swapTokenIn = IXToken(swap.tokenIn);
                if (k == 1) {
                    // Makes sure that on the second swap the output of the first was used
                    // so there is not intermediate token leftover
                    swap.swapAmount = tokenAmountOut;
                }

                IBPool pool = IBPool(swap.pool);
                if (swapTokenIn.allowance(address(this), swap.pool) > 0) {
                    swapTokenIn.approve(swap.pool, 0);
                }
                swapTokenIn.approve(swap.pool, swap.swapAmount);
                (tokenAmountOut, ) = pool.swapExactAmountIn(
                    swap.tokenIn,
                    swap.swapAmount,
                    swap.tokenOut,
                    swap.limitReturnAmount,
                    swap.maxPrice
                );
            }
            // This takes the amountOut of the last swap
            totalAmountOut = tokenAmountOut.add(totalAmountOut);
        }

        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");

        transferFeeFrom(tokenIn, protocolFee.multihopBatch(swapSequences, totalAmountIn), useUtilityToken);

        transfer(tokenOut, totalAmountOut);
        transfer(tokenIn, getBalance(tokenIn));
    }

    /**
     * @dev Execute multi-hop swaps returned from off-chain SOR for swapExactOut trade type.
     *
     * @param swapSequences multi-hop swaps sequence.
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param maxTotalAmountIn Maximum total amount of tokenIn.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 maxTotalAmountIn,
        bool useUtilityToken
    ) external returns (uint256 totalAmountIn) {
        transferFrom(tokenIn, maxTotalAmountIn);

        for (uint256 i = 0; i < swapSequences.length; i++) {
            uint256 tokenAmountInFirstSwap;
            // Specific code for a simple swap and a multihop (2 swaps in sequence)
            if (swapSequences[i].length == 1) {
                Swap memory swap = swapSequences[i][0];
                IXToken swapTokenIn = IXToken(swap.tokenIn);

                IBPool pool = IBPool(swap.pool);
                if (swapTokenIn.allowance(address(this), swap.pool) > 0) {
                    swapTokenIn.approve(swap.pool, 0);
                }
                swapTokenIn.approve(swap.pool, swap.limitReturnAmount);

                (tokenAmountInFirstSwap, ) = pool.swapExactAmountOut(
                    swap.tokenIn,
                    swap.limitReturnAmount,
                    swap.tokenOut,
                    swap.swapAmount,
                    swap.maxPrice
                );
            } else {
                // Consider we are swapping A -> B and B -> C. The goal is to buy a given amount
                // of token C. But first we need to buy B with A so we can then buy C with B
                // To get the exact amount of C we then first need to calculate how much B we'll need:
                uint256 intermediateTokenAmount; // This would be token B as described above
                Swap memory secondSwap = swapSequences[i][1];
                IBPool poolSecondSwap = IBPool(secondSwap.pool);
                intermediateTokenAmount = poolSecondSwap.calcInGivenOut(
                    poolSecondSwap.getBalance(secondSwap.tokenIn),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenIn),
                    poolSecondSwap.getBalance(secondSwap.tokenOut),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenOut),
                    secondSwap.swapAmount,
                    poolSecondSwap.getSwapFee()
                );

                //// Buy intermediateTokenAmount of token B with A in the first pool
                Swap memory firstSwap = swapSequences[i][0];
                IXToken firstswapTokenIn = IXToken(firstSwap.tokenIn);
                IBPool poolFirstSwap = IBPool(firstSwap.pool);
                if (firstswapTokenIn.allowance(address(this), firstSwap.pool) < uint256(-1)) {
                    firstswapTokenIn.approve(firstSwap.pool, uint256(-1));
                }

                (tokenAmountInFirstSwap, ) = poolFirstSwap.swapExactAmountOut(
                    firstSwap.tokenIn,
                    firstSwap.limitReturnAmount,
                    firstSwap.tokenOut,
                    intermediateTokenAmount, // This is the amount of token B we need
                    firstSwap.maxPrice
                );

                //// Buy the final amount of token C desired
                IXToken secondswapTokenIn = IXToken(secondSwap.tokenIn);
                if (secondswapTokenIn.allowance(address(this), secondSwap.pool) < uint256(-1)) {
                    secondswapTokenIn.approve(secondSwap.pool, uint256(-1));
                }

                poolSecondSwap.swapExactAmountOut(
                    secondSwap.tokenIn,
                    secondSwap.limitReturnAmount,
                    secondSwap.tokenOut,
                    secondSwap.swapAmount,
                    secondSwap.maxPrice
                );
            }
            totalAmountIn = tokenAmountInFirstSwap.add(totalAmountIn);
        }

        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");

        transferFeeFrom(tokenIn, protocolFee.multihopBatch(swapSequences, totalAmountIn), useUtilityToken);

        transfer(tokenOut, getBalance(tokenOut));
        transfer(tokenIn, getBalance(tokenIn));
    }

    /**
     * @dev Used for swaps returned from viewSplit function.
     *
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param totalAmountIn Total amount of tokenIn.
     * @param minTotalAmountOut Minumum amount of tokenOut.
     * @param nPools Maximum mumber of pools.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function smartSwapExactIn(
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        uint256 nPools,
        bool useUtilityToken
    ) external returns (uint256 totalAmountOut) {
        Swap[] memory swaps;
        uint256 totalOutput;
        (swaps, totalOutput) = viewSplitExactIn(address(tokenIn), address(tokenOut), totalAmountIn, nPools);

        require(totalOutput >= minTotalAmountOut, "ERR_LIMIT_OUT");

        totalAmountOut = batchSwapExactIn(swaps, tokenIn, tokenOut, totalAmountIn, minTotalAmountOut, useUtilityToken);
    }

    /**
     * @dev Used for swaps returned from viewSplit function.
     *
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param maxTotalAmountIn Maximum total amount of tokenIn.
     * @param nPools Maximum mumber of pools.
     * @param useUtilityToken Flag to determine if the protocol swap fee is paid using UtilityToken or TokenIn.
     */
    function smartSwapExactOut(
        IXToken tokenIn,
        IXToken tokenOut,
        uint256 totalAmountOut,
        uint256 maxTotalAmountIn,
        uint256 nPools,
        bool useUtilityToken
    ) external returns (uint256 totalAmountIn) {
        Swap[] memory swaps;
        uint256 totalInput;
        (swaps, totalInput) = viewSplitExactOut(address(tokenIn), address(tokenOut), totalAmountOut, nPools);

        require(totalInput <= maxTotalAmountIn, "ERR_LIMIT_IN");

        totalAmountIn = batchSwapExactOut(swaps, tokenIn, tokenOut, maxTotalAmountIn, useUtilityToken);
    }

    /**
     * @dev Join the `pool`, getting `poolAmountOut` pool tokens. This will pull some of each of the currently
     * trading tokens in the pool, meaning you must have called approve for each token for this pool. These
     * values are limited by the array of `maxAmountsIn` in the order of the pool tokens.
     *
     * @param pool Pool address.
     * @param poolAmountOut Exact pool amount out.
     * @param maxAmountsIn Maximum amounts in.
     */
    function joinPool(
        address pool,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) external {
        address[] memory tokens = IBPool(pool).getCurrentTokens();

        // pull xTokens
        for (uint256 i = 0; i < tokens.length; i++) {
            transferFrom(IXToken(tokens[i]), maxAmountsIn[i]);
            IXToken(tokens[i]).approve(pool, maxAmountsIn[i]);
        }

        IBPool(pool).joinPool(poolAmountOut, maxAmountsIn);

        // push remaining xTokens
        for (uint256 i = 0; i < tokens.length; i++) {
            transfer(IXToken(tokens[i]), getBalance(IXToken(tokens[i])));
        }

        // Wrap balancer liquidity tokens into its representing xToken
        IBPool(pool).approve(address(xTokenWrapper), poolAmountOut);
        require(xTokenWrapper.wrap(pool, poolAmountOut), "ERR_WRAP_POOL");

        transfer(IXToken(xTokenWrapper.tokenToXToken(pool)), poolAmountOut);

        emit JoinPool(msg.sender, pool,  poolAmountOut);
    }

    /**
     * @dev Exit the pool, paying poolAmountIn pool tokens and getting some of each of the currently trading
     * tokens in return. These values are limited by the array of minAmountsOut in the order of the pool tokens.
     *
     * @param pool Pool address.
     * @param poolAmountIn Exact pool amount int.
     * @param minAmountsOut Minumum amounts out.
     */
    function exitPool(
        address pool,
        uint256 poolAmountIn,
        uint256[] calldata minAmountsOut
    ) external {
        address wrappedLPT = xTokenWrapper.tokenToXToken(pool);

        // pull wrapped liquitity tokens
        transferFrom(IXToken(wrappedLPT), poolAmountIn);

        // unwrap wrapped liquitity tokens
        require(xTokenWrapper.unwrap(wrappedLPT, poolAmountIn), "ERR_UNWRAP_POOL");

        // LPT do not need to be approved when exit
        IBPool(pool).exitPool(poolAmountIn, minAmountsOut);

        // push xTokens
        address[] memory tokens = IBPool(pool).getCurrentTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            transfer(IXToken(tokens[i]), getBalance(IXToken(tokens[i])));
        }

        emit ExitPool(msg.sender, pool, poolAmountIn); 
    }

    /**
     * @dev Pay `tokenAmountIn` of token `tokenIn` to join the pool, getting `poolAmountOut` of the pool shares.
     *
     * @param pool Pool address.
     * @param tokenIn Input token.
     * @param tokenAmountIn Exact amount of tokenIn to pay.
     * @param minPoolAmountOut Minumum amount of pool shares to get.
     */
    function joinswapExternAmountIn(
        address pool,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut) {
        // pull xToken
        transferFrom(IXToken(tokenIn), tokenAmountIn);
        IXToken(tokenIn).approve(pool, tokenAmountIn);

        poolAmountOut = IBPool(pool).joinswapExternAmountIn(tokenIn, tokenAmountIn, minPoolAmountOut);

        // Wrap balancer liquidity tokens into its representing xToken
        IBPool(pool).approve(address(xTokenWrapper), poolAmountOut);
        require(xTokenWrapper.wrap(pool, poolAmountOut), "ERR_WRAP_POOL");

        transfer(IXToken(xTokenWrapper.tokenToXToken(pool)), poolAmountOut);

        emit JoinPool(msg.sender, pool,  poolAmountOut);
    }

    /**
     * @dev Specify `poolAmountOut` pool shares that you want to get, and a token `tokenIn` to pay with.
     * This costs `tokenAmountIn` tokens (these went into the pool).
     *
     * @param pool Pool address.
     * @param tokenIn Input token.
     * @param poolAmountOut Exact amount of pool shares to get.
     * @param maxAmountIn Minumum amount of tokenIn to pay.
     */
    function joinswapPoolAmountOut(
        address pool,
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external returns (uint256 tokenAmountIn) {
        // pull xToken
        transferFrom(IXToken(tokenIn), maxAmountIn);
        IXToken(tokenIn).approve(pool, maxAmountIn);

        tokenAmountIn = IBPool(pool).joinswapPoolAmountOut(tokenIn, poolAmountOut, maxAmountIn);

        // push remaining xTokens
        transfer(IXToken(tokenIn), getBalance(IXToken(tokenIn)));

        // Wrap balancer liquidity tokens into its representing xToken
        IBPool(pool).approve(address(xTokenWrapper), poolAmountOut);
        require(xTokenWrapper.wrap(pool, poolAmountOut), "ERR_WRAP_POOL");

        transfer(IXToken(xTokenWrapper.tokenToXToken(pool)), poolAmountOut);

        emit JoinPool(msg.sender, pool,  poolAmountOut);
    }

    /**
     * @dev Pay `poolAmountIn` pool shares into the pool, getting `tokenAmountOut` of the given
     * token `tokenOut` out of the pool.
     *
     * @param pool Pool address.
     * @param tokenOut Input token.
     * @param poolAmountIn Exact amount of pool shares to pay.
     * @param minAmountOut Minumum amount of tokenIn to get.
     */
    function exitswapPoolAmountIn(
        address pool,
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut) {
        address wrappedLPT = xTokenWrapper.tokenToXToken(pool);

        // pull wrapped liquitity tokens
        transferFrom(IXToken(wrappedLPT), poolAmountIn);

        // unwrap wrapped liquitity tokens
        require(xTokenWrapper.unwrap(wrappedLPT, poolAmountIn), "ERR_UNWRAP_POOL");

        // LPT do not need to be approved when exit
        tokenAmountOut = IBPool(pool).exitswapPoolAmountIn(tokenOut, poolAmountIn, minAmountOut);

        // push xToken
        transfer(IXToken(tokenOut), tokenAmountOut);

        emit ExitPool(msg.sender, pool, poolAmountIn);
    }

    /**
     * @dev Specify tokenAmountOut of token tokenOut that you want to get out of the pool.
     * This costs poolAmountIn pool shares (these went into the pool).
     *
     * @param pool Pool address.
     * @param tokenOut Input token.
     * @param tokenAmountOut Exact amount of of tokenIn to get.
     * @param maxPoolAmountIn Maximum amount of pool shares to pay.
     */
    function exitswapExternAmountOut(
        address pool,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn) {
        address wrappedLPT = xTokenWrapper.tokenToXToken(pool);

        // pull wrapped liquitity tokens
        transferFrom(IXToken(wrappedLPT), maxPoolAmountIn);

        // unwrap wrapped liquitity tokens
        require(xTokenWrapper.unwrap(wrappedLPT, maxPoolAmountIn), "ERR_UNWRAP_POOL");

        // LPT do not need to be approved when exit
        poolAmountIn = IBPool(pool).exitswapExternAmountOut(tokenOut, tokenAmountOut, maxPoolAmountIn);

        // push xToken
        transfer(IXToken(tokenOut), tokenAmountOut);

        uint256 remainingLPT = maxPoolAmountIn.sub(poolAmountIn);
        if (remainingLPT > 0) {
            // Wrap remaining balancer liquidity tokens into its representing xToken
            IBPool(pool).approve(address(xTokenWrapper), remainingLPT);
            require(xTokenWrapper.wrap(pool, remainingLPT), "ERR_WRAP_POOL");

            transfer(IXToken(wrappedLPT), remainingLPT);
        }

        emit ExitPool(msg.sender, pool, poolAmountIn);
    }

    /**
     * @dev View function that calculates most optimal swaps (exactIn swap type) across a max of nPools.
     * Returns an array of `Swaps` and the total amount out for swap.
     *
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param swapAmount Amount of tokenIn.
     * @param nPools Maximum mumber of pools.
     */
    function viewSplitExactIn(
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        uint256 nPools
    ) public view returns (Swap[] memory swaps, uint256 totalOutput) {
        address[] memory poolAddresses = registry.getBestPoolsWithLimit(tokenIn, tokenOut, nPools);

        Pool[] memory pools = new Pool[](poolAddresses.length);
        uint256 sumEffectiveLiquidity;
        for (uint256 i = 0; i < poolAddresses.length; i++) {
            pools[i] = getPoolData(tokenIn, tokenOut, poolAddresses[i]);
            sumEffectiveLiquidity = sumEffectiveLiquidity.add(pools[i].effectiveLiquidity);
        }

        uint256[] memory bestInputAmounts = new uint256[](pools.length);
        uint256 totalInputAmount;
        for (uint256 i = 0; i < pools.length; i++) {
            bestInputAmounts[i] = swapAmount.mul(pools[i].effectiveLiquidity).div(sumEffectiveLiquidity);
            totalInputAmount = totalInputAmount.add(bestInputAmounts[i]);
        }

        if (totalInputAmount < swapAmount) {
            bestInputAmounts[0] = bestInputAmounts[0].add(swapAmount.sub(totalInputAmount));
        } else {
            bestInputAmounts[0] = bestInputAmounts[0].sub(totalInputAmount.sub(swapAmount));
        }

        swaps = new Swap[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            swaps[i] = Swap({
                pool: pools[i].pool,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                swapAmount: bestInputAmounts[i],
                limitReturnAmount: 0,
                maxPrice: uint256(-1)
            });
        }

        totalOutput = calcTotalOutExactIn(bestInputAmounts, pools);

        return (swaps, totalOutput);
    }

    /**
     * @dev View function that calculates most optimal swaps (exactOut swap type) across a max of nPools.
     * Returns an array of Swaps and the total amount in for swap.
     *
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param swapAmount Amount of tokenIn.
     * @param nPools Maximum mumber of pools.
     */
    function viewSplitExactOut(
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        uint256 nPools
    ) public view returns (Swap[] memory swaps, uint256 totalInput) {
        address[] memory poolAddresses = registry.getBestPoolsWithLimit(tokenIn, tokenOut, nPools);

        Pool[] memory pools = new Pool[](poolAddresses.length);
        uint256 sumEffectiveLiquidity;
        for (uint256 i = 0; i < poolAddresses.length; i++) {
            pools[i] = getPoolData(tokenIn, tokenOut, poolAddresses[i]);
            sumEffectiveLiquidity = sumEffectiveLiquidity.add(pools[i].effectiveLiquidity);
        }

        uint256[] memory bestInputAmounts = new uint256[](pools.length);
        uint256 totalInputAmount;
        for (uint256 i = 0; i < pools.length; i++) {
            bestInputAmounts[i] = swapAmount.mul(pools[i].effectiveLiquidity).div(sumEffectiveLiquidity);
            totalInputAmount = totalInputAmount.add(bestInputAmounts[i]);
        }

        if (totalInputAmount < swapAmount) {
            bestInputAmounts[0] = bestInputAmounts[0].add(swapAmount.sub(totalInputAmount));
        } else {
            bestInputAmounts[0] = bestInputAmounts[0].sub(totalInputAmount.sub(swapAmount));
        }

        swaps = new Swap[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            swaps[i] = Swap({
                pool: pools[i].pool,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                swapAmount: bestInputAmounts[i],
                limitReturnAmount: uint256(-1),
                maxPrice: uint256(-1)
            });
        }

        totalInput = calcTotalOutExactOut(bestInputAmounts, pools);

        return (swaps, totalInput);
    }

    function getPoolData(
        address tokenIn,
        address tokenOut,
        address poolAddress
    ) internal view returns (Pool memory) {
        IBPool pool = IBPool(poolAddress);
        uint256 tokenBalanceIn = pool.getBalance(tokenIn);
        uint256 tokenBalanceOut = pool.getBalance(tokenOut);
        uint256 tokenWeightIn = pool.getDenormalizedWeight(tokenIn);
        uint256 tokenWeightOut = pool.getDenormalizedWeight(tokenOut);
        uint256 swapFee = pool.getSwapFee();

        uint256 effectiveLiquidity = calcEffectiveLiquidity(tokenWeightIn, tokenBalanceOut, tokenWeightOut);
        Pool memory returnPool =
            Pool({
                pool: poolAddress,
                tokenBalanceIn: tokenBalanceIn,
                tokenWeightIn: tokenWeightIn,
                tokenBalanceOut: tokenBalanceOut,
                tokenWeightOut: tokenWeightOut,
                swapFee: swapFee,
                effectiveLiquidity: effectiveLiquidity
            });

        return returnPool;
    }

    function calcEffectiveLiquidity(
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut
    ) internal pure returns (uint256 effectiveLiquidity) {
        // Bo * wi/(wi+wo)
        effectiveLiquidity = tokenWeightIn.mul(BONE).div(tokenWeightOut.add(tokenWeightIn)).mul(tokenBalanceOut).div(
            BONE
        );

        return effectiveLiquidity;
    }

    function calcTotalOutExactIn(uint256[] memory bestInputAmounts, Pool[] memory bestPools)
        internal
        pure
        returns (uint256 totalOutput)
    {
        totalOutput = 0;
        for (uint256 i = 0; i < bestInputAmounts.length; i++) {
            uint256 output =
                IBPool(bestPools[i].pool).calcOutGivenIn(
                    bestPools[i].tokenBalanceIn,
                    bestPools[i].tokenWeightIn,
                    bestPools[i].tokenBalanceOut,
                    bestPools[i].tokenWeightOut,
                    bestInputAmounts[i],
                    bestPools[i].swapFee
                );

            totalOutput = totalOutput.add(output);
        }
        return totalOutput;
    }

    function calcTotalOutExactOut(uint256[] memory bestInputAmounts, Pool[] memory bestPools)
        internal
        pure
        returns (uint256 totalOutput)
    {
        totalOutput = 0;
        for (uint256 i = 0; i < bestInputAmounts.length; i++) {
            uint256 output =
                IBPool(bestPools[i].pool).calcInGivenOut(
                    bestPools[i].tokenBalanceIn,
                    bestPools[i].tokenWeightIn,
                    bestPools[i].tokenBalanceOut,
                    bestPools[i].tokenWeightOut,
                    bestInputAmounts[i],
                    bestPools[i].swapFee
                );

            totalOutput = totalOutput.add(output);
        }
        return totalOutput;
    }

    /**
     * @dev Trtansfers `token` from the sender to this conteract.
     *
     */
    function transferFrom(IXToken token, uint256 amount) internal {
        require(token.transferFrom(msg.sender, address(this), amount), "ERR_TRANSFER_FAILED");
    }

    /**
     * @dev Trtansfers protocol swap fee from the sender to this `feeReceiver`.
     *
     */
    function transferFeeFrom(
        IXToken token,
        uint256 amount,
        bool useUtitlityToken
    ) internal {
        if (useUtitlityToken && utilityToken != address(0) && address(utilityTokenFeed) != address(0)) {
            uint256 discountedFee = utilityTokenFeed.calculateAmount(address(token), amount.div(2));

            if (discountedFee > 0) {
                require(
                    IERC20(utilityToken).transferFrom(msg.sender, feeReceiver, discountedFee),
                    "ERR_FEE_UTILITY_TRANSFER_FAILED"
                );
            } else {
                require(token.transferFrom(msg.sender, feeReceiver, amount), "ERR_FEE_TRANSFER_FAILED");
            }
        } else {
            require(token.transferFrom(msg.sender, feeReceiver, amount), "ERR_FEE_TRANSFER_FAILED");
        }
    }

    function getBalance(IXToken token) internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transfer(IXToken token, uint256 amount) internal {
        require(token.transfer(msg.sender, amount), "ERR_TRANSFER_FAILED");
    }
}
