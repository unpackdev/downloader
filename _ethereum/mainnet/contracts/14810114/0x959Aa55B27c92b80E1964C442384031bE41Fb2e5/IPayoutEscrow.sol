// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IPayoutEscrow {
  struct TokenToExchange {
    // ERC-20 token address
    address tokenAddress;
    // amount in native token to acquire, disregarding decimals
    uint256 tokenAmount;
    // amount in USDC that should be exchanged, disregarding decimals
    uint256 usdcToExchange;
  }

  // Initial USDC transfer sent to PayoutEscrow contract
  event CompliantPayoutInitiated(
    address indexed payee,
    uint256 stableCoinAmountInUSDC
  );

  // Initiates USDC transfer from caller
  // Transfers ERC20 tokens from caller
  // Exchanges USDC back to caller at ERC20 token spot price
  // Transfers USDC and ERC20 token payout to payee
  function createAndTransferPayout(
    uint256 usdcAmount,
    address payee,
    TokenToExchange[] memory tokensToExchange
  ) external;
}
