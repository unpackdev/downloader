// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
pragma abicoder v2;

import "./SingleAssetVault.sol";
import "./IStaking.sol";

/// @dev This version adds support for using "boosted" user balances.
///  Boosted user balances will take user's staking balance into account.
contract SingleAssetVaultV2 is SingleAssetVault {
  event StakingContractUpdated(address _staking);
  /// @dev Track the boosted balances for all users
  mapping(address => uint256) internal boostedUserBalances;
  /// @dev Track the total boosted balance
  uint256 internal totalBoostedBalance;

  /// @dev Struct to store the formula weights that is used to calculate the boosted balance.
  struct BoostFormulaWeights {
    uint128 vaultBalanceWeight;
    uint128 stakingBalanceWeight;
  }
  BoostFormulaWeights public boostFormulaWeights;
  /// @dev Address of the staking contract
  address public stakingContract;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initializeV2(
    string memory _name,
    string memory _symbol,
    address _governance,
    address _gatekeeper,
    address _feeCollection,
    address _strategyDataStoreAddress,
    address _token,
    address _accessManager,
    address _vaultRewards,
    address _stakingContract
  ) external virtual initializer {
    __SingleAssetVaultV2_init(
      _name,
      _symbol,
      _governance,
      _gatekeeper,
      _feeCollection,
      _strategyDataStoreAddress,
      _token,
      _accessManager,
      _vaultRewards,
      _stakingContract
    );
  }

  // solhint-disable-next-line func-name-mixedcase
  function __SingleAssetVaultV2_init(
    string memory _name,
    string memory _symbol,
    address _governance,
    address _gatekeeper,
    address _feeCollection,
    address _strategyDataStoreAddress,
    address _token,
    address _accessManager,
    address _vaultRewards,
    address _stakingContract
  ) internal {
    __SingleAssetVault_init(
      _name,
      _symbol,
      _governance,
      _gatekeeper,
      _feeCollection,
      _strategyDataStoreAddress,
      _token,
      _accessManager,
      _vaultRewards
    );
    __SingleAssetVaultV2_init_unchained(_stakingContract);
  }

  function __SingleAssetVaultV2_init_unchained(address _stakingContract) internal {
    require(_stakingContract != address(0), "!staking");
    stakingContract = _stakingContract;
    boostFormulaWeights.vaultBalanceWeight = 1;
    boostFormulaWeights.stakingBalanceWeight = 9;
  }

  function version() external pure virtual override returns (string memory) {
    return "0.2.0";
  }

  /// @notice Query the boosted vault balance of the user.
  /// @dev If no boosted vault balance but there is a normal balance for the user, it means the boosted balance hasn't been inited yet.
  ///   Return the normal balance to keep it backward compatible.
  /// @param _user the address of the user to query
  /// @return the boosted balance of the user
  function boostedBalanceOf(address _user) external view returns (uint256) {
    require(_user != address(0), "!user");
    if (boostedUserBalances[_user] == 0 && balanceOf(_user) > 0) {
      return balanceOf(_user);
    }
    return boostedUserBalances[_user];
  }

  /// @notice Return the total of boosted balances
  /// @dev If no total boosted balance but there is totalSupply, it means the boosted balance hasn't been inited yet.
  ///  Return the normal totalSupply in this case.
  function totalBoostedSupply() external view returns (uint256) {
    if (totalBoostedBalance == 0 && totalSupply() > 0) {
      return totalSupply();
    }
    return totalBoostedBalance;
  }

  /// @notice Set the address of the staking contract. Can only be called by governance.
  /// @dev This needs to be called after upgrading from v1 to v2 version to ensure the staking contract address is set.
  /// @param _stakingContract The address of the staking contract.
  function setStakingContract(address _stakingContract) external {
    _onlyGovernance();
    require(_stakingContract != address(0), "!staking");
    if (_stakingContract != stakingContract) {
      stakingContract = _stakingContract;
      emit StakingContractUpdated(_stakingContract);
    }
  }

  /// @notice Set the weight used to calculate the boosted balance. Can only be called by governance.
  /// @dev This needs to be called after upgrading from v1 to v2 version.
  ///  Also once this is called, the `updateBoostedBalancesForUsers` should be called as well with all the vault user addresses to recalculate the boosted balances.
  function setBoostedFormulaWeights(uint128 _vaultWeight, uint128 _stakingWeight) external {
    _onlyGovernance();
    boostFormulaWeights.vaultBalanceWeight = _vaultWeight;
    boostFormulaWeights.stakingBalanceWeight = _stakingWeight;
  }

  /// @notice Recalculate the boosted balances for the given array of users.
  /// @dev Before the boosted balance is updated for a user, it will also ensure the rewards up to this point is calculated for the user.
  ///  This function must be called whenever `setBoostedFormulaWeights` is called to recalcuate the boosted balances for users.
  ///  It can also be called at anytime afterwards to reset the boosted balances for a user (or users).
  function updateBoostedBalancesForUsers(address[] calldata _users) external {
    uint256 totalBalanceToReduce;
    uint256 totalBalanceToAdd;
    for (uint256 i = 0; i < _users.length; i++) {
      if (vaultRewards != address(0)) {
        IYOPRewards(vaultRewards).calculateVaultRewards(_users[i]);
      }
      uint256 oldBoostedBalance = boostedUserBalances[_users[i]];
      uint256 newBoostedBalance = _calculateBoostedBalanceForUser(_users[i]);
      boostedUserBalances[_users[i]] = newBoostedBalance;
      totalBalanceToReduce += oldBoostedBalance;
      totalBalanceToAdd += newBoostedBalance;
    }
    // only update the storage value once at the end to save gas
    totalBoostedBalance = totalBoostedBalance - totalBalanceToReduce + totalBalanceToAdd;
  }

  /// @notice Returns the latest boosted balance of the user based on their latest staking and vault positions
  ///  Use this function and boostedBalanceOf to check if a user's boosted balance should be updated
  /// @param _user the address of the user to query
  /// @return the latest boosted balance for the user
  function latestBoostedBalanceOf(address _user) external view returns (uint256) {
    return _calculateBoostedBalanceForUser(_user);
  }

  function _calculateBoostedBalanceForUser(address _user) internal view returns (uint256) {
    return
      VaultUtils.calculateBoostedVaultBalance(
        _user,
        stakingContract,
        address(this),
        boostFormulaWeights.vaultBalanceWeight,
        boostFormulaWeights.stakingBalanceWeight
      );
  }

  /// @dev This hook is called by the OZ ERC20 contract after the user balance is updated.
  ///  At this point we can update the boosted balance as well.
  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256
  ) internal virtual override {
    uint256 totalReduce;
    uint256 totalAdd;
    if (_from != address(0)) {
      uint256 newBoostedBalance = _calculateBoostedBalanceForUser(_from);
      uint256 oldBoostedBalance = boostedUserBalances[_from];
      boostedUserBalances[_from] = newBoostedBalance;
      totalReduce += oldBoostedBalance;
      totalAdd += newBoostedBalance;
    }
    if (_to != address(0)) {
      uint256 newBoostedBalance = _calculateBoostedBalanceForUser(_to);
      uint256 oldBoostedBalance = boostedUserBalances[_to];
      boostedUserBalances[_to] = newBoostedBalance;
      totalReduce += oldBoostedBalance;
      totalAdd += newBoostedBalance;
    }
    totalBoostedBalance = totalBoostedBalance - totalReduce + totalAdd;
  }
}
