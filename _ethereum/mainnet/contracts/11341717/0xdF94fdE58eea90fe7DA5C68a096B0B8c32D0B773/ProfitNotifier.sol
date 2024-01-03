pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./FeeRewardForwarder.sol";


contract ProfitNotifier {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public profitSharingNumerator;
  uint256 public profitSharingDenominator;

  address public feeRewardForwarder; // Address of the `FeeRewardForwarder` contract.

  event ProfitLog(
    uint256 oldBalance,
    uint256 newBalance,
    uint256 feeAmount,
    uint256 timestamp
  );

  constructor() {
    // persist in the state for immutability of the fee
    // means fee = 30%
    profitSharingNumerator = 25; 
    profitSharingDenominator = 100;
    require(profitSharingNumerator < profitSharingDenominator, "invalid profit share");
  }

  /* 
  / This fn takes in the old balance (pre-profit) and the new balance (after profit).
  / It uses this info to calculate the profit (old balance - new balance).
  / After computing the profit, it computes the fee (30% of profit in our case).
  / Finally it sends the fee amount to the `FeeRewardForwarder` contract and notifies it.
  */
  function notifyProfit(uint256 oldBalance, uint256 newBalance, address underlying) internal {
    if (newBalance > oldBalance) {
      uint256 profit = newBalance.sub(oldBalance);
      uint256 feeAmount = profit.mul(profitSharingNumerator).div(profitSharingDenominator);
      emit ProfitLog(oldBalance, newBalance, feeAmount, block.timestamp);

      if (feeAmount > 0) {
        IERC20(underlying).safeApprove(feeRewardForwarder, 0);
        IERC20(underlying).safeApprove(feeRewardForwarder, feeAmount);
        require(feeRewardForwarder != address(0), 'burning porfits!');
        FeeRewardForwarder(feeRewardForwarder).poolNotifyFixedTarget(underlying, feeAmount);
      }
    } else {
      emit ProfitLog(oldBalance, newBalance, 0, block.timestamp);
    }
  }
}

