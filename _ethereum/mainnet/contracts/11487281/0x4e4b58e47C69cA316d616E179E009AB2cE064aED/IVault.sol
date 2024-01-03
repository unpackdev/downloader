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
     * @dev Notifies the vault that a new reward is added.
     * The reward token is set in Controller.rewardToken().
     * @param _rewardAmount Amount of reward that is newly added to the vault.
     */
    function notifyRewardAmount(uint256 _rewardAmount) external;
}