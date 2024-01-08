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
 * @notice On-chain scripts for borrowing from the Cozy-DAI-Rari Trigger protection market, and
 * depositing it to the Rari DAI pool.
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 */
contract CozyInvestRariDAI is ICozyInvest2, ICozyDivest2 {
  using Address for address payable;
  using SafeERC20 for IERC20;

  /// @notice Cozy protection market with DAI underlying to borrow from: Cozy-DAI-Rari DAI Trigger
  ICozyToken public constant cozyDaiPm = ICozyToken(0xAeF3f76e426D2f0139EAeCd19672Dd9C9A3fC582);

  /// @notice DAI token
  IERC20 public constant dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  /// @notice Rari DAI pool manager
  IRariPool public constant poolManager = IRariPool(0x59FA438cD0731EBF5F4cDCaf72D4960EFd13FCe6);

  /**
   * @notice Protected invest method for borrowing from the Cozy-DAI Rari Trigger protection market,
   * depositing that DAI to Rari DAI pool
   * @param _borrowAmount Amount of DAI to borrow and deposit into the Rari pool
   */
  function invest(uint256 _borrowAmount) external {
    // Borrow DAI from Cozy protection market
    require(cozyDaiPm.borrow(_borrowAmount) == 0, "Borrow failed");

    // Approve the pool mamanger to spend our DAI. We only approve the borrow amount for security because
    // the pool mamanger is an upgradeable proxy
    if (dai.allowance(address(this), address(poolManager)) < _borrowAmount) {
      dai.approve(address(poolManager), _borrowAmount);
    }

    // Deposit into the DAI pool
    poolManager.deposit("DAI", _borrowAmount);
  }

  /**
   * @notice Protected divest method for exiting a position entered using this contract's `invest` method
   * @param _recipient Address where any leftover DAI should be transferred
   * @param _withdrawAmount Amount of DAI to withdraw
   * @param _excessTokens Quantity of DAI to transfer from the caller into this address to ensure
   * the borrow can be repaid in full. Only required if you want to repay the full borrow amount and the
   * amount of DAI obtained from withdrawing from Rari will not cover the full debt. A value of zero will not
   * attempt to transfer tokens from the caller, and the transfer will not be attempted if it's not required
   */
  function divest(
    address _recipient,
    uint256 _withdrawAmount,
    uint256 _excessTokens
  ) external {
    // Withdraw from pool
    poolManager.withdraw("DAI", _withdrawAmount);

    // Attempt to repay the entire debt
    try cozyDaiPm.repayBorrowBehalf(address(this), type(uint256).max) returns (uint256 _err) {
        if (_err == 0) return; // success! all debt repaid
    } catch {
        // If that failed with a revert, do nothing and fall through to the next statement
    }
    // Repaying the max debt failed, repay as much debt as possible from our balance
    uint256 _err2 = cozyDaiPm.repayBorrowBehalf(address(this), dai.balanceOf(address(this)));
    require(_err2 == 0, "Repay attempts failed");

    // Transfer any remaining DAI to the user after paying back borrow
    dai.transfer(_recipient, dai.balanceOf(address(this)));
  }
}
