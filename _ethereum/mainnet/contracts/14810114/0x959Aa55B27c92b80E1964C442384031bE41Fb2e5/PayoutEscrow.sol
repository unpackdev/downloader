// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IPayoutEscrow.sol";

contract PayoutEscrow is IPayoutEscrow {
  using SafeERC20 for IERC20;
  using Address for address;

  address public usdcAddress;

  constructor(address _usdcAddress) {
    usdcAddress = _usdcAddress;
  }

  /**
   * @dev Facilitates compliant USDC transfer through PayoutEscrow to payee
   */
  function createAndTransferPayout(
    uint256 totalUsdcAmount,
    address payee,
    TokenToExchange[] memory tokensToExchange
  ) external {
    // transfer full balance in USDC to PayoutEscrow and record compliant payout
    IERC20(usdcAddress).safeTransferFrom(
      msg.sender,
      address(this),
      totalUsdcAmount
    );
    emit CompliantPayoutInitiated(payee, totalUsdcAmount);
    uint256 totalUsdcExchangeAmount = 0;
    // transfer allocated non-USDC tokens from sender to contract
    for (uint256 i = 0; i < tokensToExchange.length; i++) {
      TokenToExchange memory tokenConfig = tokensToExchange[i];
      // add up over-allocated USDC that should be exchanged for non-USDC tokens
      totalUsdcExchangeAmount += tokenConfig.usdcToExchange;
      IERC20(tokenConfig.tokenAddress).safeTransferFrom(
        msg.sender,
        address(this),
        tokenConfig.tokenAmount
      );
    }
    require(
      totalUsdcAmount >= totalUsdcExchangeAmount,
      "Exchange amount exceeds transfer amount"
    );

    // transfer over-allocated USDC back to caller
    refundStableAmount(totalUsdcExchangeAmount, msg.sender);

    // initiate final payout from PayoutEscrow to payee
    IERC20(usdcAddress).safeTransfer(
      payee,
      totalUsdcAmount - totalUsdcExchangeAmount
    );
    // transfer non-USDC tokens from PayoutEscrow to payee
    for (uint256 i = 0; i < tokensToExchange.length; i++) {
      TokenToExchange memory tokenConfig = tokensToExchange[i];
      IERC20(tokenConfig.tokenAddress).safeTransfer(
        payee,
        tokenConfig.tokenAmount
      );
    }
  }

  /**
   * @dev Refunds excess USDC from PayoutEscrow
   */
  function refundStableAmount(uint256 amount, address _dest) private {
    IERC20(usdcAddress).safeTransfer(_dest, amount);
  }
}
