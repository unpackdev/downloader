// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ICurveAddressProvider.sol";
import "./ICurveExchange.sol";

library CurveswapAdapter {
  using SafeERC20 for IERC20;

  error SW_MISMATCH_RETURNED_AMOUNT();

  address private constant curveAddressProvider = 0x0000000022D53366457F9d5E68Ec105046FC4383;

  struct Path {
    address[9] routes;
    uint256[3][4] swapParams;
  }

  address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function swapExactTokensForTokens(
    address addressesProvider,
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 amountToSwap,
    Path calldata path,
    uint256 minAmountOut
  ) external returns (uint256) {
    // Approves the transfer for the swap. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
    address curveExchange = ICurveAddressProvider(curveAddressProvider).get_address(2);

    IERC20(assetToSwapFrom).safeApprove(address(curveExchange), 0);
    IERC20(assetToSwapFrom).safeApprove(address(curveExchange), amountToSwap);

    address[4] memory pools;
    uint256 receivedAmount = ICurveExchange(curveExchange).exchange_multiple(
      path.routes,
      path.swapParams,
      amountToSwap,
      minAmountOut,
      pools,
      address(this)
    );

    if (receivedAmount == 0) revert SW_MISMATCH_RETURNED_AMOUNT();
    uint256 balanceOfAsset;
    if (assetToSwapTo == ETH) {
      balanceOfAsset = address(this).balance;
    } else {
      balanceOfAsset = IERC20(assetToSwapTo).balanceOf(address(this));
    }
    if (balanceOfAsset < receivedAmount) revert SW_MISMATCH_RETURNED_AMOUNT();
    return receivedAmount;
  }
}
