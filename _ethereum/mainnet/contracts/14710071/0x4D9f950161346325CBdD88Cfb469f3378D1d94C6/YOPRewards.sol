// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./IERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PRBMathUD60x18Typed.sol";
import "./IYOPRewards.sol";
import "./IVault.sol";
import "./ConvertUtils.sol";
import "./BasePauseableUpgradeable.sol";

interface IStaking {
  function totalWorkingSupply() external view returns (uint256);

  function workingBalanceOfStake(uint256 _stakeId) external view returns (uint256);

  function stakesFor(address _user) external view returns (uint256[] memory);
}

/// @notice This contract will be used to calculate the YOP rewards for vault and staking users based on the emission schedule outlined in YOP tokenomics.
///  In a nutshell, from Jan 2022, there will be certain amount of YOP token distributed to all users who provide liquidity to vaults or stake their YOP tokens.
///  The emission will last for 10 years, and the amount of first month is 342554 and will reduce by 1% every month.
///  Initially the split will be 50-50 between users who provide liquidity to vaults and users who stake. However, the value is configurable and may change down the road.
///  Each vault also has a weight to decide the proportion of the overall vault emission it will get.
///  For vaults, the rewards are associated with users, so they can still claim unclaimed rewards after they transfer their vault tokens to others.
///  However, for Staking, the staking rewards is associated with each stake, as each stake is unique and there is an NFT associated with each stake.
///  This means that if there is unclaimed rewards, and then the NFT is transferred, the new owner will be able to claim all unclaimed rewards too.
/// @dev Given the token emission rate for a vault R, and from time T1 to time T2, user balance U and total balance of the vault V, the rewards for the user can be calculated as:
///       (T2 - T1) * R * (U/V)
///      So to calculate the total rewards for a user, we just need to calculate the value above everytime when R, U, V is about to change, from the last time any of these value chaged,
///      and add them up over time.
///      The above equation can also be written as (T2 - T1) * R / V * U. So when U is not changed, we can calculate the sum of `(T2 - T1) * R / V` part and store it. And then multiply the U when U is about to change.
///      And this is how we do it in this contract.
contract YOPRewards is IYOPRewards, BasePauseableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
  using PRBMathUD60x18Typed for PRBMath.UD60x18;
  using ConvertUtils for *;
  using ERC165CheckerUpgradeable for address;

  /// @notice Emitted when the weight of rewards for all vaults is changed
  event VaultsRewardsWeightUpdated(uint256 indexed _weight);
  /// @notice Emitted when the weight of rewards for staking is changed
  event StakingRewardsWeightUpdated(uint256 indexed _weight);
  /// @notice Emitted when the weight points of a vault is updated
  event VaultRewardWeightUpdated(address[] _vaults, uint256[] _weights);
  /// @notice Emitted when rewards is calculated for a user
  event RewardsDistributed(address indexed _vault, bytes32 indexed _to, uint256 indexed _amount);
  /// @notice Emitted when the staking contract is updated
  event StakingContractUpdated(address indexed _stakingContract);

  struct PoolRewardsState {
    // This is the `(T2 - T1) * R / V` part
    PRBMath.UD60x18 index;
    /// Last time when the state is updated
    uint256 timestamp;
    /// The last epoch count when the state is updated
    uint256 epochCount;
    /// The rate of the last epoch when the state is updated
    uint256 epochRate;
    // Overall total rewards have been allocated to this vault
    uint256 totalRewards;
  }

  struct ClaimRecord {
    uint256 totalAvailable;
    uint256 totalClaimed;
  }

  uint256 public constant FIRST_EPOCH_EMISSION = 342554; // no decimals here. Will apply the appropriate decimals during calculation to improve precision.
  uint256 public constant DEFLATION_RATE = 100; // 1% in BPS
  uint256 public constant MAX_BPS = 10000;
  uint256 public constant SECONDS_PER_EPOCH = 2629743; // 1 month/30.44 days
  uint256 public constant MAX_EPOCH_COUNT = 120; // 120 months
  uint256 public constant WEIGHT_AMP = 1000000;
  uint8 public constant YOP_DECIMAL = 8;

  /// @notice The weight of new YOP emissions that will be allocated to vault users. Default to 50.
  uint256 public vaultsRewardsWeight;
  /// @notice The weight of new YOP emissions that will be allocated to staking users. Default to 50.
  uint256 public stakingRewardsWeight;
  /// @notice The total weight points of all the vaults combined together
  uint256 public totalWeightForVaults;
  /// @notice The start time of the emission
  uint256 public emissionStartTime;
  /// @notice The end time of the emission
  uint256 public emissionEndTime;
  /// @notice The address of the YOP contract
  address public yopContractAddress;
  /// @notice The address of the wallet where reward tokens will be drawn from
  address public rewardsWallet;
  /// @notice The address of the staking contract
  address public stakingContract;
  /// @notice The weight of new YOP emissions that each vault will get. Will be set by governance.
  /// @dev The percentage value is calculated using the vaultWeight/totalWeight.
  ///      If any one of the vault weight is changed, the percentage value is then changed for every other vault.
  mapping(address => uint256) public perVaultRewardsWeight;
  /// @dev Used to store all the vault addresses internally.
  EnumerableSetUpgradeable.AddressSet internal vaultAddresses;

  /// @notice The reward state for each vault or staking contract
  mapping(address => PoolRewardsState) public poolRewardsState;
  /// @notice The rewards state for each user in each vault or each NFT in the staking contract
  mapping(address => mapping(bytes32 => PRBMath.UD60x18)) public userRewardsState;
  /// @notice The claimed records of reward tokens for each user
  mapping(bytes32 => ClaimRecord) internal claimRecords;

  struct EpochInfo {
    /// Counter of an epoch
    uint256 epochCount;
    /// Rate associated with the epoch
    uint256 epochRate;
  }

  /// @dev store the information about the current epoch.
  /// It will only updated once per epoch so one transaction will pay more gas because of this, but it will reduce gas costs for all transactions of the same epoch afterwards as there will be less loop needed.
  EpochInfo public currentEpoch;

  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  /// @param _governance The address of the governance
  /// @param _wallet The address of the reward wallet where this contract can draw reward tokens.
  function initialize(
    address _governance,
    address _gatekeeper,
    address _wallet,
    address _yopContract,
    uint256 _emissionStartTime
  ) external virtual initializer {
    __YOPRewards_init(_governance, _gatekeeper, _wallet, _yopContract, _emissionStartTime);
  }

  // solhint-disable-next-line func-name-mixedcase
  function __YOPRewards_init(
    address _governance,
    address _gatekeeper,
    address _wallet,
    address _yopContract,
    uint256 _emissionStartTime
  ) internal {
    __BasePauseableUpgradeable_init(_governance, _gatekeeper);
    __YOPRewards_init_unchained(_wallet, _yopContract, _emissionStartTime);
  }

  // solhint-disable-next-line func-name-mixedcase
  function __YOPRewards_init_unchained(
    address _wallet,
    address _yopContract,
    uint256 _emissionStartTime
  ) internal {
    require(_wallet != address(0), "invalid wallet address");
    require(_yopContract != address(0), "invalid yop contract address");
    require(_emissionStartTime > 0, "invalid emission start time");
    rewardsWallet = _wallet;
    yopContractAddress = _yopContract;
    emissionStartTime = _emissionStartTime;
    emissionEndTime = emissionStartTime + SECONDS_PER_EPOCH * MAX_EPOCH_COUNT;
    vaultsRewardsWeight = 50;
    stakingRewardsWeight = 50;
  }

  /// @notice Returns the current emission rate of the rewards token (per epoch/month) and the epoch count. The epoch count will start from 1.
  /// @return _rate The current rate of emission for the current epoch.
  /// @return _epoch The current epoch. Starts from 1.
  function rate() external view returns (uint256 _rate, uint256 _epoch) {
    EpochInfo memory epoch = _getCurrentEpoch();
    // epoch count 0 means it's not started yet. And it will start from 1.
    uint256 epochCount = epoch.epochRate == 0 ? 0 : epoch.epochCount + 1;
    return (epoch.epochRate, epochCount);
  }

  /// @notice Return the claim record for the given address of a user
  function claimRecordForAddress(address _user) external view returns (ClaimRecord memory) {
    return claimRecords[_user.addressToBytes32()];
  }

  /// @notice Return the claim record for the given stake id
  function claimRecordForStake(uint256 _stakeId) external view returns (ClaimRecord memory) {
    return claimRecords[_stakeId.uint256ToBytes32()];
  }

  /// @notice Set the address of the staking contract. Can only be set by governance.addressToBytes32();
  /// @dev This should be set as soon as the staking contract is deployed.
  ///  It isn't required as part of the constructor is because the staking contract is depending on this contract too (it needs to call the reward contract when stakes are minted/burned).
  ///  And if the staking contract is required as part of the constructor, then we will have a circular dependency.
  /// @param _stakingContract The address of the staking contract.
  function setStakingContractAddress(address _stakingContract) external onlyGovernance {
    require(_stakingContract != address(0), "!address");
    require(stakingContract != _stakingContract, "!valid");
    stakingContract = _stakingContract;
    emit StakingContractUpdated(_stakingContract);
  }

  /// @notice Set the weights of community emission allocations for vault LP providers and stakers.
  ///  The weights can be any positive integers and allocation percentage will be calculated using weight/weightTotal.
  /// @param _weightForVaults The weight of vault user rewards allocation.
  /// @param _weightForStaking The weight of staking user rewards allocation.
  function setRewardsAllocationWeights(uint256 _weightForVaults, uint256 _weightForStaking) external onlyGovernance {
    require((_weightForVaults + _weightForStaking) > 0, "invalid ratio");
    if (_weightForVaults != vaultsRewardsWeight) {
      for (uint256 i = 0; i < vaultAddresses.length(); i++) {
        // need to update the vault state with the old value before the rate is changed
        _updatePoolState(vaultAddresses.at(i));
      }
      vaultsRewardsWeight = _weightForVaults;
      emit VaultsRewardsWeightUpdated(_weightForVaults);
    }
    if (stakingContract != address(0)) {
      if (_weightForStaking != stakingRewardsWeight) {
        _updatePoolState(stakingContract);
        stakingRewardsWeight = _weightForStaking;
        emit StakingRewardsWeightUpdated(_weightForStaking);
      }
    }
  }

  /// @notice Set the weight points of each vault. The weight will be used to decide the percentages of the reward emissions that are allocated to all vaults will be distributed to each vault.
  ///         Can only be set by governance.
  /// @param _vaults The addresses of al the vaults.
  /// @param _weights The corresponding weight values of each vault. The weight values can be any value and percentage for each vault is calculated as (vaultWeight/totalWeight).
  function setPerVaultRewardsWeight(address[] calldata _vaults, uint256[] calldata _weights) external onlyGovernance {
    require(_vaults.length > 0, "!vaults");
    require(_vaults.length == _weights.length, "!sameLength");
    // needs to add a checkpoint for all the existing vaults, because when the weight point is changed for any vault, the percentage value is changed for every vault and they all need to be updated
    for (uint256 i = 0; i < vaultAddresses.length(); i++) {
      _updatePoolState(vaultAddresses.at(i));
    }
    for (uint256 i = 0; i < _vaults.length; i++) {
      address vault = _vaults[i];
      require(vault.supportsInterface(type(IVault).interfaceId), "!vault interface");
      uint256 oldValue = perVaultRewardsWeight[vault];
      if (!vaultAddresses.contains(_vaults[i])) {
        // a new vault, add the initial checkpoint
        _updatePoolState(vault);
      }
      perVaultRewardsWeight[vault] = _weights[i];
      totalWeightForVaults = totalWeightForVaults - oldValue + _weights[i];
      vaultAddresses.add(vault);
    }
    require(totalWeightForVaults > 0, "!totalWeight");
    emit VaultRewardWeightUpdated(_vaults, _weights);
  }

  /// @notice Calculate rewards the given _user should receive in the given _vault. Can only be invoked by the vault.
  /// @dev This should be called everytime when a user deposits/withdraws from a vault.
  ///      It needs to be called *BEFORE* the user balance is actually updated in the vault.
  /// @param _user The address of the user
  function calculateVaultRewards(address _user) external {
    address vault = _msgSender();
    require(vaultAddresses.contains(vault), "not authorised");
    _updatePoolState(vault);
    _updateUserState(vault, _user.addressToBytes32());
  }

  /// @notice Calculate rewards the given stakeId should receive in the staking contract. Can only be invoked by the staking contract
  /// @dev This should be called everytime when a user stakes/unstakes. It should be called before the balance is updated in the staking contract.
  /// @param _stakeId The id of the stake
  function calculateStakingRewards(uint256 _stakeId) external {
    address staking = _msgSender();
    require(staking == stakingContract, "!authorised");
    _updatePoolState(staking);
    _updateUserState(staking, _stakeId.uint256ToBytes32());
  }

  /// @notice Claim reward tokens for the caller across all the vaults and staking contract and send the rewards to the given address.
  /// @param _to The address to send the rewards to
  function claimAll(address _to) external whenNotPaused {
    _updateStateForVaults(vaultAddresses.values(), _msgSender().addressToBytes32());
    uint256[] memory stakeIds;
    if (stakingContract != address(0)) {
      stakeIds = IStaking(stakingContract).stakesFor(_msgSender());
    }
    _updateStateForStaking(stakeIds);
    bytes32[] memory accounts = new bytes32[](stakeIds.length + 1);
    accounts[0] = _msgSender().addressToBytes32();
    for (uint256 i = 0; i < stakeIds.length; i++) {
      accounts[i + 1] = stakeIds[i].uint256ToBytes32();
    }
    _claim(accounts, _to);
  }

  /// @notice Claim reward tokens for the caller in the given vaults and send the rewards to the given address.
  /// @param _vaults The addresses of the vaults to claim rewards for
  /// @param _to The address that will receive the reward tokens
  function claimVaultRewards(address[] calldata _vaults, address _to) external whenNotPaused {
    require(_vaults.length > 0, "no vaults");
    _updateStateForVaults(_vaults, _msgSender().addressToBytes32());
    bytes32[] memory accounts = new bytes32[](1);
    accounts[0] = _msgSender().addressToBytes32();
    _claim(accounts, _to);
  }

  /// @notice Claim staking rewards for the caller. It will check what staking NFTs the caller has at the time of calling this function and transfer the available rewards for these NFTs.
  /// @param _to The address that will receive the rewards
  function claimStakingRewards(address _to) external whenNotPaused {
    uint256[] memory stakeIds;
    if (stakingContract != address(0)) {
      stakeIds = IStaking(stakingContract).stakesFor(_msgSender());
    }
    _updateStateForStaking(stakeIds);
    bytes32[] memory accounts = ConvertUtils.uint256ArrayToBytes32Array(stakeIds);
    _claim(accounts, _to);
  }

  /// @notice Returns the total of estimated unclaimed rewards across all the vaults for the given user.
  /// @param _user The address of the user to query for.
  /// @return totalRewards The total amount of rewards token the caller can claim. Equals to vaultsRewards + stakingRewards.
  /// @return vaultsRewards The amount of rewards from providing liqudity for vaults.
  /// @return stakingRewards The amount of rewards from staking
  function allUnclaimedRewards(address _user)
    external
    view
    returns (
      uint256 totalRewards,
      uint256 vaultsRewards,
      uint256 stakingRewards
    )
  {
    require(_user != address(0), "!input");
    address[] memory vaults = vaultAddresses.values();
    vaultsRewards = _unclaimedVaultRewards(vaults, _user.addressToBytes32());
    if (stakingContract != address(0)) {
      uint256[] memory stakeIds = IStaking(stakingContract).stakesFor(_user);
      stakingRewards = _unclaimedStakingRewards(stakeIds);
    }
    totalRewards = vaultsRewards + stakingRewards;
  }

  /// @notice Returns the total of estimated unclaimed rewards across the given vaults for the given user.
  /// @param _user The address of the user to query for
  /// @param _vaults The list of vaults to calculate the rewards for
  function unclaimedVaultRewards(address _user, address[] calldata _vaults) external view returns (uint256) {
    require(_user != address(0), "!input");
    require(_vaults.length > 0, "!input");
    return _unclaimedVaultRewards(_vaults, _user.addressToBytes32());
  }

  /// @notice Returns the estimated unclaimed rewards for staking for the given stakes. Note the caller may not own these stakes.
  /// @param _stakeIds The ids of the stakes.
  function unclaimedStakingRewards(uint256[] calldata _stakeIds) external view returns (uint256) {
    return _unclaimedStakingRewards(_stakeIds);
  }

  /// @notice Returns the total of rewards for a vault up to the current block time. Can be useful to calculate APY.
  /// @param _vault the vault address
  function totalRewardsForVault(address _vault) external view returns (uint256) {
    PoolRewardsState memory poolState = _calculatePoolState(_vault);
    return poolState.totalRewards;
  }

  /// @notice Returns the total of rewards for the staking contract up to the current block time. Can be useful to calculate APY.
  function totalRewardsForStaking() external view returns (uint256) {
    PoolRewardsState memory poolState = _calculatePoolState(stakingContract);
    return poolState.totalRewards;
  }

  /// @notice Set the address of the reward wallet that this contract can draw rewards from. Can only be called by governance.
  /// @param _wallet The address of the wallet that have reward tokens.
  function setRewardWallet(address _wallet) external onlyGovernance {
    require(_wallet != address(0), "!wallet");
    rewardsWallet = _wallet;
  }

  function _getCurrentEpoch() internal view returns (EpochInfo memory) {
    EpochInfo memory epoch;
    if ((_getBlockTimestamp() < _getEpochStartTime()) || (_getBlockTimestamp() > _getEpochEndTime())) {
      return epoch;
    }
    epoch = currentEpoch;
    if (epoch.epochRate > 0) {
      // check if we are still in the "currentEpoch". Most requests should hit this path and no additional loops required
      uint256 startTime = _getEpochStartTime() + epoch.epochCount * SECONDS_PER_EPOCH;
      uint256 endTime = startTime + SECONDS_PER_EPOCH;
      if (startTime <= _getBlockTimestamp() && _getBlockTimestamp() <= endTime) {
        return epoch;
      }
    }
    // we are not in the "currentEpoch" anymore, so find out what's correct "currentEpoch"
    // FIRST_EPOCH_EMISSION needs to include YOP decimals
    uint256 epochRate = epoch.epochRate == 0 ? FIRST_EPOCH_EMISSION * (10**YOP_DECIMAL) : epoch.epochRate;
    uint256 r = epochRate;
    for (uint256 i = epoch.epochCount; i < MAX_EPOCH_COUNT; i++) {
      // if there are any interactions with any of the vaults/staking contracts/claim rewards contracts every month,
      // then this should only be run once every epoch to bump the epoch count from i to i+1
      uint256 startTime = _getEpochStartTime() + SECONDS_PER_EPOCH * i;
      uint256 endTime = startTime + SECONDS_PER_EPOCH;
      if (startTime <= _getBlockTimestamp() && _getBlockTimestamp() <= endTime) {
        epoch.epochCount = i;
        epoch.epochRate = r;
        break;
      }
      // use recursive function is a lot easier as comupting x^y for fix point values in Solidity is quite complicated and likely cost more gas
      r = (r * (MAX_BPS - DEFLATION_RATE)) / MAX_BPS;
    }
    return epoch;
  }

  function _updateCurrentEpoch() internal returns (EpochInfo memory) {
    EpochInfo memory epoch = _getCurrentEpoch();
    if (currentEpoch.epochCount != epoch.epochCount || currentEpoch.epochRate != epoch.epochRate) {
      currentEpoch.epochCount = epoch.epochCount;
      currentEpoch.epochRate = epoch.epochRate;
    }
    return epoch;
  }

  function _updatePoolState(address _pool) internal {
    _updateCurrentEpoch();
    PoolRewardsState memory state = _calculatePoolState(_pool);
    if (state.timestamp != poolRewardsState[_pool].timestamp) {
      poolRewardsState[_pool] = state;
    }
  }

  function _updateUserState(address _pool, bytes32 _user) internal {
    PoolRewardsState memory poolState = poolRewardsState[_pool];
    uint256 tokenDelta = _calculateUserState(_pool, _user, poolState);
    if (userRewardsState[_pool][_user].value != poolState.index.value) {
      userRewardsState[_pool][_user] = poolState.index; // store the new value so it will be used the next time as the previous value
    }
    if (tokenDelta > 0) {
      claimRecords[_user].totalAvailable = claimRecords[_user].totalAvailable + tokenDelta;
      emit RewardsDistributed(_pool, _user, tokenDelta);
    }
  }

  function _calculatePoolState(address _pool) internal view returns (PoolRewardsState memory) {
    PoolRewardsState memory poolState = poolRewardsState[_pool];
    if (poolState.timestamp == 0) {
      poolState.timestamp = _getEpochStartTime();
      // Use the vault decimal here to improve the calculation precision as this value will be devided by the totalSupply of the vault.
      // If there is a big different between the YOP decimals and the vault decimals then the calculation won't be very accurate.
      poolState.epochRate = FIRST_EPOCH_EMISSION * (10**_getPoolDecimals(_pool));
    }
    if (poolState.timestamp == _getBlockTimestamp()) {
      // poolState data is up to date, just return it
      return poolState;
    }
    uint256 start = poolState.timestamp;
    uint256 end = _getBlockTimestamp();
    EpochInfo memory epochInfo = _getCurrentEpoch();
    if (end > start) {
      uint256 r = poolState.epochRate;
      uint256 totalSupply = _getPoolTotalSupply(_pool);
      uint256 totalAccrued;
      // Start from where last time the snapshot was taken, and loop through the epochs.
      // We the calculate the for each epoch, how many rewards the vault should get and all them up.
      // Finally we divide the value by the totalSupply of the vault.
      for (uint256 i = poolState.epochCount; i <= epochInfo.epochCount; i++) {
        uint256 epochStart = _getEpochStartTime() + SECONDS_PER_EPOCH * i;
        uint256 epochEnd = epochStart + SECONDS_PER_EPOCH;
        // Get the rate, take the vaultsRewardsRatio and the weight of the vault into account.
        uint256 currentPoolRate = _getCurrentRateForPool(_pool, r);
        uint256 duration;
        // For each epoch, we will check if it is: the starting point, the ending point, or in between.
        // Add these to the total duration.
        if (epochStart <= start && end <= epochEnd) {
          // Inside the same epoch, so it is the starting epoch and the ending epoch.
          duration = end - start;
        } else if (epochStart <= start && start <= epochEnd && end > epochEnd) {
          // This is the starting epoch, not the ending epoch. The time included is from start to epochEnd.
          duration = epochEnd - start;
        } else if (end <= epochEnd && end >= epochStart && start < epochStart) {
          // This is the ending epoch, not the start epoch. The time included is from the epochStart to the end.
          duration = end - epochStart;
        } else {
          // Neither the starting or endoing epoch. So the whole epoch should be included.
          duration = epochEnd - epochStart;
        }
        totalAccrued += currentPoolRate * duration;
        if (end <= epochEnd || i == MAX_EPOCH_COUNT - 1) {
          // This is either the ending epoch, or the last epoch ever. Do the calcuation and store the value.
          // Solidity doesn't have support for fix-point numbers, so we use a library here to store this value.
          if (totalSupply > 0) {
            poolState.index = poolState.index.add(
              PRBMathUD60x18Typed.fromUint(totalAccrued).div(PRBMathUD60x18Typed.fromUint(SECONDS_PER_EPOCH)).div(
                PRBMathUD60x18Typed.fromUint(totalSupply)
              )
            );
            // the rate is per month and use the decimal of the vault
            poolState.totalRewards +=
              (totalAccrued * (10**YOP_DECIMAL)) /
              SECONDS_PER_EPOCH /
              (10**_getPoolDecimals(_pool));
          }
          poolState.timestamp = end;
          poolState.epochCount = i;
          poolState.epochRate = r;
          break;
        }
        // reduce the rate based on the deflation setting
        r = (r * (MAX_BPS - DEFLATION_RATE)) / MAX_BPS;
      }
    }
    return poolState;
  }

  function _calculateUserState(
    address _pool,
    bytes32 _user,
    PoolRewardsState memory _poolState
  ) internal view returns (uint256) {
    uint256 poolDecimal = _getPoolDecimals(_pool);
    PRBMath.UD60x18 memory currentVaultIndex = _poolState.index; // = T2 * R / V
    PRBMath.UD60x18 memory previousUserIndex = userRewardsState[_pool][_user]; // = T1 * R /V
    PRBMath.UD60x18 memory diff = currentVaultIndex.sub(previousUserIndex);
    uint256 tokenDelta;
    if (diff.value > 0) {
      uint256 userBalance = _balanceFor(_pool, _user);
      // = U * (T2 * R / V  - T1 * R /V) = U * R / V * (T2 - T1)
      tokenDelta = PRBMathUD60x18Typed.toUint(
        PRBMathUD60x18Typed.fromUint(userBalance).mul(diff).div(PRBMathUD60x18Typed.fromUint(10**poolDecimal)).mul(
          PRBMathUD60x18Typed.fromUint(10**YOP_DECIMAL)
        )
      ); // prevent phantom overflow
    }
    return tokenDelta;
  }

  function _weightForVault(address _vault) internal view returns (uint256) {
    if (totalWeightForVaults > 0) {
      return (perVaultRewardsWeight[_vault] * WEIGHT_AMP) / totalWeightForVaults;
    }
    return 0;
  }

  /// @dev This function should only be used when claiming rewards
  function _updateStateForVaults(address[] memory _vaults, bytes32 _account) internal virtual {
    for (uint256 i = 0; i < _vaults.length; i++) {
      require(vaultAddresses.contains(_vaults[i]), "!vault");
      // since this function is only called when claiming, if the account doesn't have any balance in a vault
      // then there is no need to update the checkpoint for the user as it will always be 0
      if (IVault(_vaults[i]).balanceOf(_account.bytes32ToAddress()) > 0) {
        _updatePoolState(_vaults[i]);
        _updateUserState(_vaults[i], _account);
      }
    }
  }

  function _updateStateForStaking(uint256[] memory _stakeIds) internal {
    if (stakingContract != address(0)) {
      _updatePoolState(stakingContract);
      for (uint256 i = 0; i < _stakeIds.length; i++) {
        _updateUserState(stakingContract, _stakeIds[i].uint256ToBytes32());
      }
    }
  }

  function _claim(bytes32[] memory _accounts, address _to) internal returns (uint256, uint256[] memory) {
    require(_to != address(0), "!input");
    uint256 toTransfer = 0;
    uint256[] memory claimedRewards = new uint256[](_accounts.length);
    for (uint256 i = 0; i < _accounts.length; i++) {
      ClaimRecord memory record = claimRecords[_accounts[i]];
      uint256 claimable = record.totalAvailable - record.totalClaimed;
      claimRecords[_accounts[i]].totalClaimed = record.totalAvailable;
      claimedRewards[i] = claimable;
      toTransfer += claimable;
    }
    if (toTransfer > 0) {
      // this requires the reward contract is approved as a spender for the wallet
      IERC20Upgradeable(_getYOPAddress()).safeTransferFrom(rewardsWallet, _to, toTransfer);
    }
    return (toTransfer, claimedRewards);
  }

  function _unclaimedVaultRewards(address[] memory _vaults, bytes32 _user) internal view returns (uint256) {
    uint256 total = claimRecords[_user].totalAvailable;
    for (uint256 i = 0; i < _vaults.length; i++) {
      PoolRewardsState memory vaultState = _calculatePoolState(_vaults[i]);
      uint256 rewards = _calculateUserState(_vaults[i], _user, vaultState);
      total += rewards;
    }
    return total - claimRecords[_user].totalClaimed;
  }

  function _unclaimedStakingRewards(uint256[] memory _stakeIds) internal view returns (uint256) {
    uint256 totalUnclaimed = 0;
    if (stakingContract != address(0)) {
      PoolRewardsState memory poolState = _calculatePoolState(stakingContract);
      for (uint256 i = 0; i < _stakeIds.length; i++) {
        uint256 rewardsDelta = _calculateUserState(stakingContract, bytes32(_stakeIds[i]), poolState);
        totalUnclaimed += (claimRecords[bytes32(_stakeIds[i])].totalAvailable +
          rewardsDelta -
          claimRecords[bytes32(_stakeIds[i])].totalClaimed);
      }
    }
    return totalUnclaimed;
  }

  /// @dev use a function and allow override to make testing easier
  function _getEpochStartTime() internal view virtual returns (uint256) {
    return emissionStartTime;
  }

  /// @dev use a function and allow override to make testing easier
  function _getEpochEndTime() internal view virtual returns (uint256) {
    return emissionEndTime;
  }

  /// @dev use a function and allow override to make testing easier
  function _getYOPAddress() internal view virtual returns (address) {
    return yopContractAddress;
  }

  /// @dev use a function and allow override to make testing easier
  function _getBlockTimestamp() internal view virtual returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp;
  }

  function _getPoolDecimals(address _pool) internal view returns (uint8) {
    if (_pool == stakingContract) {
      // staking contract is for staking YOP tokens, so we can just use the decimals of YOP
      return YOP_DECIMAL;
    } else {
      return IERC20MetadataUpgradeable(_pool).decimals();
    }
  }

  function _getPoolTotalSupply(address _pool) internal view returns (uint256) {
    if (_pool == stakingContract) {
      return IStaking(_pool).totalWorkingSupply();
    } else {
      return _getVaultTotalSupply(_pool);
    }
  }

  function _balanceFor(address _pool, bytes32 _account) internal view returns (uint256) {
    if (_pool == stakingContract) {
      return IStaking(_pool).workingBalanceOfStake(_account.bytes32ToUint256());
    } else {
      return _getVaultBalanceOf(_pool, _account.bytes32ToAddress());
    }
  }

  function _getVaultTotalSupply(address _vault) internal view virtual returns (uint256) {
    return IERC20MetadataUpgradeable(_vault).totalSupply();
  }

  function _getVaultBalanceOf(address _vault, address _user) internal view virtual returns (uint256) {
    return IERC20Upgradeable(_vault).balanceOf(_user);
  }

  function _getCurrentRateForPool(address _pool, uint256 _rate) internal view returns (uint256) {
    if (_pool == stakingContract) {
      return ((_rate * stakingRewardsWeight) / (stakingRewardsWeight + vaultsRewardsWeight));
    } else {
      return
        (_rate * vaultsRewardsWeight * _weightForVault(_pool)) /
        (stakingRewardsWeight + vaultsRewardsWeight) /
        WEIGHT_AMP;
    }
  }
}
