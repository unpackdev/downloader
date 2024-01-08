pragma solidity >=0.8.4;
import "./ISwapRouter.sol";
import "./TransferHelper.sol";

contract BrainTrustFeeConverterContract {
  address public immutable TreasuryAddress;
  address public immutable USDC;
  address public immutable BTRST;

  ISwapRouter public immutable swapRouter;

  uint24 public immutable poolFee;

  constructor(ISwapRouter _swapRouter, address _treasuryAddress, address _usdc, address _btrst, uint24 _poolFee) {
    swapRouter = _swapRouter;
    TreasuryAddress = _treasuryAddress;
    USDC = _usdc;
    BTRST = _btrst;
    poolFee = _poolFee;
  }

  function swapExactInputSingle(uint256 amountIn, uint256 amountOutMin, uint256 deadline) external returns (uint256 amountOut) {
    TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), amountIn);
    TransferHelper.safeApprove(USDC, address(swapRouter), amountIn);

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: USDC,
      tokenOut: BTRST,
      fee: poolFee,
      recipient: TreasuryAddress,
      deadline: deadline,
      amountIn: amountIn,
      amountOutMinimum: amountOutMin,
      sqrtPriceLimitX96: 0
    });

    // The call to `exactInputSingle` executes the swap.
    amountOut = swapRouter.exactInputSingle(params);
  }
}