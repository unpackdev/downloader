// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ICozyInvest.sol";
import "./CozyInvestHelpers.sol";

interface IYVault is IERC20 {
  function deposit() external returns (uint256); // providing no inputs to `deposit` deposits max amount for msg.sender

  function withdraw(uint256 maxShares) external returns (uint256); // defaults to msg.sender as recipient and 0.01 BPS maxLoss
}

/**
 * @notice On-chain scripts for borrowing from Cozy and using the borrowed funds to deposit into the Yearn USDC vault
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 */
contract CozyInvestYearnUSDC is CozyInvestHelpers, ICozyInvest2, ICozyDivest2 {
  using SafeERC20 for IERC20;

  // --- Cozy markets ---
  /// @notice Cozy protection market to borrow from: Cozy-USDC-2-Yearn USDC V2 Vault Share Price Trigger
  ICozyToken public constant protectionMarket = ICozyToken(0x9affB6D8568cEfa2837d251b1553967430D1a5e5);

  /// @notice Cozy money market with USDC underlying
  ICozyToken public constant moneyMarket = ICozyToken(0xdBDF2fC3Af896e18f2A9DC58883d12484202b57E);

  /// @notice USDC
  IERC20 public immutable underlying;

  // --- Yearn Parameters ---
  /// @notice Yearn USDC vault
  IYVault public constant yearn = IYVault(0x5f18C75AbDAe578b483E5F43f12a39cF75b973a9);

  constructor() {
    underlying = IERC20(moneyMarket.underlying());
  }

  /**
   * @notice Protected invest method for borrowing from given cozy market and depositing the borrowed
   * funds into the Yearn vault
   * @param _market Address of the market to borrow from
   * @param _borrowAmount Amount to borrow
   */
  function invest(address _market, uint256 _borrowAmount) external {
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");

    // Borrow from Cozy
    require(ICozyToken(_market).borrow(_borrowAmount) == 0, "Borrow failed");

    // Deposit the borrowed tokens into the Yearn vault
    underlying.safeApprove(address(yearn), type(uint256).max);
    yearn.deposit();
  }

  /**
   * @notice Protected divest method for exiting a position entered using this contract's `invest` method
   * @param _market Address of the market to repay
   * @param _recipient Address where any leftover tokens should be transferred
   * @param _yearnRedeemAmount Amount of Yearn receipt tokens to redeem
   * @param _excessTokens Quantity to transfer from the caller into this address to ensure
   * the borrow can be repaid in full. Only required if you want to repay the full borrow amount and the
   * amount obtained from withdrawing from Yearn will not cover the full debt. A value of zero will not
   * attempt to transfer tokens from the caller, and the transfer will not be attempted if it's not required
   */
  function divest(
    address _market,
    address _recipient,
    uint256 _yearnRedeemAmount,
    uint256 _excessTokens
  ) external {
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");

    // Redeem Yearn receipt tokens
    yearn.withdraw(_yearnRedeemAmount);

    // Pay back as much of the borrow as possible, excess is refunded to `recipient`
    executeMaxRepay(_market, address(underlying), _excessTokens);

    // Transfer any remaining tokens to the user after paying back borrow
    underlying.transfer(_recipient, underlying.balanceOf(address(this)));
  }
}
