// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./IERC20Upgradeable.sol";

interface IRewardToken {
    /**
     * @dev Update accumulatedPerBlock and user.debt when stake() is called
     */
    function updateAccumulatedWhenStake(address account, uint256 amount) external returns (bool);

    /**
     * @dev Update accumulatedPerBlock and user.debt when unstake() is called
     */
    function updateAccumulatedWhenUnstake(address account, uint256 amount) external returns (bool);

    /**
     * @dev return next reward halve block number
     */
    function getNextRewardChangeBlock() external returns (uint256);

    /**
     * @dev return current reward amount
     */
    function getCurrentReward() external returns (uint256);

    /**
     * @dev return lockup blocks period
     */
    function getLockupPeriod() external returns (uint256);
}
