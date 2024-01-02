// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {

  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);

}

interface IWETH {

  function withdraw(uint amount) external;

}

interface ISwapRouter {

  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint deadline;
    uint amountIn;
    uint amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  function exactInputSingle(
    ExactInputSingleParams calldata params
  ) external payable returns (uint amountOut);

}

contract UniswapHelper {
  ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  function _swap(
    uint amountIn
  ) internal returns (uint) {

    IERC20(address(this)).approve(address(router), amountIn);

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
      .ExactInputSingleParams({
        tokenIn: address(this),
        tokenOut: WETH,
        fee: 10000,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });

    return router.exactInputSingle(params);
  }

  receive() external payable {}

}
