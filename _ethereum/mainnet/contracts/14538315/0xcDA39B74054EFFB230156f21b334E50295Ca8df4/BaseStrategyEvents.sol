// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./IERC20.sol";

import "./AccessControl.sol";
import "./AccessControlUpgradeable.sol";

import "./IStrategy.sol";
import "./IPoolManager.sol";

/// @title BaseStrategyEvents
/// @author Angle Core Team
/// @notice Events used in the abstract `BaseStrategy` contract
contract BaseStrategyEvents {
    // So indexers can keep track of this
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    event UpdatedMinReportDelayed(uint256 delay);

    event UpdatedMaxReportDelayed(uint256 delay);

    event UpdatedDebtThreshold(uint256 debtThreshold);

    event UpdatedRewards(address rewards);

    event UpdatedIsRewardActivated(bool activated);

    event UpdatedRewardAmountAndMinimumAmountMoved(uint256 _rewardAmount, uint256 _minimumAmountMoved);

    event EmergencyExitActivated();
}
