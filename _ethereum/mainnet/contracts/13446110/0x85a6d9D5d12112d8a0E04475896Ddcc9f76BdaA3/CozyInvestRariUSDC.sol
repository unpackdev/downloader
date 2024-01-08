// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./Address.sol";

import "./ICozy.sol";
import "./ICozyInvest.sol";

interface IRariPool is IERC20 {
  function deposit(string calldata currencyCode, uint256 amount) external;

  function withdraw(string calldata currencyCode, uint256 amount) external returns (uint256);
}

/**
 * @notice On-chain scripts for borrowing from the Cozy-USDC-Rari Trigger protection market, and
 * depositing it to the Rari USDC pool.
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 */
contract CozyInvestRariUSDC is ICozyInvest2, ICozyDivest2 {
  using Address for address payable;
  using SafeERC20 for IERC20;

  /// @notice Cozy protection market with USDC underlying to borrow from: Cozy-USDC-Rari USDC Trigger
  ICozyToken public constant cozyUsdcPm = ICozyToken(0x97f84825d16b32ca97afC1c8bf51ab1086bcFf1F);

  /// @notice USDC token
  IERC20 public constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

  /// @notice Rari USDC pool manager
  IRariPool public constant poolManager = IRariPool(0xC6BF8C8A55f77686720E0a88e2Fd1fEEF58ddf4a);

  /**
   * @notice Protected invest method for borrowing from the Cozy-USDC Rari Trigger protection market,
   * depositing that USDC to Rari USDC pool
   * @param _borrowAmount Amount of USDC to borrow and deposit into the Rari pool
   */
  function invest(uint256 _borrowAmount) external {
    // Borrow USDC from Cozy protection market
    require(cozyUsdcPm.borrow(_borrowAmount) == 0, "Borrow failed");

    // Approve the pool mamanger to spend our USDC. We only approve the borrow amount for security because
    // the pool mamanger is an upgradeable proxy
    if (usdc.allowance(address(this), address(poolManager)) < _borrowAmount) {
      usdc.approve(address(poolManager), _borrowAmount);
    }

    // Deposit into the USDC pool
    poolManager.deposit("USDC", _borrowAmount);
  }

  /**
   * @notice Protected divest method for exiting a position entered using this contract's `invest` method
   * @param _recipient Address where any leftover USDC should be transferred
   * @param _withdrawAmount Amount of USDC to withdraw
   * @param _excessTokens Quantity of USDC to transfer from the caller into this address to ensure
   * the borrow can be repaid in full. Only required if you want to repay the full borrow amount and the
   * amount of USDC obtained from withdrawing from Rari will not cover the full debt. A value of zero will not
   * attempt to transfer tokens from the caller, and the transfer will not be attempted if it's not required
   */
  function divest(
    address _recipient,
    uint256 _withdrawAmount,
    uint256 _excessTokens
  ) external {
    // Withdraw from pool
    poolManager.withdraw("USDC", _withdrawAmount);

    // Attempt to repay the entire debt
    try cozyUsdcPm.repayBorrowBehalf(address(this), type(uint256).max) returns (uint256 _err) {
        if (_err == 0) return; // success! all debt repaid
    } catch {
        // If that failed with a revert, do nothing and fall through to the next statement
    }
    // Repaying the max debt failed, repay as much debt as possible from our balance
    uint256 _err2 = cozyUsdcPm.repayBorrowBehalf(address(this), usdc.balanceOf(address(this)));
    require(_err2 == 0, "Repay attempts failed");

    // Transfer any remaining USDC to the user after paying back borrow
    usdc.transfer(_recipient, usdc.balanceOf(address(this)));
  }
}
