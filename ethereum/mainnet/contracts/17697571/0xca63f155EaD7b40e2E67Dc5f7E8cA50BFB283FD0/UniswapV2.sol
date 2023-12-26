// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWowmaxRouter.sol";

// @title Uniswap v2 pair interface
interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function router() external returns (address);
}

// @title Uniswap v2 router interface
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// @title Uniswap v2 library
// @notice Functions to swap tokens on Uniswap v2 and compatible protocols
library UniswapV2 {
    uint256 private constant feeDenominator = 10000;

    using SafeERC20 for IERC20;

    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IERC20(from).safeTransfer(swapData.addr, amountIn);
        uint256 fee = abi.decode(swapData.data, (uint256));
        bool directSwap = IUniswapV2Pair(swapData.addr).token0() == from;
        (uint112 reserveIn, uint112 reserveOut) = getReserves(swapData.addr, directSwap);
        amountOut = getAmountOut(amountIn, reserveIn, reserveOut, fee);
        if (amountOut > 0) {
            IUniswapV2Pair(swapData.addr).swap(
                directSwap ? 0 : amountOut,
                directSwap ? amountOut : 0,
                address(this),
                new bytes(0)
            );
        }
    }

    function routerSwap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IUniswapV2Router router = IUniswapV2Router(IUniswapV2Pair(swapData.addr).router());
        IERC20(from).safeApprove(address(router), amountIn);
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = swapData.to;
        return router.swapExactTokensForTokens(amountIn, 0, path, address(this), type(uint256).max)[1];
    }

    function getReserves(address pair, bool directSwap) private view returns (uint112 reserveIn, uint112 reserveOut) {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        return directSwap ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountOut(
        uint256 amountIn,
        uint112 reserveIn,
        uint112 reserveOut,
        uint256 fee
    ) private pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * (feeDenominator - fee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * feeDenominator + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
