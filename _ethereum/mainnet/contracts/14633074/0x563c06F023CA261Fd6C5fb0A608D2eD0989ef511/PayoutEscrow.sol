// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IPayoutEscrow.sol";
import "./IPayoutTreasury.sol";

contract PayoutEscrow is IPayoutEscrow {
  using SafeERC20 for IERC20;

  address public PayoutTreasuryAddress;
  address public usdcAddress;

  constructor (
    address _PayoutTreasuryAddress,
    address _usdcAddress
  ) {
    PayoutTreasuryAddress = _PayoutTreasuryAddress;
    usdcAddress = _usdcAddress;
  }

  modifier onlyPayoutTreasury () {
    require(msg.sender == PayoutTreasuryAddress, "PayoutEscrow: caller is not the payout treasury contract");
    _;
  }

  /**
    * @dev Returns excess USDC transferred as part of the initial compliant payout to PayoutTreasury
    */
  function refundStableAmount(uint256 amount) external override onlyPayoutTreasury {
    IERC20(usdcAddress).safeTransfer(PayoutTreasuryAddress, amount);
    emit StableCoinExchanged(amount);
  }

  /**
    * @dev Transfers multi-token payout to payee
    */
  function claimPayout(IPayoutTreasury.ClaimablePayout calldata claimablePayout) external override onlyPayoutTreasury {
    uint256 remainingUsdcAmount = claimablePayout.originalUsdcAmount;
    for (uint i = 0; i < claimablePayout.tokensToExchange.length; i++) {
      IPayoutTreasury.TokenToExchange calldata tokenToExchange = claimablePayout.tokensToExchange[i];
      IERC20(tokenToExchange.tokenAddress).safeTransfer(claimablePayout.payee, tokenToExchange.tokenAmount);
      remainingUsdcAmount -= claimablePayout.tokensToExchange[i].usdcToExchange;
    }
    IERC20(usdcAddress).safeTransfer(claimablePayout.payee, remainingUsdcAmount);
    emit PayoutClaimed(claimablePayout.payee, claimablePayout.originalUsdcAmount);
  }
}
