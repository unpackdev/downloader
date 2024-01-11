// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./YOPRewards.sol";

/// @dev This version of the reward contract will calculate the user's vault rewards using their boosted vault balances (taking staking into account)
///  rather than just their vault balances.
contract YOPRewardsV2 is IYOPRewardsV2, YOPRewards {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
  using ConvertUtils for *;

  modifier onlyStaking() {
    require(stakingContract != address(0) && _msgSender() == stakingContract, "staking only");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  /// @notice Called by the staking contract to claim rewards for a stake id when it is burnt (unstaked) or compounded. The claimed rewards will be transferred to the staking contract which will then decide what to do. Can only be called by the staking contract.
  /// @param _stakeIds The stake ids to claim rewards for
  /// @return The amount of rewards
  function claimRewardsForStakes(uint256[] calldata _stakeIds)
    external
    whenNotPaused
    onlyStaking
    returns (uint256, uint256[] memory)
  {
    _updateStateForStaking(_stakeIds);
    bytes32[] memory accounts = ConvertUtils.uint256ArrayToBytes32Array(_stakeIds);
    return _claim(accounts, stakingContract);
  }

  /// @notice Called by the staking contract to claim vault rewards for the given users for compounding the stakes. Can only be called by the staking contract.
  /// @dev In this function the reward state of the users are not updated. This is because this function will call `updateBoostedBalancesForUsers` function on the vaults eventually,
  ///  which in turn will call the `calculateVaultRewards` function on the rewards contract.
  ///  However, in the future if this changes, then this function needs to be updated to ensure the reward state is updated here.
  /// @param _users The addreses of users to claim rewards for
  /// @return The amount of rewards
  function claimVaultRewardsForUsers(address[] calldata _users)
    external
    whenNotPaused
    onlyStaking
    returns (uint256, uint256[] memory)
  {
    bytes32[] memory accounts = new bytes32[](_users.length);
    for (uint256 i = 0; i < _users.length; i++) {
      bytes32 acc = _users[i].addressToBytes32();
      accounts[i] = acc;
      _updateStateForVaults(vaultAddresses.values(), acc);
    }
    return _claim(accounts, stakingContract);
  }

  function _getVaultTotalSupply(address _vault) internal view virtual override returns (uint256) {
    return IBoostedVault(_vault).totalBoostedSupply();
  }

  function _getVaultBalanceOf(address _vault, address _user) internal view virtual override returns (uint256) {
    return IBoostedVault(_vault).boostedBalanceOf(_user);
  }

  /// @dev This is called when user claims their rewards for vaults. This will also update the user's boosted balance based on their latest staking position.
  function _updateStateForVaults(address[] memory _vaults, bytes32 _account) internal virtual override {
    for (uint256 i = 0; i < _vaults.length; i++) {
      require(vaultAddresses.contains(_vaults[i]), "!vault");
      // since this function is only called when claiming, if the account doesn't have any balance in a vault
      // then there is no need to update the checkpoint for the user as it will always be 0
      if (IVault(_vaults[i]).balanceOf(_account.bytes32ToAddress()) > 0) {
        address[] memory users = new address[](1);
        users[0] = _account.bytes32ToAddress();
        // the updateBoostedBalancesForUsers will calculate the user's rewards, and update the boosted balance
        // based the user's current staking position
        IBoostedVault(_vaults[i]).updateBoostedBalancesForUsers(users);
      }
    }
  }
}
