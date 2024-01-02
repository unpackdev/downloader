// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./LinkTokenInterface.sol";
import {TypeAndVersionInterface} from
  "@chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";

import "./Math.sol";
import "./SafeCast.sol";

import "./FixedPointMathLib.sol";

import "./IRewardVault.sol";
import "./IStakingPool.sol";
import "./PausableWithAccessControl.sol";
import "./CommunityStakingPool.sol";
import "./OperatorStakingPool.sol";

/// @notice This contract is the reward vault for the staking pools. Admin can deposit rewards into
/// the vault and set the aggregate reward rate for each pool to control the reward distribution.
/// @dev This contract interacts with the community and operator staking pools that it is connected
/// to. A reward vault is connected to only one community and operator staking pool during its
/// lifetime, which means when we upgrade either one of the pools or introduce a new type of pool,
/// we will need to update this contract and deploy a new reward vault.
/// @dev invariant LINK balance of the contract is greater than or equal to the sum of unvested
/// rewards.
/// @dev invariant The sum of all stakers' rewards is less than or equal to the sum of available
/// rewards.
/// @dev invariant The reward bucket with zero aggregate reward rate has zero reward.
/// @dev invariant Stakers' multipliers are within 0 and the max value.
/// @dev We only support LINK token in v0.2 staking. Rebasing tokens, ERC777 tokens, fee-on-transfer
/// tokens or tokens that do not have 18 decimal places are not supported.
contract RewardVault is IRewardVault, PausableWithAccessControl, TypeAndVersionInterface {
  using FixedPointMathLib for uint256;
  using SafeCast for uint256;

  /// @notice This error is thrown when the pool address is not one of the registered staking pools
  error InvalidPool();

  /// @notice This error is thrown when the reward amount is invalid when adding rewards
  error InvalidRewardAmount();

  /// @notice This error is thrown when the aggregate reward rate is invalid when adding rewards
  error InvalidEmissionRate();

  /// @notice This error is thrown when the delegation rate is invalid when setting delegation rate
  error InvalidDelegationRate();

  /// @notice This error is thrown when an address who doesn't have access tries to call a function
  /// For example, when the caller is not a rewarder and adds rewards to the vault, or
  /// when the caller is not a staking pool and tries to call updateRewardPerToken.
  error AccessForbidden();

  /// @notice This error is thrown whenever a zero-address is supplied when
  /// a non-zero address is required
  error InvalidZeroAddress();

  /// @notice This error is thrown when the reward duration is too short when adding rewards
  error RewardDurationTooShort();

  /// @notice this error is thrown when the rewards remaining are insufficient for the new
  /// delegation rate
  error InsufficentRewardsForDelegationRate();

  /// @notice This error is thrown when calling an operation that is not allowed when the vault is
  /// closed.
  error VaultAlreadyClosed();

  /// @notice This error is thrown when the staker tries to claim rewards and the staker has no
  /// rewards to claim.
  error NoRewardToClaim();

  /// @notice This event is emitted when the delegation rate is updated.
  /// @param oldDelegationRate The old delegationRate
  /// @param newDelegationRate The new delegationRate
  event DelegationRateSet(uint256 oldDelegationRate, uint256 newDelegationRate);

  /// @notice This event is emitted when rewards are added to the vault
  /// @param pool The pool to which the rewards are added
  /// @param amount The reward amount
  /// @param emissionRate The target aggregate reward rate (token/second)
  event RewardAdded(address indexed pool, uint256 amount, uint256 emissionRate);

  /// @notice This event is emitted when the vault is opened.
  event VaultOpened();

  /// @notice This event is emitted when the vault is closed.
  /// @param totalUnvestedRewards The total amount of unvested rewards at the
  /// time the vault was closed
  event VaultClosed(uint256 totalUnvestedRewards);

  /// @notice This event is emitted when the staker claims rewards
  event RewardClaimed(address indexed staker, uint256 claimedRewards);

  /// @notice This event is emitted when the forfeited rewards are shared back into the reward
  /// buckets.
  /// @param vestedReward The amount of forfeited rewards shared in juels
  /// @param vestedRewardPerToken The amount of forfeited rewards per token added.
  /// @param reclaimedReward The amount of forfeited rewards reclaimed.
  /// @param isOperatorReward True if the forfeited reward is from the operator staking pool.
  event ForfeitedRewardDistributed(
    uint256 vestedReward,
    uint256 vestedRewardPerToken,
    uint256 reclaimedReward,
    bool isOperatorReward
  );

  /// @notice This event is emitted when the community pool rewards are updated
  /// @param baseRewardPerToken The per-token base reward of the community staking pool
  /// pool
  event CommunityPoolRewardUpdated(uint256 baseRewardPerToken);

  /// @notice This event is emitted when the operator pool rewards are updated
  /// @param baseRewardPerToken The per-token base reward of the operator staking pool
  /// @param delegatedRewardPerToken The per-token delegated reward of the operator staking
  /// pool
  event OperatorPoolRewardUpdated(uint256 baseRewardPerToken, uint256 delegatedRewardPerToken);

  /// @notice This event is emitted when a staker's rewards are updated
  /// @param staker The staker address
  /// @param vestedBaseReward The staker's vested base rewards
  /// @param vestedDelegatedReward The staker's vested delegated rewards
  /// @param baseRewardPerToken The staker's base reward per token
  /// @param operatorDelegatedRewardPerToken The staker's delegated reward per token
  /// @param claimedBaseRewardsInPeriod The staker's claimed base rewards in the period
  event StakerRewardUpdated(
    address indexed staker,
    uint256 vestedBaseReward,
    uint256 vestedDelegatedReward,
    uint256 baseRewardPerToken,
    uint256 operatorDelegatedRewardPerToken,
    uint256 claimedBaseRewardsInPeriod
  );

  /// @notice This event is emitted when the staker rewards are finalized
  /// @param staker The staker address
  /// @param shouldForfeit True if the staker forfeited their rewards
  event RewardFinalized(address indexed staker, bool shouldForfeit);

  /// @notice The constructor parameters.
  struct ConstructorParams {
    /// @notice The LINK token.
    LinkTokenInterface linkToken;
    /// @notice The community staking pool.
    CommunityStakingPool communityStakingPool;
    /// @notice The operator staking pool.
    OperatorStakingPool operatorStakingPool;
    /// @notice The delegation rate expressed in basis points. For example, a delegation rate of
    /// 4.5% would be represented as 450 basis points.
    uint32 delegationRate;
    /// @notice The time it takes for a multiplier to reach its max value in seconds.
    uint32 multiplierDuration;
    /// @notice The time it requires to transfer admin role
    uint48 adminRoleTransferDelay;
  }

  /// @notice This struct is used to store the reward information for a reward bucket.
  struct RewardBucket {
    /// @notice The reward aggregate reward rate of the reward bucket in Juels/second.
    uint80 emissionRate;
    /// @notice The timestamp when the reward duration ends.
    uint80 rewardDurationEndsAt;
    /// @notice The last updated available reward per token of the reward bucket.
    /// This value only increases over time as more rewards vest to the
    /// stakers.
    uint80 vestedRewardPerToken;
  }

  /// @notice This struct is used to store the reward buckets states.
  struct RewardBuckets {
    /// @notice The reward bucket for the operator staking pool.
    RewardBucket operatorBase;
    /// @notice The reward bucket for the community staking pool.
    RewardBucket communityBase;
    /// @notice The reward bucket for the delegated rewards.
    RewardBucket operatorDelegated;
  }

  /// @notice This struct is used to store the vault config.
  struct VaultConfig {
    /// @notice The delegation rate expressed in basis points. For example, a delegation rate of
    /// 4.5% would be represented as 450 basis points.
    uint32 delegationRate;
    /// @notice Flag that signals if the reward vault is open
    bool isOpen;
  }

  /// @notice This struct is used to store the checkpoint information at the time the reward vault
  /// is closed
  struct VestingCheckpointData {
    /// @notice The total staked LINK amount of the operator staking pool at the time
    /// the reward vault was closed
    uint256 operatorPoolTotalPrincipal;
    /// @notice The total staked LINK amount of the community staking pool at the time
    /// the reward vault was closed
    uint256 communityPoolTotalPrincipal;
    /// @notice The block number of at the time the reward vault was migrated or closed
    uint256 finalBlockNumber;
  }

  /// @notice This struct is used for aggregating the return values of a function that calculates
  /// the reward aggregate reward rate splits.
  struct BucketRewardEmissionSplit {
    /// @notice The reward for the community staking pool
    uint256 communityReward;
    /// @notice The reward for the operator staking pool
    uint256 operatorReward;
    /// @notice The reward for the delegated staking pool
    uint256 operatorDelegatedReward;
    /// @notice The aggregate reward rate for the community staking pool
    uint256 communityRate;
    /// @notice The aggregate reward rate for the operator staking pool
    uint256 operatorRate;
    /// @notice The aggregate reward rate for the delegated staking pool
    uint256 delegatedRate;
  }

  /// @notice This is the ID for the rewarder role, which is given to the
  /// addresses that will add rewards to the vault.
  /// @dev Hash: beec13769b5f410b0584f69811bfd923818456d5edcf426b0e31cf90eed7a3f6
  bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");
  /// @notice The maximum possible value of a multiplier. Current implementation requires that this
  /// value is 1e18 (i.e. 100%).
  uint256 private constant MAX_MULTIPLIER = 1e18;
  /// @notice The denominator used to calculate the delegation rate.
  uint256 private constant DELEGATION_BASIS_POINTS_DENOMINATOR = 10000;
  /// @notice The multiplier ramp up period duration in seconds.
  uint256 private immutable i_multiplierDuration;
  /// @notice The LINK token
  LinkTokenInterface private immutable i_LINK;
  /// @notice The community staking pool.
  CommunityStakingPool private immutable i_communityStakingPool;
  /// @notice The operator staking pool.
  OperatorStakingPool private immutable i_operatorStakingPool;
  /// @notice The reward buckets.
  RewardBuckets private s_rewardBuckets;
  /// @notice The vault config.
  VaultConfig private s_vaultConfig;
  /// @notice The checkpoint information at the time the reward vault was closed
  VestingCheckpointData private s_finalVestingCheckpointData;
  /// @notice The packed timestamps of reward updates. First digits contain community reward
  /// update timestamp and last 18 digits contain operator timestamp, e.g., if both timestamps are
  /// 1_697_127_483_832 then the value would be 1_697_127_483_832_000_001_697_127_483_832.
  uint256 private s_packedRewardUpdateTimestamps;
  /// @notice Stores reward information for each staker
  mapping(address => StakerReward) private s_rewards;

  constructor(ConstructorParams memory params)
    PausableWithAccessControl(params.adminRoleTransferDelay, msg.sender)
  {
    if (address(params.linkToken) == address(0)) revert InvalidZeroAddress();
    if (address(params.communityStakingPool) == address(0)) revert InvalidZeroAddress();
    if (address(params.operatorStakingPool) == address(0)) revert InvalidZeroAddress();
    if (params.delegationRate > DELEGATION_BASIS_POINTS_DENOMINATOR) revert InvalidDelegationRate();

    i_multiplierDuration = params.multiplierDuration;
    i_LINK = params.linkToken;
    i_communityStakingPool = params.communityStakingPool;
    i_operatorStakingPool = params.operatorStakingPool;

    s_vaultConfig.delegationRate = params.delegationRate;
    emit DelegationRateSet(0, params.delegationRate);

    s_vaultConfig.isOpen = true;
    emit VaultOpened();
  }

  /// @notice Adds more rewards into the reward vault
  /// Calculates the reward duration from the amount and aggregate reward rate
  /// @dev To add rewards to all pools use address(0) as the pool address
  /// @dev There is a possibility that a fraction of the added rewards can be locked in this
  /// contract as dust, specifically, when the amount is not divided by the aggregate reward rate
  /// evenly. We
  /// will handle this case operationally and make sure that the amount is large relative to the
  /// aggregate reward rate so there will only be small dust (less than 10^18 juels).
  /// @param pool The staking pool address
  /// @param amount The reward amount
  /// @param emissionRate The target aggregate reward rate (token/second)
  /// @dev precondition The caller must have the REWARDER role.
  /// @dev precondition This contract must be open and not paused.
  /// @dev precondition The caller must have at least `amount` LINK tokens.
  /// @dev precondition The caller must have approved this contract for the transfer of at least
  /// `amount` LINK tokens.
  function addReward(
    address pool,
    uint256 amount,
    uint256 emissionRate
  ) external onlyRewarder whenOpen whenNotPaused {
    // check if the pool is either community staking pool or operator staking pool
    // if the pool is the zero address, then the reward is split between all pools
    if (
      pool != address(0) && pool != address(i_communityStakingPool)
        && pool != address(i_operatorStakingPool)
    ) {
      revert InvalidPool();
    }
    // check that the aggregate reward rate is greater than zero
    if (emissionRate == 0) revert InvalidEmissionRate();

    // update the reward per tokens
    _updateRewardPerToken();

    // update the reward buckets
    _updateRewardBuckets({pool: pool, amount: amount, emissionRate: emissionRate});

    // transfer the reward tokens to the reward vault
    // The return value is not checked since the call will revert if any balance, allowance or
    // receiver conditions fail.
    i_LINK.transferFrom({from: msg.sender, to: address(this), value: amount});

    emit RewardAdded(pool, amount, emissionRate);
  }

  /// @notice Returns the delegation rate
  /// @return The delegation rate expressed in basis points
  function getDelegationRate() external view returns (uint256) {
    return s_vaultConfig.delegationRate;
  }

  /// @notice Updates the delegation rate
  /// @param newDelegationRate The delegation rate.
  /// @dev precondition The caller must have the default admin role.
  function setDelegationRate(uint256 newDelegationRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 oldDelegationRate = s_vaultConfig.delegationRate;
    if (
      oldDelegationRate == newDelegationRate
        || newDelegationRate > DELEGATION_BASIS_POINTS_DENOMINATOR
    ) {
      revert InvalidDelegationRate();
    }

    uint256 communityRateWithoutDelegation =
      s_rewardBuckets.communityBase.emissionRate + s_rewardBuckets.operatorDelegated.emissionRate;

    uint256 delegatedRate = newDelegationRate == 0
      ? 0
      : communityRateWithoutDelegation * newDelegationRate / DELEGATION_BASIS_POINTS_DENOMINATOR;

    if (delegatedRate == 0 && newDelegationRate != 0 && communityRateWithoutDelegation != 0) {
      // delegated rate has rounded down to zero
      revert InsufficentRewardsForDelegationRate();
    }

    _updateRewardPerToken();

    uint256 unvestedRewards = _getUnvestedRewards(s_rewardBuckets.communityBase)
      + _getUnvestedRewards(s_rewardBuckets.operatorDelegated);
    uint256 communityRate = communityRateWithoutDelegation - delegatedRate;
    s_rewardBuckets.communityBase.emissionRate = communityRate.toUint80();
    s_rewardBuckets.operatorDelegated.emissionRate = delegatedRate.toUint80();

    // NOTE - the reward duration for both buckets need to be in sync.
    if (newDelegationRate == 0) {
      delete s_rewardBuckets.operatorDelegated.rewardDurationEndsAt;
      _updateRewardDurationEndsAt({
        bucket: s_rewardBuckets.communityBase,
        rewardAmount: unvestedRewards,
        emissionRate: communityRate
      });
    } else if (newDelegationRate == DELEGATION_BASIS_POINTS_DENOMINATOR) {
      delete s_rewardBuckets.communityBase.rewardDurationEndsAt;
      _updateRewardDurationEndsAt({
        bucket: s_rewardBuckets.operatorDelegated,
        rewardAmount: unvestedRewards,
        emissionRate: delegatedRate
      });
    } else if (unvestedRewards != 0) {
      uint256 delegatedRewards =
        unvestedRewards * newDelegationRate / DELEGATION_BASIS_POINTS_DENOMINATOR;
      uint256 communityRewards = unvestedRewards - delegatedRewards;
      _updateRewardDurationEndsAt({
        bucket: s_rewardBuckets.communityBase,
        rewardAmount: communityRewards,
        emissionRate: communityRate
      });
      _updateRewardDurationEndsAt({
        bucket: s_rewardBuckets.operatorDelegated,
        rewardAmount: delegatedRewards,
        emissionRate: delegatedRate
      });
    }

    s_vaultConfig.delegationRate = newDelegationRate.toUint32();

    emit DelegationRateSet(oldDelegationRate, newDelegationRate);
  }

  // =================
  // IRewardVault
  // =================

  /// @inheritdoc IRewardVault
  /// @dev precondition This contract must not be paused.
  /// @dev precondition The caller must be a staker with a non-zero reward.
  function claimReward() external whenNotPaused returns (uint256) {
    bool isOperator = _isOperator(msg.sender);

    _updateRewardPerToken(isOperator ? StakerType.OPERATOR : StakerType.COMMUNITY);

    IStakingPool stakingPool =
      isOperator ? IStakingPool(i_operatorStakingPool) : IStakingPool(i_communityStakingPool);
    uint256 stakerPrincipal = _getStakerPrincipal(msg.sender, stakingPool);
    StakerReward memory stakerReward = _calculateStakerReward({
      staker: msg.sender,
      isOperator: isOperator,
      stakerPrincipal: stakerPrincipal
    });

    uint112 newVestedBaseRewards = _calculateNewVestedBaseRewards(
      stakerReward, _getMultiplier(_getStakerStakedAtTime(msg.sender, stakingPool))
    );

    stakerReward.unvestedBaseReward -= newVestedBaseRewards;
    stakerReward.claimedBaseRewardsInPeriod += newVestedBaseRewards;

    uint256 newVestedRewards = stakerReward.vestedBaseReward + newVestedBaseRewards;
    delete stakerReward.vestedBaseReward;

    if (isOperator) {
      newVestedRewards += stakerReward.vestedDelegatedReward;
      delete stakerReward.vestedDelegatedReward;
    }

    if (newVestedRewards == 0) {
      revert NoRewardToClaim();
    }

    s_rewards[msg.sender] = stakerReward;

    // The return value is not checked since the call will revert if any balance, allowance or
    // receiver conditions fail.
    i_LINK.transfer(msg.sender, newVestedRewards);

    emit RewardClaimed(msg.sender, newVestedRewards);
    emit StakerRewardUpdated(
      msg.sender,
      0,
      0,
      stakerReward.baseRewardPerToken,
      stakerReward.operatorDelegatedRewardPerToken,
      stakerReward.claimedBaseRewardsInPeriod
    );

    return newVestedRewards;
  }

  /// @inheritdoc IRewardVault
  /// @dev precondition The caller must be a staking pool.
  function updateReward(address staker, uint256 stakerPrincipal) external onlyStakingPool {
    _updateRewardPerToken();

    StakerReward memory stakerReward = _calculateStakerReward({
      staker: staker,
      isOperator: msg.sender == address(i_operatorStakingPool),
      stakerPrincipal: stakerPrincipal
    });
    s_rewards[staker] = stakerReward;

    emit StakerRewardUpdated(
      staker,
      stakerReward.vestedBaseReward,
      stakerReward.vestedDelegatedReward,
      stakerReward.baseRewardPerToken,
      stakerReward.operatorDelegatedRewardPerToken,
      stakerReward.claimedBaseRewardsInPeriod
    );
  }

  /// @inheritdoc IRewardVault
  /// @dev This applies any final logic such as the multipliers to the staker's newly accrued and
  /// stored rewards and store the value.
  /// @dev The caller staking pool must update the total staked LINK amount of the pool AFTER
  /// calling this
  /// function.
  /// @dev precondition The caller must be a staking pool.
  function concludeRewardPeriod(
    address staker,
    uint256 oldPrincipal,
    uint256 stakedAt,
    uint256 unstakedAmount,
    bool shouldForfeit
  ) external onlyStakingPool {
    // _isOperator is not used here to save gas.  The _isOperator function
    // currently checks for 2 things.  The first that the staker is currently
    // an operator and the other is that the staker is a removed operator.  As
    // this function will only be called by a staking pool, the contract can
    // safely assume that the staker is an operator if the msg.sender is the
    // operator staking pool as upgrading a pool/reward vault means that the operator
    // staking pool will point to a new reward vault.  Additionally the contract
    // assumes that it does not need to do the second check to determine whether
    // or not an operator had been removed as it is unlikely that an operator
    // is removed after the reward vault is closed.
    bool isOperator = msg.sender == address(i_operatorStakingPool);

    _updateRewardPerToken(isOperator ? StakerType.OPERATOR : StakerType.COMMUNITY);

    StakerReward memory stakerReward = _calculateStakerReward({
      staker: staker,
      isOperator: isOperator,
      stakerPrincipal: oldPrincipal
    });

    uint112 newVestedBaseRewards =
      _calculateNewVestedBaseRewards(stakerReward, _getMultiplier(stakedAt));

    stakerReward.unvestedBaseReward -= newVestedBaseRewards;
    stakerReward.vestedBaseReward += newVestedBaseRewards;

    // claimedBaseRewardsInPeriod is reset as this function ends a
    // reward period for the staker.  This variable only tracks the amount
    // of rewards a staker has claimed within a period hence should only
    // accumulate from zero after this function is called.
    delete stakerReward.claimedBaseRewardsInPeriod;

    if (!shouldForfeit) {
      return _storeRewardAndEmitEvents(staker, stakerReward, shouldForfeit);
    }

    uint112 unvestedRewardAmount = stakerReward.unvestedBaseReward;

    // The function terminates here as a staker that has reached the maximum
    // multiplier will not have any unvested rewards hence will not forfeit
    // anything.
    if (unvestedRewardAmount == 0) {
      return _storeRewardAndEmitEvents(staker, stakerReward, shouldForfeit);
    }

    IStakingPool stakingPool =
      isOperator ? IStakingPool(i_operatorStakingPool) : IStakingPool(i_communityStakingPool);

    uint256 remainingPoolPrincipal = _getTotalPrincipal(stakingPool) - oldPrincipal;

    // This is the case when the last staker exits the pool.
    if (remainingPoolPrincipal == 0) {
      delete stakerReward.unvestedBaseReward;
      stakerReward.vestedBaseReward += unvestedRewardAmount;
      emit ForfeitedRewardDistributed(0, 0, unvestedRewardAmount, isOperator);
      return _storeRewardAndEmitEvents(staker, stakerReward, shouldForfeit);
    }

    // This handles an edge case when an operator with 0 principal remaining (due to
    // slashing) gets removed and forfeits rewards. In this scenario, the reward vault will
    // forfeit the full amount of unclaimable rewards instead of calculating
    // the proportion of the unclaimable rewards that should be forfeited.
    // There is another case when forfeitedRewardAmount rounds down to 0, which is when a staker has
    // earned too little rewards and unstakes a very small amount. In this case, we do not forfeit
    // any rewards.
    uint256 forfeitedRewardAmount = oldPrincipal == 0
      ? unvestedRewardAmount
      : unvestedRewardAmount * unstakedAmount / oldPrincipal;

    RewardBucket storage rewardBucket =
      isOperator ? s_rewardBuckets.operatorBase : s_rewardBuckets.communityBase;

    uint256 redistributedRewardPerToken = forfeitedRewardAmount.divWadDown(remainingPoolPrincipal);

    /// There is an extreme edge case where redistributedRewardPerToken may overflow
    /// because the remaining principal in a pool is an extremely small amount.
    /// This scenario is however extremely unlikely because there is a minimum
    /// staked amount for both the operator and community staking pools.
    /// Operators may be slashed so that the sum of remaining staked amounts
    /// is extremely small but this scenario is also unlikely to happen as
    /// it would mean multiple CL services going down at the same time.
    rewardBucket.vestedRewardPerToken += redistributedRewardPerToken.toUint80();

    emit ForfeitedRewardDistributed(
      forfeitedRewardAmount, redistributedRewardPerToken, 0, isOperator
    );

    // Update stakerRewardPerToken so that the staker doesn't benefit from redistributed
    // tokens
    _updateStakerRewardPerToken(stakerReward, isOperator);

    stakerReward.unvestedBaseReward -= forfeitedRewardAmount.toUint112();

    return _storeRewardAndEmitEvents(staker, stakerReward, shouldForfeit);
  }

  /// @notice Updates a staker's reward data and emits events
  /// @param staker The address of the staker to update reward data for
  /// @param stakerReward The staker's new reward data
  /// @param shouldForfeit True if the staker has forfeited some unvested
  /// rewards
  function _storeRewardAndEmitEvents(
    address staker,
    StakerReward memory stakerReward,
    bool shouldForfeit
  ) internal {
    s_rewards[staker] = stakerReward;

    emit RewardFinalized(staker, shouldForfeit);
    emit StakerRewardUpdated(
      staker,
      stakerReward.vestedBaseReward,
      stakerReward.vestedDelegatedReward,
      stakerReward.baseRewardPerToken,
      stakerReward.operatorDelegatedRewardPerToken,
      stakerReward.claimedBaseRewardsInPeriod
    );
  }

  /// @notice Calculates new vested base rewards, taking into account the multiplier
  /// and the rewards that have already been claimed.
  /// @return New vested base rewards
  function _calculateNewVestedBaseRewards(
    StakerReward memory stakerReward,
    uint256 multiplier
  ) internal pure returns (uint112) {
    return uint256(stakerReward.unvestedBaseReward + stakerReward.claimedBaseRewardsInPeriod)
      .mulWadDown(multiplier).toUint112() - stakerReward.claimedBaseRewardsInPeriod;
  }

  /// @inheritdoc IRewardVault
  /// @dev Withdraws any unvested LINK rewards to the owner's address.
  /// @dev precondition The caller must have the default admin role.
  /// @dev precondition This contract must be open.
  function close() external onlyRole(DEFAULT_ADMIN_ROLE) whenOpen {
    (, uint256 totalUnvestedRewards,,,) = _stopVestingRewardsToBuckets();
    delete s_vaultConfig.isOpen;
    // The return value is not checked since the call will revert if any balance, allowance or
    // receiver conditions fail.
    i_LINK.transfer(msg.sender, totalUnvestedRewards);
    emit VaultClosed(totalUnvestedRewards);
  }

  /// @inheritdoc IRewardVault
  function getReward(address staker) external view returns (uint256) {
    // Determine if staker is operator or community
    bool isOperator = _isOperator(staker);

    IStakingPool stakingPool =
      isOperator ? IStakingPool(i_operatorStakingPool) : IStakingPool(i_communityStakingPool);

    uint256 stakerPrincipal = _getStakerPrincipal(staker, stakingPool);

    (StakerReward memory stakerReward, uint256 forfeitedReward) =
      _getReward(staker, stakerPrincipal, isOperator);

    (,, uint256 reclaimableReward) = _calculateForfeitedRewardDistribution(
      forfeitedReward, _getTotalPrincipal(stakingPool) - stakerPrincipal
    );

    return stakerReward.vestedBaseReward + stakerReward.vestedDelegatedReward + reclaimableReward;
  }

  /// @inheritdoc IRewardVault
  function isOpen() external view returns (bool) {
    return s_vaultConfig.isOpen;
  }

  /// @inheritdoc IRewardVault
  function hasRewardDurationEnded(address stakingPool) external view returns (bool) {
    if (stakingPool == address(i_operatorStakingPool)) {
      return s_rewardBuckets.operatorBase.rewardDurationEndsAt <= block.timestamp
        && s_rewardBuckets.operatorDelegated.rewardDurationEndsAt <= block.timestamp;
    }
    if (stakingPool == address(i_communityStakingPool)) {
      return s_rewardBuckets.communityBase.rewardDurationEndsAt <= block.timestamp;
    }

    revert InvalidPool();
  }

  /// @inheritdoc IRewardVault
  function hasRewardAdded() external view returns (bool) {
    return s_rewardBuckets.operatorBase.emissionRate != 0
      || s_rewardBuckets.communityBase.emissionRate != 0
      || s_rewardBuckets.operatorDelegated.emissionRate != 0;
  }

  /// @inheritdoc IRewardVault
  function getStoredReward(address staker) external view returns (StakerReward memory) {
    return s_rewards[staker];
  }

  /// @notice Returns the reward buckets within this vault
  /// @return The reward buckets
  function getRewardBuckets() external view returns (RewardBuckets memory) {
    return s_rewardBuckets;
  }

  /// @notice Returns the timestamp of the last reward per token update
  /// @return uint256 communityRewardUpdateTimestamp The timestamp of the last update
  /// @return uint256 operatorRewardUpdateTimestamp The timestamp of the last update
  function getRewardPerTokenUpdatedAt() external view returns (uint256, uint256) {
    return _getRewardUpdateTimestamps(s_packedRewardUpdateTimestamps);
  }

  /// @notice Returns the multiplier ramp up time
  /// @return uint256 The multiplier ramp up time
  function getMultiplierDuration() external view returns (uint256) {
    return i_multiplierDuration;
  }

  /// @notice Returns the ramp up multiplier of the staker
  /// @dev Multipliers are in the range of 0 and 1, so we multiply them by 1e18 (WAD) to preserve
  /// the decimals.
  /// @param staker The address of the staker
  /// @return uint256 The staker's multiplier
  function getMultiplier(address staker) external view returns (uint256) {
    IStakingPool stakingPool = _isOperator(staker)
      ? IStakingPool(i_operatorStakingPool)
      : IStakingPool(i_communityStakingPool);

    return _getMultiplier(_getStakerStakedAtTime(staker, stakingPool));
  }

  /// @notice Calculates and returns the latest reward info of the staker
  /// @param staker The staker address
  /// @return StakerReward The staker's reward info
  /// @return uint256 The staker's forfeited reward in juels
  function calculateLatestStakerReward(address staker)
    external
    view
    returns (StakerReward memory, uint256)
  {
    // Determine if staker is operator or community
    bool isOperator = _isOperator(staker);

    IStakingPool stakingPool =
      isOperator ? IStakingPool(i_operatorStakingPool) : IStakingPool(i_communityStakingPool);

    uint256 stakerPrincipal = _getStakerPrincipal(staker, stakingPool);
    return _getReward(staker, stakerPrincipal, isOperator);
  }

  /// @notice Returns the final checkpoint data
  /// @return VestingCheckpointData The final checkpoint
  function getFinalVestingCheckpointData() external view returns (VestingCheckpointData memory) {
    return s_finalVestingCheckpointData;
  }

  /// @notice Returns the unvested rewards
  /// @return unvestedCommunityBaseRewards The unvested community base rewards
  /// @return unvestedOperatorBaseRewards The unvested operator base rewards
  /// @return unvestedOperatorDelegatedRewards The unvested operator delegated rewards
  function getUnvestedRewards() external view returns (uint256, uint256, uint256) {
    uint256 unvestedCommunityBaseRewards = _getUnvestedRewards(s_rewardBuckets.communityBase);
    uint256 unvestedOperatorBaseRewards = _getUnvestedRewards(s_rewardBuckets.operatorBase);
    uint256 unvestedOperatorDelegatedRewards =
      _getUnvestedRewards(s_rewardBuckets.operatorDelegated);
    return
      (unvestedCommunityBaseRewards, unvestedOperatorBaseRewards, unvestedOperatorDelegatedRewards);
  }

  /// @inheritdoc IRewardVault
  function isPaused() external view returns (bool) {
    return paused();
  }

  /// @inheritdoc IRewardVault
  function getStakingPools() external view override returns (address[] memory) {
    address[] memory stakingPools = new address[](2);
    stakingPools[0] = address(i_operatorStakingPool);
    stakingPools[1] = address(i_communityStakingPool);
    return stakingPools;
  }

  // =========
  // Helpers
  // =========

  /// @notice Stops rewards in all buckets from vesting and close the vault.
  /// @dev This will also checkpoint the staking pools
  /// @return uint256 The total aggregate reward rate from all three buckets
  /// @return uint256 The total amount of available rewards in juels
  /// @return uint256 The amount of available operator base rewards in juels
  /// @return uint256 The amount of available community base rewards in juels
  /// @return uint256 The amount of available operator delegated rewards in juels
  function _stopVestingRewardsToBuckets()
    private
    returns (uint256, uint256, uint256, uint256, uint256)
  {
    _updateRewardPerToken();

    uint256 unvestedOperatorBaseRewards = _stopVestingBucketRewards(s_rewardBuckets.operatorBase);
    uint256 unvestedCommunityBaseRewards = _stopVestingBucketRewards(s_rewardBuckets.communityBase);
    uint256 unvestedOperatorDelegatedRewards =
      _stopVestingBucketRewards(s_rewardBuckets.operatorDelegated);
    uint256 totalUnvestedRewards =
      unvestedOperatorBaseRewards + unvestedCommunityBaseRewards + unvestedOperatorDelegatedRewards;

    _checkpointStakingPools();

    return (
      s_rewardBuckets.operatorBase.emissionRate + s_rewardBuckets.communityBase.emissionRate
        + s_rewardBuckets.operatorDelegated.emissionRate,
      totalUnvestedRewards,
      unvestedOperatorBaseRewards,
      unvestedCommunityBaseRewards,
      unvestedOperatorDelegatedRewards
    );
  }

  /// @notice Returns the total staked LINK amount staked in a staking pool.  This will
  /// return the staking pool's latest total staked LINK amount if the vault has not been
  /// closed and the pool's total staked LINK amount at the time the vault was
  /// closed if the vault has already been closed.
  /// @param stakingPool The staking pool to query the total staked LINK amount for
  /// @return uint256 The total staked LINK amount staked in the staking pool
  function _getTotalPrincipal(IStakingPool stakingPool) private view returns (uint256) {
    return s_vaultConfig.isOpen
      ? stakingPool.getTotalPrincipal()
      : _getFinalTotalPoolPrincipal(stakingPool);
  }

  /// @notice Returns the staker's staked LINK amount in a staking pool.  This will
  /// return the staker's latest staked LINK amount if the vault has not been
  /// closed and the staker's staked LINK amount at the time the vault was
  /// closed if the vault has already been closed.
  /// @param staker The staker to query the total staked LINK amount for
  /// @param stakingPool The staking pool to query the total staked LINK amount for
  /// @return uint256 The staker's staked LINK amount in the staking pool in juels
  function _getStakerPrincipal(
    address staker,
    IStakingPool stakingPool
  ) private view returns (uint256) {
    return s_vaultConfig.isOpen
      ? stakingPool.getStakerPrincipal(staker)
      : stakingPool.getStakerPrincipalAt(staker, s_finalVestingCheckpointData.finalBlockNumber);
  }

  /// @notice Helper function to get a staker's current multiplier
  /// @param stakedAt The time the staker last staked at
  /// @return uint256 The staker's multiplier
  function _getMultiplier(uint256 stakedAt) private view returns (uint256) {
    if (stakedAt == 0) return 0;

    if (!s_vaultConfig.isOpen) return MAX_MULTIPLIER;

    uint256 multiplierDuration = i_multiplierDuration;
    if (multiplierDuration == 0) return MAX_MULTIPLIER;

    return Math.min(
      FixedPointMathLib.divWadDown(block.timestamp - stakedAt, multiplierDuration), MAX_MULTIPLIER
    );
  }

  /// @notice Returns the staker's staked at time in a staking pool.  This will
  /// return the staker's latest staked at time if the vault has not been
  /// closed and the staker's staked at time at the time the vault was
  /// closed if the vault has already been closed.
  /// @param staker The staker to query the staked at time for
  /// @param stakingPool The staking pool to query the staked at time for
  /// @return uint256 The staker's average staked at time in the staking pool
  function _getStakerStakedAtTime(
    address staker,
    IStakingPool stakingPool
  ) private view returns (uint256) {
    return s_vaultConfig.isOpen
      ? stakingPool.getStakerStakedAtTime(staker)
      : stakingPool.getStakerStakedAtTimeAt(staker, s_finalVestingCheckpointData.finalBlockNumber);
  }

  /// @notice Return the staking pool's total staked LINK amount at the time the vault was
  /// closed
  /// @param stakingPool The staking pool to query the total staked LINK amount for
  /// @return uint256 The pool's total staked LINK amount at the time the vault was
  /// closed
  function _getFinalTotalPoolPrincipal(IStakingPool stakingPool) private view returns (uint256) {
    return address(stakingPool) == address(i_operatorStakingPool)
      ? s_finalVestingCheckpointData.operatorPoolTotalPrincipal
      : s_finalVestingCheckpointData.communityPoolTotalPrincipal;
  }

  /// @notice Records the final block number and the total staked LINK amounts
  /// in the operator and community staking pools
  function _checkpointStakingPools() private {
    s_finalVestingCheckpointData.operatorPoolTotalPrincipal =
      i_operatorStakingPool.getTotalPrincipal();
    s_finalVestingCheckpointData.communityPoolTotalPrincipal =
      i_communityStakingPool.getTotalPrincipal();
    s_finalVestingCheckpointData.finalBlockNumber = block.number;
  }

  /// @notice Stops rewards in a bucket from vesting
  /// @param bucket The bucket to stop vesting rewards for
  /// @return uint256 The amount of unvested rewards in juels
  function _stopVestingBucketRewards(RewardBucket storage bucket) private returns (uint256) {
    uint256 unvestedRewards = _getUnvestedRewards(bucket);
    bucket.rewardDurationEndsAt = block.timestamp.toUint80();
    return unvestedRewards;
  }

  /// @notice Updates the reward buckets
  /// @param pool The staking pool address
  /// @param amount The reward amount
  /// @param emissionRate The target aggregate reward rate (Juels/second)
  function _updateRewardBuckets(address pool, uint256 amount, uint256 emissionRate) private {
    // split the reward and aggregate reward rate for the different reward buckets
    BucketRewardEmissionSplit memory emissionSplitData = _getBucketRewardAndEmissionRateSplit({
      pool: pool,
      amount: amount,
      emissionRate: emissionRate,
      isDelegated: s_vaultConfig.delegationRate != 0
    });

    // If the aggregate reward rate is zero, we don't update the reward bucket
    // This is because we do not allow a zero aggregate reward rate
    // A zero aggregate reward rate means no rewards have been added
    if (emissionSplitData.communityRate != 0) {
      _updateRewardBucket({
        bucket: s_rewardBuckets.communityBase,
        amount: emissionSplitData.communityReward,
        emissionRate: emissionSplitData.communityRate
      });
    }
    if (emissionSplitData.operatorRate != 0) {
      _updateRewardBucket({
        bucket: s_rewardBuckets.operatorBase,
        amount: emissionSplitData.operatorReward,
        emissionRate: emissionSplitData.operatorRate
      });
    }
    if (emissionSplitData.delegatedRate != 0) {
      _updateRewardBucket({
        bucket: s_rewardBuckets.operatorDelegated,
        amount: emissionSplitData.operatorDelegatedReward,
        emissionRate: emissionSplitData.delegatedRate
      });
    }
  }

  /// @notice Updates the reward bucket
  /// @param bucket The reward bucket
  /// @param amount The reward amount
  /// @param emissionRate The target aggregate reward rate (token/second)
  function _updateRewardBucket(
    RewardBucket storage bucket,
    uint256 amount,
    uint256 emissionRate
  ) private {
    // calculate the remaining rewards
    uint256 remainingRewards = _getUnvestedRewards(bucket);

    // if the amount of rewards is less than what becomes available per second, we revert
    if (amount + remainingRewards < emissionRate) revert RewardDurationTooShort();

    _updateRewardDurationEndsAt({
      bucket: bucket,
      rewardAmount: amount + remainingRewards,
      emissionRate: emissionRate
    });
    bucket.emissionRate = emissionRate.toUint80();
  }

  /// @notice Updates the reward duration end time of the bucket
  /// @param bucket The reward bucket
  /// @param rewardAmount The reward amount
  /// @param emissionRate The aggregate reward rate
  function _updateRewardDurationEndsAt(
    RewardBucket storage bucket,
    uint256 rewardAmount,
    uint256 emissionRate
  ) private {
    if (emissionRate == 0) return;
    bucket.rewardDurationEndsAt = (block.timestamp + (rewardAmount / emissionRate)).toUint80();
  }

  /// @notice Splits the reward and aggregate reward rates between the different reward buckets
  /// @dev If the pool is not targeted, the returned reward and aggregate reward rate will be zero
  /// @param pool The staking pool address (or zero address if the reward is split between all
  /// pools)
  /// @param amount The reward amount
  /// @param emissionRate The aggregate reward rate (juels/second)
  /// @param isDelegated Whether the reward is delegated or not
  /// @return BucketRewardEmissionSplit The rewards and aggregate reward rates after
  /// distributing the reward amount to the buckets
  function _getBucketRewardAndEmissionRateSplit(
    address pool,
    uint256 amount,
    uint256 emissionRate,
    bool isDelegated
  ) private view returns (BucketRewardEmissionSplit memory) {
    // when splitting reward and rate, a pool's share is 0 if it is not targeted by the pool
    // address,
    // otherwise it is the pool's max size
    // a pool's share is used to split rewards and aggregate reward rates proportionally
    uint256 communityPoolShare =
      pool != address(i_operatorStakingPool) ? i_communityStakingPool.getMaxPoolSize() : 0;
    uint256 operatorPoolShare =
      pool != address(i_communityStakingPool) ? i_operatorStakingPool.getMaxPoolSize() : 0;
    uint256 totalPoolShare = communityPoolShare + operatorPoolShare;

    uint256 operatorReward;
    uint256 communityReward;
    uint256 operatorRate;
    uint256 communityRate;
    if (pool == address(i_operatorStakingPool)) {
      operatorReward = amount;
      operatorRate = emissionRate;
    } else if (pool == address(i_communityStakingPool)) {
      communityReward = amount;
      communityRate = emissionRate;
    } else {
      // prevent a possible rounding to zero error by validating inputs
      _checkForRoundingToZeroRewardAmountSplit({
        rewardAmount: amount,
        operatorPoolShare: operatorPoolShare,
        totalPoolShare: totalPoolShare
      });
      _checkForRoundingToZeroEmissionRateSplit({
        emissionRate: emissionRate,
        operatorPoolShare: operatorPoolShare,
        totalPoolShare: totalPoolShare
      });

      operatorReward = amount * operatorPoolShare / totalPoolShare;
      operatorRate = emissionRate * operatorPoolShare / totalPoolShare;

      communityReward = amount - operatorReward;
      communityRate = emissionRate - operatorRate;
    }

    uint256 operatorDelegatedReward;
    uint256 delegatedRate;
    // if there is no delegation or the community pool is not targeted, the delegated reward and
    // rate is zero
    if (isDelegated && communityPoolShare != 0) {
      // calculate the delegated pool reward and remove from community reward
      operatorDelegatedReward =
        communityReward * s_vaultConfig.delegationRate / DELEGATION_BASIS_POINTS_DENOMINATOR;
      if (communityReward > 0 && operatorDelegatedReward == 0) revert InvalidRewardAmount();
      communityReward -= operatorDelegatedReward;

      // calculate the delegated pool aggregate reward rate and remove from community rate
      delegatedRate =
        communityRate * s_vaultConfig.delegationRate / DELEGATION_BASIS_POINTS_DENOMINATOR;
      if (communityRate > 0 && delegatedRate == 0) revert InvalidEmissionRate();
      communityRate -= delegatedRate;
    }

    return (
      BucketRewardEmissionSplit({
        communityReward: communityReward,
        operatorReward: operatorReward,
        operatorDelegatedReward: operatorDelegatedReward,
        communityRate: communityRate,
        operatorRate: operatorRate,
        delegatedRate: delegatedRate
      })
    );
  }

  /// @notice Validates the added reward amount after splitting to avoid a rounding error when
  /// dividing
  /// @param rewardAmount The reward amount
  /// @param operatorPoolShare The size of the operator staking pool to take into account
  /// @param totalPoolShare The total size of the pools to take into account
  function _checkForRoundingToZeroRewardAmountSplit(
    uint256 rewardAmount,
    uint256 operatorPoolShare,
    uint256 totalPoolShare
  ) private pure {
    if (
      rewardAmount != 0
        && ((operatorPoolShare != 0 && rewardAmount * operatorPoolShare < totalPoolShare))
    ) {
      revert InvalidRewardAmount();
    }
  }

  /// @notice Validates the aggregate reward rate after splitting to avoid a rounding error when
  /// dividing
  /// @param emissionRate The aggregate reward rate
  /// @param operatorPoolShare The size of the operator staking pool to take into account
  /// @param totalPoolShare The total size of the pools to take into account
  function _checkForRoundingToZeroEmissionRateSplit(
    uint256 emissionRate,
    uint256 operatorPoolShare,
    uint256 totalPoolShare
  ) private pure {
    if ((operatorPoolShare != 0 && emissionRate * operatorPoolShare < totalPoolShare)) {
      revert InvalidEmissionRate();
    }
  }

  /// @notice Private util function to unpack and return reward update timestamps.
  /// @return uint256 communityRewardUpdateTimestamp
  /// @return uint256 operatorRewardUpdateTimestamp
  function _getRewardUpdateTimestamps(uint256 packedRewardUpdateTimestamps)
    private
    pure
    returns (uint256, uint256)
  {
    uint256 communityRewardUpdateTimestamp = packedRewardUpdateTimestamps / 1e18;
    uint256 operatorRewardUpdateTimestamp = packedRewardUpdateTimestamps % 1e18;

    return (communityRewardUpdateTimestamp, operatorRewardUpdateTimestamp);
  }

  /// @notice Private util function to pack and set reward update timestamps.
  function _setRewardUpdateTimestamps(
    uint256 communityRewardUpdateTimestamp,
    uint256 operatorRewardUpdateTimestamp
  ) private {
    s_packedRewardUpdateTimestamps =
      communityRewardUpdateTimestamp * 1e18 + operatorRewardUpdateTimestamp;
  }

  /// @notice Private util function for updateRewardPerToken
  function _updateRewardPerToken() private {
    (uint256 communityRewardUpdateTimestamp, uint256 operatorRewardUpdateTimestamp) =
      _getRewardUpdateTimestamps(s_packedRewardUpdateTimestamps);

    if (
      communityRewardUpdateTimestamp == block.timestamp
        && operatorRewardUpdateTimestamp == block.timestamp
    ) {
      // if the pools were previously updated in the same block there is no recalculation of reward
      return;
    }

    (
      uint256 communityRewardPerToken,
      uint256 operatorRewardPerToken,
      uint256 operatorDelegatedRewardPerToken
    ) = _calculatePoolsRewardPerToken();

    s_rewardBuckets.communityBase.vestedRewardPerToken = communityRewardPerToken.toUint80();
    s_rewardBuckets.operatorBase.vestedRewardPerToken = operatorRewardPerToken.toUint80();
    s_rewardBuckets.operatorDelegated.vestedRewardPerToken =
      operatorDelegatedRewardPerToken.toUint80();

    _setRewardUpdateTimestamps(block.timestamp, block.timestamp);
    emit CommunityPoolRewardUpdated(communityRewardPerToken);
    emit OperatorPoolRewardUpdated(operatorRewardPerToken, operatorDelegatedRewardPerToken);
  }

  /// @notice Private util function for updateRewardPerToken
  /// @param stakerType The staker type to update the reward for.
  function _updateRewardPerToken(StakerType stakerType) private {
    (uint256 communityRewardUpdateTimestamp, uint256 operatorRewardUpdateTimestamp) =
      _getRewardUpdateTimestamps(s_packedRewardUpdateTimestamps);

    if (stakerType == StakerType.COMMUNITY) {
      if (communityRewardUpdateTimestamp == block.timestamp) {
        return;
      }

      s_rewardBuckets.communityBase.vestedRewardPerToken = _calculateVestedRewardPerToken(
        s_rewardBuckets.communityBase,
        _getTotalPrincipal(i_communityStakingPool),
        communityRewardUpdateTimestamp
      ).toUint80();

      _setRewardUpdateTimestamps(block.timestamp, operatorRewardUpdateTimestamp);
      emit CommunityPoolRewardUpdated(s_rewardBuckets.communityBase.vestedRewardPerToken);
    } else if (stakerType == StakerType.OPERATOR) {
      if (operatorRewardUpdateTimestamp == block.timestamp) {
        return;
      }

      uint256 operatorTotalPrincipal = _getTotalPrincipal(i_operatorStakingPool);
      s_rewardBuckets.operatorBase.vestedRewardPerToken = _calculateVestedRewardPerToken(
        s_rewardBuckets.operatorBase, operatorTotalPrincipal, operatorRewardUpdateTimestamp
      ).toUint80();
      s_rewardBuckets.operatorDelegated.vestedRewardPerToken = _calculateVestedRewardPerToken(
        s_rewardBuckets.operatorDelegated, operatorTotalPrincipal, operatorRewardUpdateTimestamp
      ).toUint80();

      _setRewardUpdateTimestamps(communityRewardUpdateTimestamp, block.timestamp);
      emit OperatorPoolRewardUpdated(
        s_rewardBuckets.operatorBase.vestedRewardPerToken,
        s_rewardBuckets.operatorDelegated.vestedRewardPerToken
      );
    }
  }

  /// @notice Util function for calculating the current reward per token for the pools
  /// @return uint256 The community reward per token
  /// @return uint256 The operator reward per token
  /// @return uint256 The operator delegated reward per token
  function _calculatePoolsRewardPerToken() private view returns (uint256, uint256, uint256) {
    uint256 communityTotalPrincipal = _getTotalPrincipal(i_communityStakingPool);
    uint256 operatorTotalPrincipal = _getTotalPrincipal(i_operatorStakingPool);
    (uint256 communityRewardUpdateTimestamp, uint256 operatorRewardUpdateTimestamp) =
      _getRewardUpdateTimestamps(s_packedRewardUpdateTimestamps);

    return (
      _calculateVestedRewardPerToken(
        s_rewardBuckets.communityBase, communityTotalPrincipal, communityRewardUpdateTimestamp
        ),
      _calculateVestedRewardPerToken(
        s_rewardBuckets.operatorBase, operatorTotalPrincipal, operatorRewardUpdateTimestamp
        ),
      _calculateVestedRewardPerToken(
        s_rewardBuckets.operatorDelegated, operatorTotalPrincipal, operatorRewardUpdateTimestamp
        )
    );
  }

  /// @notice Calculate a bucket’s available rewards earned per token
  /// @param rewardBucket The reward bucket to calculate the vestedRewardPerToken for
  /// @param totalPrincipal The total staked LINK amount staked in a pool associated with the reward
  /// bucket
  /// @return uint256 The available rewards earned per token
  function _calculateVestedRewardPerToken(
    RewardBucket memory rewardBucket,
    uint256 totalPrincipal,
    uint256 lastUpdateTimestamp
  ) private view returns (uint256) {
    if (totalPrincipal == 0) return rewardBucket.vestedRewardPerToken;

    uint256 latestRewardEmittedAt = Math.min(rewardBucket.rewardDurationEndsAt, block.timestamp);

    if (latestRewardEmittedAt <= lastUpdateTimestamp) {
      return rewardBucket.vestedRewardPerToken;
    }

    uint256 elapsedTime = latestRewardEmittedAt - lastUpdateTimestamp;

    return rewardBucket.vestedRewardPerToken
      + (elapsedTime * rewardBucket.emissionRate).divWadDown(totalPrincipal);
  }

  /// @notice Calculates a stakers earned base reward
  /// @param stakerReward The staker's reward info
  /// @param stakerPrincipal The staker's staked LINK amount
  /// @param baseRewardPerToken The base reward per token of the staking pool
  /// @return uint256 The earned base reward
  function _calculateEarnedBaseReward(
    StakerReward memory stakerReward,
    uint256 stakerPrincipal,
    uint256 baseRewardPerToken
  ) private pure returns (uint256) {
    uint256 earnedBaseReward = _calculateAccruedReward({
      principal: stakerPrincipal,
      rewardPerToken: stakerReward.baseRewardPerToken,
      vestedRewardPerToken: baseRewardPerToken
    });

    return earnedBaseReward;
  }

  /// @notice Calculates an operator's earned delegated reward
  /// @param stakerReward The staker's reward info
  /// @param stakerPrincipal The staker's staked LINK amount
  /// @param operatorDelegatedRewardPerToken The operator delegated reward per token
  /// @return uint256 The earned delegated reward
  function _calculateEarnedDelegatedReward(
    StakerReward memory stakerReward,
    uint256 stakerPrincipal,
    uint256 operatorDelegatedRewardPerToken
  ) private pure returns (uint256) {
    uint256 earnedDelegatedReward = _calculateAccruedReward({
      principal: stakerPrincipal,
      rewardPerToken: stakerReward.operatorDelegatedRewardPerToken,
      vestedRewardPerToken: operatorDelegatedRewardPerToken
    });

    return earnedDelegatedReward;
  }

  /// @notice Calculates the newly accrued reward of a staker since the last time the staker's
  /// reward was updated
  /// @param principal The staker's staked LINK amount
  /// @param rewardPerToken The base or delegated reward per token of the staker
  /// @param vestedRewardPerToken The available reward per token of the staking pool
  /// @return uint256 The accrued reward amount
  function _calculateAccruedReward(
    uint256 principal,
    uint256 rewardPerToken,
    uint256 vestedRewardPerToken
  ) private pure returns (uint256) {
    return principal.mulWadDown(vestedRewardPerToken - rewardPerToken);
  }

  /// @notice Calculates and updates a staker's rewards
  /// @param staker The staker's address
  /// @param isOperator True if the staker is an operator, false otherwise
  /// @param stakerPrincipal The staker's staked LINK amount
  /// @dev Staker rewards are forfeited when a staker unstakes before they
  /// have reached their maximum ramp up period multiplier.  Additionally an
  /// operator will also forfeit any unclaimed rewards if they are removed
  /// before they reach the maximum ramp up period multiplier.
  /// @return StakerReward The staker's updated reward info
  function _calculateStakerReward(
    address staker,
    bool isOperator,
    uint256 stakerPrincipal
  ) private view returns (StakerReward memory) {
    StakerReward memory stakerReward = s_rewards[staker];

    if (stakerReward.stakerType != StakerType.NOT_STAKED) {
      // do nothing
    } else {
      stakerReward.stakerType = isOperator ? StakerType.OPERATOR : StakerType.COMMUNITY;
    }

    // Calculate earned base rewards
    stakerReward.unvestedBaseReward += _calculateEarnedBaseReward({
      stakerReward: stakerReward,
      stakerPrincipal: stakerPrincipal,
      baseRewardPerToken: isOperator
        ? s_rewardBuckets.operatorBase.vestedRewardPerToken
        : s_rewardBuckets.communityBase.vestedRewardPerToken
    }).toUint112();

    // Calculate earned delegated rewards if the staker is an operator
    if (isOperator) {
      // Multipliers do not apply to the delegation reward, i.e. always treat them as
      // multiplied by the max multiplier, which is 1.
      stakerReward.vestedDelegatedReward += _calculateEarnedDelegatedReward({
        stakerReward: stakerReward,
        stakerPrincipal: stakerPrincipal,
        operatorDelegatedRewardPerToken: s_rewardBuckets.operatorDelegated.vestedRewardPerToken
      }).toUint112();
    }

    // Update the staker's earned reward per token
    _updateStakerRewardPerToken(stakerReward, isOperator);

    return stakerReward;
  }

  /// @notice Helper function for calculating the available reward per token and the reclaimable
  /// reward
  /// @dev If the pool the staker is in is empty and we can't calculate the reward per token, we
  /// allow the staker to reclaim the forfeited reward.
  /// @param forfeitedReward The amount of forfeited reward
  /// @param amountOfRecipientTokens The amount of tokens that the forfeited rewards should be
  /// shared to
  /// @return uint256 The amount of shared forfeited reward
  /// @return uint256 The shared forfeited reward per token
  /// @return uint256 The amount of reclaimable reward
  function _calculateForfeitedRewardDistribution(
    uint256 forfeitedReward,
    uint256 amountOfRecipientTokens
  ) private pure returns (uint256, uint256, uint256) {
    if (forfeitedReward == 0) return (0, 0, 0);

    uint256 vestedReward;
    uint256 vestedRewardPerToken;
    uint256 reclaimableReward;

    if (amountOfRecipientTokens != 0) {
      vestedReward = forfeitedReward;
      vestedRewardPerToken = forfeitedReward.divWadDown(amountOfRecipientTokens);
    } else {
      reclaimableReward = forfeitedReward;
    }

    return (vestedReward, vestedRewardPerToken, reclaimableReward);
  }

  /// @notice Updates the staker's base and/or delegated reward per token values
  /// @dev This function is called when staking, unstaking, claiming rewards, finalizing rewards for
  /// removed operators, and slashing operators.
  /// @param stakerReward The staker reward struct
  /// @param isOperator Whether the staker is an operator or not
  function _updateStakerRewardPerToken(
    StakerReward memory stakerReward,
    bool isOperator
  ) private view {
    if (isOperator) {
      stakerReward.baseRewardPerToken = s_rewardBuckets.operatorBase.vestedRewardPerToken;
      stakerReward.operatorDelegatedRewardPerToken =
        s_rewardBuckets.operatorDelegated.vestedRewardPerToken;
    } else {
      stakerReward.baseRewardPerToken = s_rewardBuckets.communityBase.vestedRewardPerToken;
    }
  }

  /// @notice Calculates a staker's earned rewards
  /// @param staker The staker
  /// @return The staker reward info
  /// @return The forfeited reward
  function _getReward(
    address staker,
    uint256 stakerPrincipal,
    bool isOperator
  ) private view returns (StakerReward memory, uint256) {
    StakerReward memory stakerReward = s_rewards[staker];

    // Calculate latest reward per token for the pools
    (
      uint256 communityRewardPerToken,
      uint256 operatorRewardPerToken,
      uint256 operatorDelegatedRewardPerToken
    ) = _calculatePoolsRewardPerToken();

    // Calculate earned base rewards
    stakerReward.unvestedBaseReward += _calculateEarnedBaseReward({
      stakerReward: stakerReward,
      stakerPrincipal: stakerPrincipal,
      baseRewardPerToken: isOperator ? operatorRewardPerToken : communityRewardPerToken
    }).toUint112();

    // If operator Calculate earned delegated rewards
    if (isOperator) {
      // Multipliers do not apply to the delegation reward, i.e. always treat them as
      // multiplied by the max multiplier, which is 1.
      stakerReward.vestedDelegatedReward += _calculateEarnedDelegatedReward({
        stakerReward: stakerReward,
        stakerPrincipal: stakerPrincipal,
        operatorDelegatedRewardPerToken: operatorDelegatedRewardPerToken
      }).toUint112();
    }

    uint112 newVestedBaseRewards = _calculateNewVestedBaseRewards({
      stakerReward: stakerReward,
      multiplier: _getMultiplier(
        _getStakerStakedAtTime(
          staker,
          isOperator ? IStakingPool(i_operatorStakingPool) : IStakingPool(i_communityStakingPool)
        )
        )
    });

    stakerReward.vestedBaseReward += newVestedBaseRewards;
    uint256 forfeitedRewards = stakerReward.unvestedBaseReward - newVestedBaseRewards;

    // Forfeit rewards
    delete stakerReward.unvestedBaseReward;

    return (stakerReward, forfeitedRewards);
  }

  /// @notice Calculates the amount of unvested rewards in a reward bucket
  /// @param bucket The bucket to calculate unvested rewards for
  /// @return uint256 The amount of unvested rewards in the bucket
  function _getUnvestedRewards(RewardBucket memory bucket) private view returns (uint256) {
    return bucket.rewardDurationEndsAt <= block.timestamp
      ? 0
      : bucket.emissionRate * (bucket.rewardDurationEndsAt - block.timestamp);
  }

  /// @notice Returns whether or not an address is currently an operator or
  /// is a removed operator
  /// @param staker The staker address
  /// @return bool True if the staker is either an operator or a removed operator.
  function _isOperator(address staker) private view returns (bool) {
    return i_operatorStakingPool.isOperator(staker) || i_operatorStakingPool.isRemoved(staker);
  }

  // =========
  // Modifiers
  // =========

  /// @dev Reverts if the msg.sender doesn't have the rewarder role.
  modifier onlyRewarder() {
    if (!hasRole(REWARDER_ROLE, msg.sender)) {
      revert AccessForbidden();
    }
    _;
  }

  /// @dev Reverts if the msg.sender is not a valid staking pool
  modifier onlyStakingPool() {
    if (
      msg.sender != address(i_operatorStakingPool) && msg.sender != address(i_communityStakingPool)
    ) {
      revert AccessForbidden();
    }
    _;
  }

  /// @dev Reverts if the reward vault has been closed
  modifier whenOpen() {
    if (!s_vaultConfig.isOpen) revert VaultAlreadyClosed();
    _;
  }

  // =======================
  // TypeAndVersionInterface
  // =======================

  /// @inheritdoc TypeAndVersionInterface
  function typeAndVersion() external pure virtual override returns (string memory) {
    return "RewardVault 1.0.0";
  }
}
