// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ICozy.sol";
import "./SafeERC20.sol";

abstract contract CozyInvestHelpers {
  using SafeERC20 for IERC20;

  /**
   * @notice Repays as much token debt as possible
   * @param _market Market to repay
   * @param _underlying That market's underlying token (can be obtained by a call, but passing it in saves gas)
   * @param _excessTokens Quantity to transfer from the caller into this address to ensure
   * the borrow can be repaid in full. Only required if you want to repay the full borrow amount and the
   * amount obtained from withdrawing from the invest opportunity will not cover the full debt. A value of zero
   * will not attempt to transfer tokens from the caller, and the transfer will not be attempted if it's not required
   */
  function executeMaxRepay(
    address _market,
    address _underlying,
    uint256 _excessTokens
  ) internal {
    // Pay back as much of the borrow as possible, excess is refunded to `recipient`
    uint256 _borrowBalance = ICozyToken(_market).borrowBalanceCurrent(address(this));
    uint256 _initialBalance = IERC20(_underlying).balanceOf(address(this));
    if (_initialBalance < _borrowBalance && _excessTokens > 0) {
      IERC20(_underlying).safeTransferFrom(msg.sender, address(this), _excessTokens);
    }
    uint256 _balance = _initialBalance + _excessTokens; // this contract's current balance
    uint256 _repayAmount = _balance >= _borrowBalance ? type(uint256).max : _balance;

    IERC20(_underlying).approve(address(_market), _repayAmount);
    require(ICozyToken(_market).repayBorrow(_repayAmount) == 0, "Repay failed");
  }
}
