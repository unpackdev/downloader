// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC677ReceiverInterface} from
  "@chainlink/contracts/src/v0.8/interfaces/ERC677ReceiverInterface.sol";
import "./LinkTokenInterface.sol";

import "./IERC165.sol";
import "./Checkpoints.sol";
import "./SafeCast.sol";

import "./IMigratable.sol";
import "./IRewardVault.sol";
import "./IStakingOwner.sol";
import "./IStakingPool.sol";
import "./Migratable.sol";
import "./PausableWithAccessControl.sol";

/// @notice This contract is the base contract for staking pools. Each staking pool extends this
/// contract.
/// @dev This contract is abstract and must be inherited.
/// @dev invariant maxPoolSize must be greater than or equal to the totalPrincipal.
/// @dev invariant maxPoolSize must be greater than or equal to the maxPrincipalPerStaker.
/// @dev invariant contract's LINK token balance should be greater than or equal to the
/// totalPrincipal.
/// @dev invariant The migrated staked LINK amount must be less than or equal to the staker's staked
/// LINK amount +
/// rewards from the v0.1 staking pool.
/// @dev invariant The migrated staked LINK amount must be less than or equal to the
/// maxPrincipalPerStaker.
/// @dev We only support LINK token in v0.2 staking. Rebasing tokens, ERC777 tokens, fee-on-transfer
/// tokens or tokens that do not have 18 decimal places are not supported.
abstract contract StakingPoolBase is
  ERC677ReceiverInterface,
  IStakingPool,
  IStakingOwner,
  Migratable,
  PausableWithAccessControl
{
  using Checkpoints for Checkpoints.History;
  using SafeCast for uint256;

  /// @notice This error is thrown when the staking pool is not active.
  error PoolNotActive();

  /// @notice This error is thrown when the unbonding period is set to 0
  error InvalidUnbondingPeriod();

  /// @notice This error is thrown when the claim period is set to 0
  error InvalidClaimPeriod();

  /// @notice This error is thrown whenever a staker tries to unbond during
  /// their unbonding period.
  /// @param unbondingPeriodEndsAt The time the unbonding period is finished
  error UnbondingOrClaimPeriodActive(uint256 unbondingPeriodEndsAt);

  /// @notice This error is thrown whenever a staker tries to unstake outside
  /// the claim period
  /// @param staker The staker trying to unstake
  error StakerNotInClaimPeriod(address staker);

  /// @notice This error is thrown when an invalid claim period range is provided
  /// @param minClaimPeriod The min claim period
  /// @param maxClaimPeriod The max claim period
  error InvalidClaimPeriodRange(uint256 minClaimPeriod, uint256 maxClaimPeriod);

  /// @notice This error is thrown when an invalid max unbonding period is provided
  /// @param maxUnbondingPeriod The max unbonding period
  error InvalidMaxUnbondingPeriod(uint256 maxUnbondingPeriod);

  /// @notice This error is thrown when a staker tries to stake and the reward vault connected to
  /// this pool is not open or is paused
  error RewardVaultNotActive();

  /// @notice This error is thrown when admin tries to open the pool and the reward vault connected
  /// to this pool has not had rewards added to it.
  error RewardVaultHasNoRewards();

  /// @notice This error is thrown when admin tries to set a new reward vault and the old reward
  /// vault is not closed yet.
  error RewardVaultNotClosed();

  /// @notice This event is emitted whenever a staker initiates the unbonding
  /// period.
  /// @param staker The staker that has started their unbonding period.
  event UnbondingPeriodStarted(address indexed staker);

  /// @notice This event is emitted when a staker's unbonding period is reset
  /// @param staker The staker that has reset their unbonding period
  event UnbondingPeriodReset(address indexed staker);

  /// @notice This event is emitted when the unbonding period has been changed
  /// @param oldUnbondingPeriod The old unbonding period
  /// @param newUnbondingPeriod The new unbonding period
  event UnbondingPeriodSet(uint256 oldUnbondingPeriod, uint256 newUnbondingPeriod);

  /// @notice This event is emitted when the claim period is set
  /// @param oldClaimPeriod The old claim period
  /// @param newClaimPeriod The new claim period
  event ClaimPeriodSet(uint256 oldClaimPeriod, uint256 newClaimPeriod);

  /// @notice This event is emitted when the reward vault is set
  /// @param oldRewardVault The old reward vault
  /// @param newRewardVault The new reward vault
  event RewardVaultSet(address indexed oldRewardVault, address indexed newRewardVault);

  /// @notice This event is emitted when the staker is migrated to the migration target
  /// @param migrationTarget The migration target
  /// @param amount The staker's staked LINK amount that was migrated in juels
  /// @param migrationData The migration data
  event StakerMigrated(address indexed migrationTarget, uint256 amount, bytes migrationData);

  /// @notice This struct defines the params required by the Staking contract's
  /// constructor.
  struct ConstructorParamsBase {
    /// @notice The LINK Token
    LinkTokenInterface LINKAddress;
    /// @notice The initial maximum total stake amount for all stakers in the
    /// pool
    uint96 initialMaxPoolSize;
    /// @notice The initial maximum stake amount for a staker
    uint96 initialMaxPrincipalPerStaker;
    /// @notice The minimum stake amount that a staker must stake
    uint96 minPrincipalPerStaker;
    /// @notice The initial unbonding period
    uint32 initialUnbondingPeriod;
    /// @notice The max value that the unbonding period can be set to
    uint32 maxUnbondingPeriod;
    /// @notice The initial claim period
    uint32 initialClaimPeriod;
    /// @notice The min value that the claim period can be set to
    uint32 minClaimPeriod;
    /// @notice The max value that the claim period can be set to
    uint32 maxClaimPeriod;
    /// @notice The time it requires to transfer admin role
    uint48 adminRoleTransferDelay;
  }

  /// @notice This struct defines the params that the pool is configured with
  struct PoolConfigs {
    /// @notice The max amount of staked LINK allowed in the pool in juels. The max value of this
    /// field is expected to be less than 1 billion (10^9 * 10^18), which is less than the max value
    /// that can be represented by a uint96 (~7.9*10^28).
    uint96 maxPoolSize;
    /// @notice The max amount of LINK a staker can stake in juels. The max value of this field is
    /// expected to be less than 1 million (10^6 * 10^18), which is less than the max value that can
    /// be represented by a uint96 (~7.9*10^28).
    uint96 maxPrincipalPerStaker;
    /// @notice The length of the unbonding period in seconds. The max value of this field is
    /// expected to be less than a year, or 30 million (3.2*10^7), which is less than the max value
    /// that can be represented by a uint32 (~4.2*10^9).
    uint32 unbondingPeriod;
    /// @notice The length of the claim period in seconds. The max value of this field is
    /// expected to be less than a year, or 30 million (3.2*10^7), which is less than the max value
    /// that can be represented by a uint32 (~4.2*10^9).
    uint32 claimPeriod;
  }

  /// @notice This struct defines the state of the staking pool
  struct PoolState {
    /// @notice The total staked LINK amount amount in the pool
    uint256 totalPrincipal;
    /// @notice The time that the pool was closed
    uint256 closedAt;
  }

  /// @notice This struct defines the global state and configuration of the pool
  struct Pool {
    /// @notice The pool's configuration
    PoolConfigs configs;
    /// @notice The pool's state
    PoolState state;
  }

  /// @notice This is the ID for the initiator role, which is given to the
  /// addresses that will add open the pools, and set the merkle root for the community pool.
  /// @dev Hash: 6b8b15f1c11543d8280deaa7c24d12fffba6a357e4428e8c43e4234790186bff
  bytes32 public constant INITIATOR_ROLE = keccak256("INITIATOR_ROLE");
  /// @notice The LINK token
  LinkTokenInterface internal immutable i_LINK;
  /// @notice The staking pool state and configuration
  Pool internal s_pool;
  /// @notice Mapping of a staker's address to their staker state
  mapping(address staker => IStakingPool.Staker) internal s_stakers;
  /// @notice Migration proxy address
  address internal s_migrationProxy;
  /// @notice The latest reward vault address
  IRewardVault internal s_rewardVault;
  /// @notice The min amount of LINK that a staker can stake
  uint96 internal immutable i_minPrincipalPerStaker;
  /// @notice The min value that the claim period can be set to
  uint32 private immutable i_minClaimPeriod;
  /// @notice The max value that the claim period can be set to
  uint32 private immutable i_maxClaimPeriod;
  /// @notice The max value that the unbonding period can be set to
  uint32 private immutable i_maxUnbondingPeriod;
  /// @notice Flag that signals if the staking pool is open for staking
  bool internal s_isOpen;

  constructor(ConstructorParamsBase memory params)
    PausableWithAccessControl(params.adminRoleTransferDelay, msg.sender)
  {
    if (address(params.LINKAddress) == address(0)) revert InvalidZeroAddress();
    if (params.minPrincipalPerStaker == 0) revert InvalidMinStakeAmount();
    if (params.minPrincipalPerStaker >= params.initialMaxPrincipalPerStaker) {
      revert InvalidMinStakeAmount();
    }
    if (params.maxUnbondingPeriod == 0) {
      revert InvalidMaxUnbondingPeriod(params.maxUnbondingPeriod);
    }
    if (params.minClaimPeriod == 0 || params.minClaimPeriod >= params.maxClaimPeriod) {
      revert InvalidClaimPeriodRange(params.minClaimPeriod, params.maxClaimPeriod);
    }

    i_LINK = params.LINKAddress;
    i_minPrincipalPerStaker = params.minPrincipalPerStaker;

    i_maxUnbondingPeriod = params.maxUnbondingPeriod;
    _setUnbondingPeriod(params.initialUnbondingPeriod);

    _setPoolConfig(params.initialMaxPoolSize, params.initialMaxPrincipalPerStaker);

    i_minClaimPeriod = params.minClaimPeriod;
    i_maxClaimPeriod = params.maxClaimPeriod;
    _setClaimPeriod(params.initialClaimPeriod);
  }

  /// @inheritdoc IMigratable
  /// @dev This will migrate the staker's staked LINK
  /// @dev precondition This contract must be closed and upgraded to a new pool.
  /// @dev precondition The migration target must be set.
  /// @dev precondition The caller must be staked in the pool.
  function migrate(bytes calldata data) external whenClosed validateMigrationTargetSet {
    // must be in storage to get access to latest()
    IStakingPool.Staker storage staker = s_stakers[msg.sender];

    uint224 history = staker.history.latest();
    uint112 stakerPrincipal = uint112(history >> 112);
    uint112 stakerStakedAtTime = uint112(history);
    if (stakerPrincipal == 0) revert StakeNotFound(msg.sender);

    bytes memory migrationData = abi.encode(msg.sender, stakerStakedAtTime, data);

    // Finalize staker's rewards to include any rewards they have earned before resetting the
    // principal and stakedAtTime.
    s_rewardVault.concludeRewardPeriod({
      staker: msg.sender,
      oldPrincipal: stakerPrincipal,
      stakedAt: stakerStakedAtTime,
      unstakedAmount: stakerPrincipal,
      shouldForfeit: false
    });
    s_pool.state.totalPrincipal -= stakerPrincipal;

    // do not reset staked at time to not reset the multiplier because staker is not forfeiting
    // rewards when migrating
    _updateStakerHistory({
      staker: staker,
      latestPrincipal: 0,
      latestStakedAtTime: stakerStakedAtTime
    });
    // The return value is not checked since the call will revert if any balance, allowance or
    // receiver conditions fail.
    i_LINK.transferAndCall({to: s_migrationTarget, value: stakerPrincipal, data: migrationData});
    emit StakerMigrated(s_migrationTarget, stakerPrincipal, migrationData);
  }

  /// @notice Starts the unbonding period for the staker.  A staker may unstake
  /// their staked LINK during the claim period that follows the unbonding period.
  /// @dev precondition The caller must be staked in the pool.
  /// @dev precondition The caller must not be in an unbonding period.
  /// @dev precondition The caller must not be in a claim period.
  function unbond() external virtual {
    Staker storage staker = s_stakers[msg.sender];
    uint224 history = staker.history.latest();
    uint112 stakerPrincipal = uint112(history >> 112);
    if (stakerPrincipal == 0) revert StakeNotFound(msg.sender);

    _unbond(staker);
  }

  /// @notice Sets the new unbonding period for the pool.  Stakers that are
  /// already unbonding will not be affected.
  /// @param newUnbondingPeriod The new unbonding period
  /// @dev precondition The caller must have the default admin role.
  /// @dev precondition Cannot be called after the pool is closed.
  function setUnbondingPeriod(uint256 newUnbondingPeriod)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    whenBeforeClosing
  {
    _setUnbondingPeriod(newUnbondingPeriod);
  }

  /// @notice Returns the max unbonding period
  /// @return uint256 The max value that the unbonding period can be set to
  function getMaxUnbondingPeriod() external view returns (uint256) {
    return (i_maxUnbondingPeriod);
  }

  /// @notice Set the claim period
  /// @param claimPeriod The claim period
  /// @dev precondition Cannot be called after the pool is closed.
  function setClaimPeriod(uint256 claimPeriod)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    whenBeforeClosing
  {
    _setClaimPeriod(claimPeriod);
  }

  /// @notice Sets the new reward vault for the pool
  /// @param newRewardVault The new reward vault
  /// @dev precondition The caller must have the default admin role.
  /// @dev precondition Cannot be called after the pool is closed.
  function setRewardVault(IRewardVault newRewardVault)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    whenBeforeClosing
  {
    if (address(newRewardVault) == address(0)) revert InvalidZeroAddress();
    address oldRewardVault = address(s_rewardVault);
    if (oldRewardVault == address(newRewardVault)) return;
    if (address(s_rewardVault) != address(0) && s_rewardVault.isOpen()) {
      revert RewardVaultNotClosed();
    }
    if (
      address(s_rewardVault) != address(0)
        && (!newRewardVault.isOpen() || newRewardVault.isPaused())
    ) revert RewardVaultNotActive();
    if (address(s_rewardVault) != address(0) && !newRewardVault.hasRewardAdded()) {
      revert RewardVaultHasNoRewards();
    }

    s_rewardVault = newRewardVault;
    emit RewardVaultSet(oldRewardVault, address(newRewardVault));
  }

  /// @notice LINK transfer callback function called when transferAndCall is called with this
  /// contract as a target.
  /// @param sender staker's address if they stake into the pool by calling transferAndCall on the
  /// LINK token, or MigrationProxy contract when a staker migrates from V0.1 to V0.2
  /// @param amount Amount of LINK token transferred
  /// @param data Bytes data received, represents migration path
  /// @inheritdoc ERC677ReceiverInterface
  /// @dev precondition The migration proxy must be set.
  /// @dev precondition This contract must be open and not paused.
  /// @dev precondition The reward vault must be open and not paused.
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  ) external validateFromLINK validateMigrationProxySet whenOpen whenRewardVaultOpen whenNotPaused {
    if (amount == 0) return;

    // Check if this call was forwarded from the migration proxy.
    address staker = sender == s_migrationProxy ? _getStakerAddress(data) : sender;
    if (staker == address(0)) revert InvalidZeroAddress();

    // includes access check for non migration proxy
    _validateOnTokenTransfer(sender, staker, data);

    Staker storage stakerState = s_stakers[staker];
    uint224 history = stakerState.history.latest();
    uint256 stakerPrincipal = uint256(history >> 112);
    uint256 stakedAt = uint112(history);

    _resetUnbondingPeriod(stakerState, staker);

    s_rewardVault.concludeRewardPeriod({
      staker: staker,
      oldPrincipal: stakerPrincipal,
      unstakedAmount: 0,
      shouldForfeit: false,
      stakedAt: stakedAt
    });

    _increaseStake(staker, stakerPrincipal + amount, amount);
  }

  /// @notice Returns the minimum and maximum claim periods that can be set by the owner
  /// @return uint256 minimum claim period
  /// @return uint256 maximum claim period
  function getClaimPeriodLimits() external view returns (uint256, uint256) {
    return (i_minClaimPeriod, i_maxClaimPeriod);
  }

  // =================
  // IStakingOwner
  // =================

  /// @inheritdoc IStakingOwner
  /// @dev precondition The caller must have the default admin role.
  function setPoolConfig(
    uint256 maxPoolSize,
    uint256 maxPrincipalPerStaker
  ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) whenOpen {
    _setPoolConfig(maxPoolSize, maxPrincipalPerStaker);
  }

  /// @inheritdoc IStakingOwner
  /// @dev precondition The caller must have the initiator role.
  function open()
    external
    onlyRole(INITIATOR_ROLE)
    whenBeforeOpening
    validateRewardVaultSet
    whenRewardVaultOpen
    whenRewardVaultHasRewards
  {
    _validateBeforeOpen();
    s_isOpen = true;
    emit PoolOpened();
  }

  /// @inheritdoc IStakingOwner
  /// @dev precondition The caller must have the default admin role.
  function close() external onlyRole(DEFAULT_ADMIN_ROLE) whenOpen {
    s_isOpen = false;
    s_pool.state.closedAt = block.timestamp;
    emit PoolClosed();
  }

  /// @inheritdoc IStakingOwner
  /// @dev precondition The caller must have the default admin role.
  function setMigrationProxy(address migrationProxy)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    whenBeforeClosing
  {
    if (migrationProxy == address(0)) revert InvalidZeroAddress();

    if (s_migrationProxy == migrationProxy) return;
    address oldMigrationProxy = s_migrationProxy;
    s_migrationProxy = migrationProxy;

    emit MigrationProxySet(oldMigrationProxy, migrationProxy);
  }

  // =================
  // IStakingPool
  // =================

  /// @inheritdoc IStakingPool
  /// @dev precondition The caller must be staked in the pool.
  /// @dev precondition The caller must be in the claim period or the pool must be closed or paused.
  /// @dev There is a possible reentrancy attack here where a malicious admin
  /// can point this pool to a malicious reward vault that calls unstake on the
  /// pool again.  This reentrancy attack is possible as the pool updates the
  /// staker's staked LINK amount after it calls concludeRewardPeriod on the configured reward
  /// vault.  This scenario is mitigated by forcing the admin to go through
  /// a timelock period that is longer than the unbonding period, which will
  /// provide stakers sufficient time to withdraw their staked LINK from the
  /// pool before a malicious reward vault is set.
  function unstake(uint256 amount) external {
    // cannot unstake 0
    if (amount == 0) revert UnstakeZeroAmount();

    Staker storage staker = s_stakers[msg.sender];
    if (!_canUnstake(staker)) {
      revert StakerNotInClaimPeriod(msg.sender);
    }

    uint224 history = staker.history.latest();
    uint256 stakerPrincipal = uint256(history >> 112);
    uint256 stakedAt = uint112(history);
    // verify that the staker has enough staked LINK amount to unstake
    if (amount > stakerPrincipal) revert UnstakeExceedsPrincipal();

    uint256 updatedPrincipal = stakerPrincipal - amount;
    // in the case of a partial withdrawal, verify new staked LINK amount is above minimum
    if (amount < stakerPrincipal && updatedPrincipal < i_minPrincipalPerStaker) {
      revert UnstakePrincipalBelowMinAmount();
    }

    s_rewardVault.concludeRewardPeriod({
      staker: msg.sender,
      oldPrincipal: stakerPrincipal,
      unstakedAmount: amount,
      shouldForfeit: true,
      stakedAt: stakedAt
    });

    s_pool.state.totalPrincipal -= amount;

    // Reset the staker's staked at time to 0 to prevent the multiplier
    // from growing if the staker has unstaked all their staked LINK
    _updateStakerHistory({
      staker: staker,
      latestPrincipal: updatedPrincipal,
      latestStakedAtTime: updatedPrincipal == 0 ? 0 : block.timestamp
    });
    // The return value is not checked since the call will revert if any balance, allowance or
    // receiver conditions fail.
    i_LINK.transfer(msg.sender, amount);

    emit Unstaked(msg.sender, amount, updatedPrincipal, s_pool.state.totalPrincipal);
  }

  /// @inheritdoc IStakingPool
  function getTotalPrincipal() external view returns (uint256) {
    return s_pool.state.totalPrincipal;
  }

  /// @inheritdoc IStakingPool
  function getStakerPrincipal(address staker) external view returns (uint256) {
    return uint112(s_stakers[staker].history.latest() >> 112);
  }

  /// @inheritdoc IStakingPool
  function getStakerPrincipalAt(
    address staker,
    uint256 blockNumber
  ) external view returns (uint256) {
    // `Checkpoints` requires to exclude the current block when calling `getAtBlock`
    return (blockNumber == block.number)
      ? uint112(s_stakers[staker].history.latest() >> 112)
      : uint112(s_stakers[staker].history.getAtBlock(blockNumber) >> 112);
  }

  /// @inheritdoc IStakingPool
  function getStakerStakedAtTime(address staker) external view returns (uint256) {
    return uint112(s_stakers[staker].history.latest());
  }

  /// @inheritdoc IStakingPool
  function getStakerStakedAtTimeAt(
    address staker,
    uint256 blockNumber
  ) external view returns (uint256) {
    // `Checkpoints` requires to exclude the current block when calling `getAtBlock`
    return (blockNumber == block.number)
      ? uint112(s_stakers[staker].history.latest())
      : uint112(s_stakers[staker].history.getAtBlock(blockNumber));
  }

  /// @inheritdoc IStakingPool
  function getRewardVault() external view returns (IRewardVault) {
    return s_rewardVault;
  }

  /// @inheritdoc IStakingPool
  function getChainlinkToken() external view returns (address) {
    return address(i_LINK);
  }

  /// @inheritdoc IStakingPool
  function getMigrationProxy() external view returns (address) {
    return s_migrationProxy;
  }

  /// @inheritdoc IStakingPool
  function isOpen() external view returns (bool) {
    return s_isOpen;
  }

  /// @inheritdoc IStakingPool
  function isActive() external view returns (bool) {
    return _isActive();
  }

  /// @inheritdoc IStakingPool
  function getStakerLimits() external view returns (uint256, uint256) {
    return (i_minPrincipalPerStaker, s_pool.configs.maxPrincipalPerStaker);
  }

  /// @inheritdoc IStakingPool
  function getMaxPoolSize() external view returns (uint256) {
    return s_pool.configs.maxPoolSize;
  }

  /// @notice Returns the time a staker's unbonding period ends
  /// @param staker The address of the staker to query
  /// @return uint256 The timestamp of when the staker's unbonding period ends.
  /// This value will be 0 if the unbonding period is not active.
  function getUnbondingEndsAt(address staker) external view returns (uint256) {
    return s_stakers[staker].unbondingPeriodEndsAt;
  }

  /// @notice Returns the pool's unbonding parameters
  /// @return uint256 The pool's unbonding period
  /// @return uint256 The pools's claim period
  function getUnbondingParams() external view returns (uint256, uint256) {
    return (s_pool.configs.unbondingPeriod, s_pool.configs.claimPeriod);
  }

  /// @notice Returns the time a staker's claim period ends
  /// @param staker The staker trying to unstake their staked LINK
  /// @return uint256 The timestamp of when the staker's claim period ends.
  /// This value will be 0 if the unbonding period has not started.
  function getClaimPeriodEndsAt(address staker) external view returns (uint256) {
    return s_stakers[staker].claimPeriodEndsAt;
  }

  // ===============
  // ERC165
  // ===============

  /// @notice This function allows the calling contract to
  /// check if the contract deployed at this address is a valid
  /// LINKTokenReceiver.  A contract is a valid LINKTokenReceiver
  /// if it implements the onTokenTransfer function.
  /// @param interfaceID The ID of the interface to check against
  /// @return bool True if the contract is a valid LINKTokenReceiver.
  function supportsInterface(bytes4 interfaceID) public view override returns (bool) {
    return interfaceID == this.onTokenTransfer.selector || super.supportsInterface(interfaceID);
  }

  // =========
  // Helpers
  // =========

  /// @notice Resets a staker's unbonding period
  /// @param stakerState The staker's current state
  /// @param staker The address of the staker to reset the unbonding period for
  /// @dev This sets the stakerState's unbondingPeriodEndsAt and
  /// claimPeriodEndsAt to 0
  function _resetUnbondingPeriod(Staker storage stakerState, address staker) internal {
    if (stakerState.unbondingPeriodEndsAt != 0) {
      delete stakerState.unbondingPeriodEndsAt;
      delete stakerState.claimPeriodEndsAt;
      emit UnbondingPeriodReset(staker);
    }
  }

  /// @inheritdoc Migratable
  /// @dev precondition The migration target must implement the onTokenTransfer function.
  /// @dev precondition Cannot be called after the pool is closed.
  function _validateMigrationTarget(address newMigrationTarget) internal override whenBeforeClosing {
    Migratable._validateMigrationTarget(newMigrationTarget);
    if (
      !IERC165(newMigrationTarget).supportsInterface(
        ERC677ReceiverInterface.onTokenTransfer.selector
      )
    ) {
      revert InvalidMigrationTarget();
    }
  }

  /// @notice Validate for when LINK is staked or migrated into the pool
  /// @param sender The address transferring LINK into the pool. Could be the migration proxy
  /// contract or the staker.
  /// @param staker The address staking or migrating LINK into the pool
  /// @param data Arbitrary data passed when staking or migrating
  function _validateOnTokenTransfer(
    address sender,
    address staker,
    bytes calldata data
  ) internal view virtual;

  /// @notice Validates pool state before opening
  function _validateBeforeOpen() internal view virtual;

  /// @notice Util function for setting the pool config
  /// @param maxPoolSize The max amount of staked LINK allowed in the pool
  /// @param maxPrincipalPerStaker The max amount of LINK a staker can stake
  /// in the pool.
  function _setPoolConfig(uint256 maxPoolSize, uint256 maxPrincipalPerStaker) internal {
    PoolConfigs storage configs = s_pool.configs;
    // only allow increasing the maxPoolSize
    if (maxPoolSize == 0 || maxPoolSize < configs.maxPoolSize) {
      revert InvalidPoolSize(maxPoolSize);
    }
    // only allow increasing the maxPrincipalPerStaker
    if (
      maxPrincipalPerStaker == 0 || maxPrincipalPerStaker > maxPoolSize
        || configs.maxPrincipalPerStaker > maxPrincipalPerStaker
    ) revert InvalidMaxStakeAmount(maxPrincipalPerStaker);

    if (configs.maxPoolSize != maxPoolSize) {
      configs.maxPoolSize = maxPoolSize.toUint96();
      emit PoolSizeIncreased(maxPoolSize);
    }
    if (configs.maxPrincipalPerStaker != maxPrincipalPerStaker) {
      configs.maxPrincipalPerStaker = maxPrincipalPerStaker.toUint96();
      emit MaxPrincipalAmountIncreased(maxPrincipalPerStaker);
    }
  }

  /// @notice Util function for setting the unbonding period
  /// @param unbondingPeriod The unbonding period
  function _setUnbondingPeriod(uint256 unbondingPeriod) internal {
    if (unbondingPeriod == 0 || unbondingPeriod > i_maxUnbondingPeriod) {
      revert InvalidUnbondingPeriod();
    }

    if (s_pool.configs.unbondingPeriod == unbondingPeriod) return;

    uint256 oldUnbondingPeriod = s_pool.configs.unbondingPeriod;
    s_pool.configs.unbondingPeriod = unbondingPeriod.toUint32();
    emit UnbondingPeriodSet(oldUnbondingPeriod, unbondingPeriod);
  }

  /// @notice Updates the staking pool state and the staker state
  /// @param sender The staker address
  /// @param newPrincipal The staker's staked LINK amount after staking
  /// @param amount The amount to stake
  function _increaseStake(address sender, uint256 newPrincipal, uint256 amount) internal {
    Staker storage staker = s_stakers[sender];

    // validate staking limits
    if (newPrincipal < i_minPrincipalPerStaker) {
      revert InsufficientStakeAmount();
    }
    if (newPrincipal > s_pool.configs.maxPrincipalPerStaker) {
      revert ExceedsMaxStakeAmount();
    }
    uint256 newTotalPrincipal = s_pool.state.totalPrincipal + amount;
    if (newTotalPrincipal > s_pool.configs.maxPoolSize) {
      revert ExceedsMaxPoolSize();
    }

    // update the pool state
    s_pool.state.totalPrincipal = newTotalPrincipal;

    // update the staker state
    _updateStakerHistory({
      staker: staker,
      latestPrincipal: newPrincipal,
      latestStakedAtTime: block.timestamp
    });

    emit Staked(sender, amount, newPrincipal, newTotalPrincipal);
  }

  /// @notice Gets the staker address from the data passed by the MigrationProxy contract
  /// @param data The data passed by the MigrationProxy contract
  /// @return The staker address
  function _getStakerAddress(bytes calldata data) internal pure returns (address) {
    if (data.length == 0) revert InvalidData();

    // decode the data
    (address staker) = abi.decode(data, (address));

    return staker;
  }

  /// @notice Checks to see whether or not a staker is eligible to
  /// unstake their staked LINK amount (when the pool is closed or, when the pool is open and they
  /// are in the claim period or, when pool is paused)
  /// @param staker The staker trying to unstake their staked LINK
  /// @return bool True if the staker is eligible to unstake
  function _canUnstake(Staker storage staker) internal view returns (bool) {
    return s_pool.state.closedAt != 0 || _inClaimPeriod(staker) || paused();
  }

  /// @notice Updates the staker's staked LINK amount history
  /// @param staker The staker to update
  /// @param latestPrincipal The staker's latest staked LINK amount
  /// @param latestStakedAtTime The staker's latest average staked at time
  function _updateStakerHistory(
    Staker storage staker,
    uint256 latestPrincipal,
    uint256 latestStakedAtTime
  ) internal {
    staker.history.push(
      (uint224(uint112(latestPrincipal)) << 112) | uint224(uint112(latestStakedAtTime))
    );
  }

  /// @notice Starts the unbonding period for the staker
  /// @param staker The staker trying to unbond
  function _unbond(Staker storage staker) internal {
    if (staker.unbondingPeriodEndsAt != 0 && block.timestamp <= staker.claimPeriodEndsAt) {
      revert UnbondingOrClaimPeriodActive(staker.unbondingPeriodEndsAt);
    }
    staker.unbondingPeriodEndsAt = (block.timestamp + s_pool.configs.unbondingPeriod).toUint128();
    staker.claimPeriodEndsAt = staker.unbondingPeriodEndsAt + s_pool.configs.claimPeriod;
    emit UnbondingPeriodStarted(msg.sender);
  }

  /// @notice Checks to see whether or not a staker is within the claim period
  /// to unstake their staked LINK
  /// @param staker The staker trying to unstake their staked LINK
  /// @return bool True if the staker is inside the claim period
  function _inClaimPeriod(Staker storage staker) private view returns (bool) {
    if (staker.unbondingPeriodEndsAt == 0 || block.timestamp < staker.unbondingPeriodEndsAt) {
      return false;
    }

    return block.timestamp <= staker.claimPeriodEndsAt;
  }

  /// @notice Util function for setting the claim period
  /// @param claimPeriod The claim period
  function _setClaimPeriod(uint256 claimPeriod) private {
    if (claimPeriod < i_minClaimPeriod || claimPeriod > i_maxClaimPeriod) {
      revert InvalidClaimPeriod();
    }

    if (s_pool.configs.claimPeriod == claimPeriod) return;

    uint256 oldClaimPeriod = s_pool.configs.claimPeriod;
    s_pool.configs.claimPeriod = claimPeriod.toUint32();

    emit ClaimPeriodSet(oldClaimPeriod, claimPeriod);
  }

  /// @notice Util function to check if the reward vault connected to this pool has rewards added to
  /// it
  /// @return bool True if the reward vault has rewards added to it, false otherwise
  function _hasRewardVaultRewardAdded() internal view virtual returns (bool) {
    return s_rewardVault.hasRewardAdded();
  }

  /// @notice Util function to check if the pool is active
  /// @return bool True if the pool is active, false otherwise
  function _isActive() internal view returns (bool) {
    return s_isOpen && !s_rewardVault.hasRewardDurationEnded(address(this));
  }

  // =========
  // Modifiers
  // =========

  /// @dev Reverts if not sent from the LINK token
  modifier validateFromLINK() {
    if (msg.sender != address(i_LINK)) revert SenderNotLinkToken();
    _;
  }

  /// @dev Reverts if migration proxy is not set
  modifier validateMigrationProxySet() {
    if (s_migrationProxy == address(0)) revert MigrationProxyNotSet();
    _;
  }

  /// @dev Reverts if reward vault is not set
  modifier validateRewardVaultSet() {
    if (address(s_rewardVault) == address(0)) revert RewardVaultNotSet();
    _;
  }

  /// @dev Reverts if pool is after an opening
  modifier whenBeforeOpening() {
    if (s_isOpen) revert PoolHasBeenOpened();
    if (s_pool.state.closedAt != 0) revert PoolHasBeenClosed();
    _;
  }

  /// @dev Reverts if the pool is already closed
  modifier whenBeforeClosing() {
    if (s_pool.state.closedAt != 0) revert PoolHasBeenClosed();
    _;
  }

  /// @dev Reverts if pool is not open
  modifier whenOpen() {
    if (!s_isOpen) revert PoolNotOpen();
    _;
  }

  /// @dev Reverts if pool is not active (is open and rewards are available for this pool)
  modifier whenActive() {
    if (!_isActive()) revert PoolNotActive();
    _;
  }

  /// @dev Reverts if pool is not closed
  modifier whenClosed() {
    if (s_pool.state.closedAt == 0) revert PoolNotClosed();
    _;
  }

  /// @dev Reverts if reward vault is not open or is paused
  modifier whenRewardVaultOpen() {
    if (!s_rewardVault.isOpen() || s_rewardVault.isPaused()) revert RewardVaultNotActive();
    _;
  }

  /// @dev Reverts if reward vault has not had rewards added to it
  modifier whenRewardVaultHasRewards() {
    if (!_hasRewardVaultRewardAdded()) revert RewardVaultHasNoRewards();
    _;
  }
}
