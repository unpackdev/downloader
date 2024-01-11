// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IPayoutTreasury.sol";

interface IPayoutEscrow {

  // USDC returned to PayoutTreasury to complete the token swap
  event StableCoinExchanged (uint256 stableCoinAmountInUSDC);

  // Tokenized payout sent to payee address
  event PayoutClaimed (address indexed payee, uint256 totalValueInUSDC);

  // returns USDC amount to PayoutTreasury
  function refundStableAmount(uint256 amount) external;

  // transfers multi-token payout to payee
  function claimPayout(IPayoutTreasury.ClaimablePayout calldata claimablePayout) external;
}
