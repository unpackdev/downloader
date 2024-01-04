// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


/**
 * @notice Interface of Vault contract.
 * 
 * Vaults are capital pools of one single token which seaks yield from the market.
 * A vault manages multiple strategies and at most one strategy is active at a time.
 */
interface IVault {

    /**
     * @dev Returns the token that the vault pools.
     */
    function token() external view returns (address);

    /**
     * @dev Returns the Controller address.
     */
    function controller() external view returns (address);

    /**
     * @dev Returns the governance of the vault.
     * Note that Controller and all vaults share the same governance, so this is
     * a shortcut to return Controller.governance().
     */
    function governance() external view returns (address);

    /**
     * @dev Returns the strategist of the vault.
     * Each vault has its own strategist to perform daily permissioned opertions.
     * Vault and its strategies managed share the same strategist.
     */
    function strategist() external view returns (address);

     /**
     * @dev Returns the total balance in both vault and strategy.
     */
    function balance() external view returns (uint256);

    /**
     * @dev Returns the current share price of the vault.
     */
    function getPricePerFullShare() external view returns (uint256);

    /**
     * @dev Checks whether a strategy is approved on the vault.
     * Only governance can approve and revoke strategies.
     * @param _strategy Strategy address to check.
     * @return Whether the strategy is approved on the vault.
     */
    function approvedStrategies(address _strategy) external view returns (bool);

    /**
     * @dev Returns the current active strategy of the vault.
     * Only strategist can select active strategy for the vault. At most strategy
     * is active at a time.
     */
    function activeStrategy() external view returns (address); 

    /**
     * @dev Whether the vault is now in emergency mode.
     * When the vault is in emergency mode:
     * 1. No deposit is allowed (but withdraw is allowed);
     * 2. The active strategy is set to zero address and all assets are withdrawn to vault.
     * 3. No new active strategy can be set.
     */
    function emergencyMode() external view returns (bool);

    /**
     * @dev Deposit some balance to the vault.
     * Deposit is not allowed when the vault is in emergency mode.
     * If one deposit is completed, no new deposit/withdraw/transfer is allowed in the same block.
     */
    function deposit(uint256 _amount) external;

    /**
     * @dev Withdraws some balance out of the vault.
     * Withdraw is allowed even in emergency mode.
     * If one withdraw is completed, no new deposit/withdraw/transfer is allowed in the same block.
     */
    function withdraw(uint256 _shares) external;

    /**
     * @dev Withdraws all balance and all rewards from the vault.
     */
    function exit() external;

    /**
     * @dev Claims all rewards from the vault.
     */
    function claimReward() external returns (uint256);

    /**
     * @dev Notifies the vault that a new reward is added. This function changes the reward vesting schedule.
     * The reward token is set in Controller.rewardToken().
     * @param _rewardAmount Amount of reward that is newly added to the vault.
     */
    function notifyRewardAmount(uint256 _rewardAmount) external;

    /**
     * @dev Adds rewards to the vault. This function DOES NOT change the reward vesting schedule.
     * The reward token is set in Controller.rewardToken().
     * @param _rewardAmount Amount of reward that is newly added to the vault.
     */
    function addRewards(uint256 _rewardAmount) external;

    /**
     * @dev Updates the strategist address. Only governance or strategist can update strategist.
     * Each vault has its own strategist to perform daily permissioned opertions.
     * Vault and its strategies managed share the same strategist.
     */
    function setStrategist(address _strategist) external;

    /**
     * @dev Updates the emergency mode. Only governance or strategist can update emergency mode.
     */
    function setEmergencyMode(bool _active) external;

    /**
     * @dev Updates the active strategy of the vault. Only governance or strategist can update the active strategy.
     * Only approved strategy can be selected as active strategy.
     * No new strategy is accepted in emergency mode.
     */
    function setActiveStrategy(address _strategy) external;

    /**
     * @dev Starts earning and deposits all current balance into strategy.
     * Only strategist or governance can call this function.
     * This function will throw if the vault is in emergency mode.
     */
    function earn() external;

    /**
     * @dev Harvest yield from the strategy if set.
     * Only strategist or governance can call this function.
     * This function will throw if the vault is in emergency mode.
     */
    function harvest() external;
}