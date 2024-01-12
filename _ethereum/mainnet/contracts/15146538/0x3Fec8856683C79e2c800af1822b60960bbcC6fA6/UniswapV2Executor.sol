// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
//


interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

abstract contract UniswapV2Executor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function swapUniswapV2(
        uint256 amountSpecified,
        IUniswapV2Pair pair,
        address recipient,
        IERC20 sourceToken,
        IERC20 targetToken
    ) external {
        (uint256 result0, uint256 result1) = _calcInOutAmounts(
            pair,
            sourceToken,
            targetToken,
            amountSpecified
        );
        sourceToken.safeTransfer(address(pair), amountSpecified);
        pair.swap(result0, result1, recipient, "");
    }

    function _calcInOutAmounts(
        IUniswapV2Pair pair,
        IERC20 sourceToken,
        IERC20 targetToken,
        uint256 amountIn
    ) private view returns (uint256 result0, uint256 result1) {
        (uint256 reserveIn, uint256 reserveOut, ) = pair.getReserves();
        if (sourceToken > targetToken) {
            (reserveIn, reserveOut) = (reserveOut, reserveIn);
        }
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        unchecked {
            uint256 amountOut = numerator / denominator;

            return
                address(sourceToken) < address(targetToken)
                    ? (uint256(0), amountOut)
                    : (amountOut, uint256(0));
        }
    }
}
