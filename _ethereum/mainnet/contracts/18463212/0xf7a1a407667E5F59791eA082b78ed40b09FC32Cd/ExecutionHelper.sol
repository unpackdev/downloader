pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9




import "./ITwapOracle.sol";
import "./ITwapPair.sol";
import "./IWETH.sol";
import "./SafeMath.sol";
import "./Orders.sol";
import "./TokenShares.sol";
import "./AddLiquidity.sol";
import "./WithdrawHelper.sol";

library ExecutionHelper {
    using SafeMath for uint256;
    using TransferHelper for address;

    using Orders for Orders.Data;
    using TokenShares for TokenShares.Data;

    uint256 private constant ORDER_LIFESPAN = 48 hours;

    struct ExecuteBuySellParams {
        Orders.Order order;
        address pairAddress;
        uint16 pairTolerance;
    }

    function executeDeposit(
        Orders.Order calldata order,
        address pairAddress,
        uint16 pairTolerance,
        TokenShares.Data storage tokenShares
    ) external {
        require(order.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'EH04');

        (uint256 amount0Left, uint256 amount1Left, uint256 swapToken) = _initialDeposit(
            order,
            pairAddress,
            tokenShares
        );

        if (order.swap && swapToken != 0) {
            bytes memory data = encodePriceInfo(pairAddress, order.priceAccumulator, order.timestamp);
            if (amount0Left != 0 && swapToken == 1) {
                uint256 extraAmount1;
                (amount0Left, extraAmount1) = AddLiquidity.swapDeposit0(
                    pairAddress,
                    order.token0,
                    amount0Left,
                    order.minSwapPrice,
                    pairTolerance,
                    data
                );
                amount1Left = amount1Left.add(extraAmount1);
            } else if (amount1Left != 0 && swapToken == 2) {
                uint256 extraAmount0;
                (extraAmount0, amount1Left) = AddLiquidity.swapDeposit1(
                    pairAddress,
                    order.token1,
                    amount1Left,
                    order.maxSwapPrice,
                    pairTolerance,
                    data
                );
                amount0Left = amount0Left.add(extraAmount0);
            }
        }

        if (amount0Left != 0 && amount1Left != 0) {
            (amount0Left, amount1Left, ) = AddLiquidity.addLiquidityAndMint(
                pairAddress,
                order.to,
                order.token0,
                order.token1,
                amount0Left,
                amount1Left
            );
        }

        AddLiquidity._refundDeposit(order.to, order.token0, order.token1, amount0Left, amount1Left);
    }

    function _initialDeposit(
        Orders.Order calldata order,
        address pairAddress,
        TokenShares.Data storage tokenShares
    )
        private
        returns (
            uint256 amount0Left,
            uint256 amount1Left,
            uint256 swapToken
        )
    {
        uint256 amount0Desired = tokenShares.sharesToAmount(order.token0, order.value0, order.amountLimit0, order.to);
        uint256 amount1Desired = tokenShares.sharesToAmount(order.token1, order.value1, order.amountLimit1, order.to);
        (amount0Left, amount1Left, swapToken) = AddLiquidity.addLiquidityAndMint(
            pairAddress,
            order.to,
            order.token0,
            order.token1,
            amount0Desired,
            amount1Desired
        );
    }

    function executeWithdraw(Orders.Order calldata order) external {
        require(order.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'EH04');
        (address pairAddress, ) = Orders.getPair(order.token0, order.token1);
        TransferHelper.safeTransfer(pairAddress, pairAddress, order.liquidity);
        uint256 wethAmount;
        uint256 amount0;
        uint256 amount1;
        if (order.unwrap && (order.token0 == TokenShares.WETH_ADDRESS || order.token1 == TokenShares.WETH_ADDRESS)) {
            bool success;
            (success, wethAmount, amount0, amount1) = WithdrawHelper.withdrawAndUnwrap(
                order.token0,
                order.token1,
                pairAddress,
                TokenShares.WETH_ADDRESS,
                order.to,
                Orders.getTransferGasCost(Orders.NATIVE_CURRENCY_SENTINEL)
            );
            if (!success) {
                TokenShares.onUnwrapFailed(order.to, wethAmount);
            }
        } else {
            (amount0, amount1) = ITwapPair(pairAddress).burn(order.to);
        }
        require(amount0 >= order.value0 && amount1 >= order.value1, 'EH03');
    }

    function executeBuy(ExecuteBuySellParams memory orderParams, TokenShares.Data storage tokenShares) external {
        require(orderParams.order.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'EH04');

        uint256 amountInMax = tokenShares.sharesToAmount(
            orderParams.order.token0,
            orderParams.order.value0,
            orderParams.order.amountLimit0,
            orderParams.order.to
        );
        bytes memory priceInfo = encodePriceInfo(
            orderParams.pairAddress,
            orderParams.order.priceAccumulator,
            orderParams.order.timestamp
        );
        uint256 amountIn;
        uint256 amountOut;
        uint256 reserveOut;
        bool inverted = orderParams.order.inverted;
        {
            // scope for reserve out logic, avoids stack too deep errors
            (uint112 reserve0, uint112 reserve1) = ITwapPair(orderParams.pairAddress).getReserves();
            // subtract 1 to prevent reserve going to 0
            reserveOut = uint256(inverted ? reserve0 : reserve1).sub(1);
        }
        {
            // scope for partial fill logic, avoids stack too deep errors
            address oracle = ITwapPair(orderParams.pairAddress).oracle();
            uint256 swapFee = ITwapPair(orderParams.pairAddress).swapFee();
            (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMaxOut(
                inverted,
                swapFee,
                orderParams.order.value1,
                priceInfo
            );
            uint256 amountInMaxScaled;
            if (amountOut > reserveOut) {
                amountInMaxScaled = amountInMax.mul(reserveOut).ceil_div(orderParams.order.value1);
                (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMinOut(
                    inverted,
                    swapFee,
                    reserveOut,
                    priceInfo
                );
            } else {
                amountInMaxScaled = amountInMax;
                amountOut = orderParams.order.value1; // Truncate to desired out
            }
            require(amountInMaxScaled >= amountIn, 'EH08');
            if (amountInMax > amountIn) {
                if (orderParams.order.token0 == TokenShares.WETH_ADDRESS && orderParams.order.unwrap) {
                    forceEtherTransfer(orderParams.order.to, amountInMax.sub(amountIn));
                } else {
                    TransferHelper.safeTransfer(
                        orderParams.order.token0,
                        orderParams.order.to,
                        amountInMax.sub(amountIn)
                    );
                }
            }
            TransferHelper.safeTransfer(orderParams.order.token0, orderParams.pairAddress, amountIn);
        }
        amountOut = amountOut.sub(orderParams.pairTolerance);
        uint256 amount0Out;
        uint256 amount1Out;
        if (inverted) {
            amount0Out = amountOut;
        } else {
            amount1Out = amountOut;
        }
        if (orderParams.order.token1 == TokenShares.WETH_ADDRESS && orderParams.order.unwrap) {
            ITwapPair(orderParams.pairAddress).swap(amount0Out, amount1Out, address(this), priceInfo);
            forceEtherTransfer(orderParams.order.to, amountOut);
        } else {
            ITwapPair(orderParams.pairAddress).swap(amount0Out, amount1Out, orderParams.order.to, priceInfo);
        }
    }

    function executeSell(ExecuteBuySellParams memory orderParams, TokenShares.Data storage tokenShares) external {
        require(orderParams.order.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'EH04');

        bytes memory priceInfo = encodePriceInfo(
            orderParams.pairAddress,
            orderParams.order.priceAccumulator,
            orderParams.order.timestamp
        );

        uint256 amountOut = _executeSellHelper(orderParams, priceInfo, tokenShares);

        (uint256 amount0Out, uint256 amount1Out) = orderParams.order.inverted
            ? (amountOut, uint256(0))
            : (uint256(0), amountOut);
        if (orderParams.order.token1 == TokenShares.WETH_ADDRESS && orderParams.order.unwrap) {
            ITwapPair(orderParams.pairAddress).swap(amount0Out, amount1Out, address(this), priceInfo);
            forceEtherTransfer(orderParams.order.to, amountOut);
        } else {
            ITwapPair(orderParams.pairAddress).swap(amount0Out, amount1Out, orderParams.order.to, priceInfo);
        }
    }

    function _executeSellHelper(
        ExecuteBuySellParams memory orderParams,
        bytes memory priceInfo,
        TokenShares.Data storage tokenShares
    ) internal returns (uint256 amountOut) {
        uint256 reserveOut;
        {
            // scope for determining reserve out, avoids stack too deep errors
            (uint112 reserve0, uint112 reserve1) = ITwapPair(orderParams.pairAddress).getReserves();
            // subtract 1 to prevent reserve going to 0
            reserveOut = uint256(orderParams.order.inverted ? reserve0 : reserve1).sub(1);
        }
        {
            // scope for calculations, avoids stack too deep errors
            address oracle = ITwapPair(orderParams.pairAddress).oracle();
            uint256 swapFee = ITwapPair(orderParams.pairAddress).swapFee();
            uint256 amountIn = tokenShares.sharesToAmount(
                orderParams.order.token0,
                orderParams.order.value0,
                orderParams.order.amountLimit0,
                orderParams.order.to
            );
            amountOut = orderParams.order.inverted
                ? ITwapOracle(oracle).getSwapAmount0Out(swapFee, amountIn, priceInfo)
                : ITwapOracle(oracle).getSwapAmount1Out(swapFee, amountIn, priceInfo);

            uint256 amountOutMinScaled;
            if (amountOut > reserveOut) {
                amountOutMinScaled = orderParams.order.value1.mul(reserveOut).div(amountOut);
                uint256 _amountIn = amountIn;
                (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMinOut(
                    orderParams.order.inverted,
                    swapFee,
                    reserveOut,
                    priceInfo
                );
                if (orderParams.order.token0 == TokenShares.WETH_ADDRESS && orderParams.order.unwrap) {
                    forceEtherTransfer(orderParams.order.to, _amountIn.sub(amountIn));
                } else {
                    TransferHelper.safeTransfer(
                        orderParams.order.token0,
                        orderParams.order.to,
                        _amountIn.sub(amountIn)
                    );
                }
            } else {
                amountOutMinScaled = orderParams.order.value1;
            }
            amountOut = amountOut.sub(orderParams.pairTolerance);
            require(amountOut >= amountOutMinScaled, 'EH37');
            TransferHelper.safeTransfer(orderParams.order.token0, orderParams.pairAddress, amountIn);
        }
    }

    function encodePriceInfo(
        address pairAddress,
        uint256 priceAccumulator,
        uint256 priceTimestamp
    ) internal view returns (bytes memory data) {
        uint256 price = ITwapOracle(ITwapPair(pairAddress).oracle()).getAveragePrice(priceAccumulator, priceTimestamp);
        // Pack everything as 32 bytes / uint256 to simplify decoding
        data = abi.encode(price);
    }

    function forceEtherTransfer(address to, uint256 amount) internal {
        IWETH(TokenShares.WETH_ADDRESS).withdraw(amount);
        (bool success, ) = to.call{ value: amount, gas: Orders.getTransferGasCost(Orders.NATIVE_CURRENCY_SENTINEL) }(
            ''
        );
        if (!success) {
            TokenShares.onUnwrapFailed(to, amount);
        }
    }
}
