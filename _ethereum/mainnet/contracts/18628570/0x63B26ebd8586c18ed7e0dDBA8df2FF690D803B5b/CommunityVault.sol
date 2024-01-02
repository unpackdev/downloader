// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./Vault.sol";

/**
 * @title Community Vault
 * @notice Vault contract for depositing LINK collateral into the Chainlink community staking controller
 */
contract CommunityVault is Vault {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice initializes contract
     * @param _token address of LINK token
     * @param _vaultController address of the strategy that controls this vault
     * @param _stakeController address of Chainlink community staking contract
     * @param _rewardsController address of Chainlink staking rewards contract
     **/
    function initialize(
        address _token,
        address _vaultController,
        address _stakeController,
        address _rewardsController
    ) public initializer {
        __Vault_init(_token, _vaultController, _stakeController, _rewardsController);
    }

    /**
     * @notice claims rewards from the Chainlink staking contract
     * @param _minRewards min amount of rewards required to claim
     * @param _rewardsReceiver address to receive rewards
     **/
    function claimRewards(uint256 _minRewards, address _rewardsReceiver) external onlyVaultController {
        uint256 rewards = getRewards();
        if (rewards != 0 && rewards >= _minRewards) {
            rewardsController.claimReward();
            token.safeTransfer(_rewardsReceiver, token.balanceOf(address(this)));
        }
    }
}
