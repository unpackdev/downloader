// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./SafeTransfer.sol";
import "./IWETH.sol";

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}


contract CerberusRouter {
    using SafeTransfer for IERC20;
    using SafeTransfer for IWETH;

    address internal immutable owner;

    address internal constant WETH9 =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function withdrawFees(address wallet) public {
        require(msg.sender == owner, "You are not the owner");
        SafeTransfer.safeTransferETH(wallet, address(this).balance);

    }
    fallback(bytes calldata input) external payable returns (bytes memory output) {
        
        address tokenIn;
        address tokenOut;
        address pair;
        uint256 minAmountOut;
        uint16 cerbFeeFactor;
        uint256 amountIn;
        address referrer;
        uint16 referrerFeeFactor;

        (tokenIn, tokenOut, pair,  minAmountOut, cerbFeeFactor, amountIn, referrer, referrerFeeFactor) = abi.decode(input, (address, address, address, uint256, uint16, uint256, address, uint16));

        address receiver = address(this);

        if (address(tokenIn) == WETH9) {

            require(msg.value > 0, "No msg value provided");

            uint cerbFee = (msg.value * cerbFeeFactor) / 10000;
            uint referrerFee = (msg.value * referrerFeeFactor) / 10000;

            amountIn = msg.value - cerbFee - referrerFee;

            IWETH weth = IWETH(WETH9);
            weth.deposit{value: amountIn}();
            weth.safeTransfer(pair, amountIn);

            if (referrerFee > 0) {
                SafeTransfer.safeTransferETH(referrer, referrerFee);
            }

        } else {
  
            IERC20(tokenIn).safeTransferFrom(msg.sender, pair, amountIn);
        }

        uint reserveIn;
        uint reserveOut;

        {
            (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pair).getReserves();

            if (tokenIn < tokenOut) {
                reserveIn = reserve0;
                reserveOut = reserve1;
            } else {
                reserveIn = reserve1;
                reserveOut = reserve0;
            }
        }


        uint amountOut = getAmountOut(amountIn, reserveIn, reserveOut);

        (uint amount0Out, uint amount1Out) = tokenIn < tokenOut
            ? (uint(0), amountOut)
            : (amountOut, uint(0));

        uint balBefore = IERC20(tokenOut).balanceOf(address(receiver));

        IUniswapV2Pair(pair).swap(
            amount0Out,
            amount1Out,
            receiver,
            new bytes(0)
        );

        uint actualAmountOut = IERC20(tokenOut).balanceOf(address(receiver)) - balBefore;

        require(actualAmountOut >= minAmountOut, "Too little received");

        if (tokenOut == WETH9) {
            IWETH(WETH9).withdraw(actualAmountOut);

            uint cerbFee = (actualAmountOut * cerbFeeFactor) / 10000;
            uint referrerFee = (actualAmountOut * referrerFeeFactor) / 10000;

            SafeTransfer.safeTransferETH(msg.sender, actualAmountOut - cerbFee - referrerFee);

            if (referrerFee > 0) {
                SafeTransfer.safeTransferETH(referrer, referrerFee);
            }
            
        } else {

            IERC20(tokenOut).safeTransfer(msg.sender, actualAmountOut);
        }

        return input;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
