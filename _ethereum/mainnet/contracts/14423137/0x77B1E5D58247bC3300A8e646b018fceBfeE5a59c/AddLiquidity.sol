// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./ITwapPair.sol";
import "./ITwapOracle.sol";

library AddLiquidity {
    using SafeMath for uint256;

    function _quote(
        uint256 amount0,
        uint256 reserve0,
        uint256 reserve1
    ) private pure returns (uint256 amountB) {
        require(amount0 > 0, 'AL03');
        require(reserve0 > 0 && reserve1 > 0, 'AL07');
        amountB = amount0.mul(reserve1) / reserve0;
    }

    function addLiquidity(
        address pair,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) internal view returns (uint256 amount0, uint256 amount1) {
        if (amount0Desired == 0 || amount1Desired == 0) {
            return (0, 0);
        }
        (uint256 reserve0, uint256 reserve1) = ITwapPair(pair).getReserves();
        if (reserve0 == 0 && reserve1 == 0) {
            (amount0, amount1) = (amount0Desired, amount1Desired);
        } else {
            uint256 amount1Optimal = _quote(amount0Desired, reserve0, reserve1);
            if (amount1Optimal <= amount1Desired) {
                (amount0, amount1) = (amount0Desired, amount1Optimal);
            } else {
                uint256 amount0Optimal = _quote(amount1Desired, reserve1, reserve0);
                assert(amount0Optimal <= amount0Desired);
                (amount0, amount1) = (amount0Optimal, amount1Desired);
            }
        }
    }

    function addLiquidityAndMint(
        address pair,
        address to,
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        (uint256 amount0, uint256 amount1) = addLiquidity(pair, amount0Desired, amount1Desired);
        if (amount0 == 0 || amount1 == 0) {
            return (amount0Desired, amount1Desired);
        }
        TransferHelper.safeTransfer(token0, pair, amount0);
        TransferHelper.safeTransfer(token1, pair, amount1);
        ITwapPair(pair).mint(to);

        amount0Left = amount0Desired.sub(amount0);
        amount1Left = amount1Desired.sub(amount1);
    }

    function swapDeposit0(
        address pair,
        address token0,
        uint256 amount0,
        uint256 minSwapPrice,
        bytes calldata data
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount0In = ITwapPair(pair).getDepositAmount0In(amount0, data);
        amount1Left = ITwapPair(pair).getSwapAmount1Out(amount0In, data);
        if (amount1Left == 0) {
            return (amount0, amount1Left);
        }
        uint256 price = getPrice(amount0In, amount1Left, pair);
        require(minSwapPrice == 0 || price >= minSwapPrice, 'AL15');
        TransferHelper.safeTransfer(token0, pair, amount0In);
        ITwapPair(pair).swap(0, amount1Left, address(this), data);
        amount0Left = amount0.sub(amount0In);
    }

    function swapDeposit1(
        address pair,
        address token1,
        uint256 amount1,
        uint256 maxSwapPrice,
        bytes calldata data
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount1In = ITwapPair(pair).getDepositAmount1In(amount1, data);
        amount0Left = ITwapPair(pair).getSwapAmount0Out(amount1In, data);
        if (amount0Left == 0) {
            return (amount0Left, amount1);
        }
        uint256 price = getPrice(amount0Left, amount1In, pair);
        require(maxSwapPrice == 0 || price <= maxSwapPrice, 'AL16');
        TransferHelper.safeTransfer(token1, pair, amount1In);
        ITwapPair(pair).swap(amount0Left, 0, address(this), data);
        amount1Left = amount1.sub(amount1In);
    }

    function getPrice(
        uint256 amount0,
        uint256 amount1,
        address pair
    ) internal view returns (uint256) {
        ITwapOracle oracle = ITwapOracle(ITwapPair(pair).oracle());
        return amount1.mul(uint256(oracle.decimalsConverter())).div(amount0);
    }
}
