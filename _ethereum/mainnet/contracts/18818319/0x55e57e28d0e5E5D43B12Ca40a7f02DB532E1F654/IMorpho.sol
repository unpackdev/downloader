// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";

interface IRewardsDistributor {
    /// @notice Claims rewards.
    /// @param _account The address of the claimer.
    /// @param _claimable The overall claimable amount of token rewards.
    /// @param _proof The merkle proof that validates this claim.
    function claim(address _account, uint256 _claimable, bytes32[] calldata _proof) external;
}

interface ISupplyVault is IERC20 {
    // The recipient of the rewards that will redistribute them to vault's users.
    function recipient() external view returns (IRewardsDistributor);

    // Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
    // scenario where all the conditions are met.
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    // Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the Vault.
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /// @notice Deposits an amount of assets into the vault and receive vault shares.
    /// @param assets The amount of assets to deposit.
    /// @param receiver The recipient of the vault shares.
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /// @notice Withdraws an amount of assets from the vault and burn an owner's shares.
    /// @param assets The number of assets to withdraw.
    /// @param receiver The recipient of the assets.
    /// @param owner The owner of the vault shares.
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
}

interface ISupplyVaultCompound is ISupplyVault {
    // The vault's rewards index.
    function rewardsIndex() external view returns (uint256);

    // The rewards data of a user, used to track accrued rewards.
    function userRewards(address _user) external view returns (uint128 index, uint128 unclaimed);

    /// @notice Claims rewards on behalf of `_user`.
    /// @param _user The address of the user to claim rewards for.
    /// @return rewardsAmount The amount of rewards claimed.
    function claimRewards(address _user) external returns (uint256 rewardsAmount);
}
