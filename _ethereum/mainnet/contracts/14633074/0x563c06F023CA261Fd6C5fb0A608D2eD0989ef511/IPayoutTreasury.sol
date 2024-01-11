// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IPayoutTreasury {
  struct TokenToExchange {
    // ERC-20 token address
    address tokenAddress;
    // amount in native token to acquire, disregarding decimals
    uint256 tokenAmount;
    // amount in USDC that should be exchanged, disregarding decimals
    uint256 usdcToExchange;
  }

  struct ClaimablePayout {
    // recipient of the transaction
    address payee;
    uint256 originalUsdcAmount;
    TokenToExchange[] tokensToExchange;
  }

  struct TokenToWithdraw {
    // ERC-20 token address
    address tokenAddress;
    // amount in native token to withdraw, disregarding decimals
    uint256 tokenAmount;
  }

  // Address of PayoutEscrow contract modified
  event PayoutEscrowAddressChanged (address _address);

  // Address of USDC contract modified
  event USDCAddressChanged (address _address);

  // Initial USDC transfer sent to PayoutEscrow contract
  event PayoutInitiated (address indexed payee, uint256 stableCoinAmountInUSDC);

  // Token swap initialized, sending ERC-20 tokens to PayoutEscrow contract
  event TokensExchanged (address indexed payee, uint256 tokenValueInUSDC);

  // All token swaps completed
  event PayoutReadyToClaim (address indexed payee, uint256 totalValueInUSDC);

  // Owner withdrew funds from the treasury
  event TreasuryFundsWithdrawn(address tokenAddress, address destination, uint256 amount);

  // owner only
  // Initiates USDC transfer to PayoutEscrow contract
  // Calls PayoutEscrow exchangeStableForTokens function
  // Calls PayoutEscrow claimPayout function
  function createAndTransferPayout(
    uint256 usdcAmount,
    address payee,
    TokenToExchange[] memory tokensToExchange
  ) external;

  // owner only
  function withdrawTokens(
    TokenToWithdraw[] calldata tokensToWithdraw,
    address dest
  ) external;
}
