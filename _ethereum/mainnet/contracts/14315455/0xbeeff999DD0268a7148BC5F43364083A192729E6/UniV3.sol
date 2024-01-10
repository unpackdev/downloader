// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma abicoder v2;

import "./ISwapRouter.sol";
import "./TransferHelper.sol";

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

contract UniV3 {
  IUniswapRouter private uniswapRouter;

  constructor(address router) {
      uniswapRouter = IUniswapRouter(router);
  }

  function convertV3(uint amountIn, address tokenIn, address tokenOut, uint24 fee) public returns (uint amountOut) {
    uint256 deadline = block.timestamp + 15;
    address recipient = address(this);
    uint256 amountOutMinimum = 0;
    uint160 sqrtPriceLimitX96 = 0;

    TransferHelper.safeApprove(tokenIn, address(uniswapRouter), amountIn);
    
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
        tokenIn,
        tokenOut,
        fee,
        recipient,
        deadline,
        amountIn,
        amountOutMinimum,
        sqrtPriceLimitX96
    );
    
    amountOut = uniswapRouter.exactInputSingle(params);
    uniswapRouter.refundETH();

    return amountOut;
  }
}