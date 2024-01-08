pragma abicoder v2;
pragma solidity ^0.7.5;

import "./TransferHelper.sol";
import "./ISwapRouter.sol";
import "./Withdraw.sol";

contract WonderFi {
  ISwapRouter public immutable swapRouter;
  Withdraw public immutable withdraw;

  // For this example, we will set the pool fee to 0.3%.
  uint24 public constant poolFee = 3000;
  uint24 public constant slippage = 10;

  mapping (address => mapping(bytes => bool)) public nonce;

  constructor(ISwapRouter _swapRouter, Withdraw _withdraw) {
      swapRouter = _swapRouter;
      withdraw = _withdraw;
  }

  function swap(
    address _signer,
    address token0,
    uint256 token0Amount,
    address token1,
    uint256 token1Amount,
    bytes memory _nonce,
    bytes memory signature
    ) external returns (uint256 amountOut) {

      withdraw.withdraw(_signer, token0, token0Amount, token1, token1Amount, _nonce, signature);

      // Approve the router to spend
      TransferHelper.safeApprove(token0, address(swapRouter), token0Amount);

      // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
      // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
      ISwapRouter.ExactInputSingleParams memory params =
          ISwapRouter.ExactInputSingleParams({
              tokenIn: token0,
              tokenOut: token1,
              fee: poolFee,
              recipient: _signer,
              deadline: block.timestamp,
              amountIn: token0Amount,
              amountOutMinimum: ((100 - slippage) * token1Amount) / 100,
              sqrtPriceLimitX96: 0
          });

      // The call to `exactInputSingle` executes the swap.
      amountOut = swapRouter.exactInputSingle(params);
  }

  function transfer(
    address _signer,
    address token0,
    uint256 token0Amount,
    address destination,
    bytes memory _nonce,
    bytes memory signature
    ) external {
      withdraw.transfer(_signer, token0, token0Amount, destination, _nonce, signature);
  }
}
