// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

/// @author koloz, charlescrain
/// @title IRarityPool
/// @notice The Rare Staking Pool ERC20 (Rarity Pool) interface containing all functions, events, etc.
interface IRarityPool is IERC20Upgradeable {
  /*//////////////////////////////////////////////////////////////////////////
                              Events
  //////////////////////////////////////////////////////////////////////////*/

  event RewardClaimed(
    address indexed _msgSender,
    address indexed _claimer,
    uint256 _amountToStaker
  );

  event Stake(
    address indexed _staker,
    uint256 _amountStaking,
    uint256 _totalAmountStaked,
    uint256 _amountSRareReceived
  );

  event Unstake(
    address indexed _staker,
    uint256 _amountUnstaking,
    uint256 _totalAmountStaked,
    uint256 _amountRareBurned,
    uint256 _amountSRareSold
  );

  event StakingSnapshot(uint256 _lastSnapshotTimestamp, uint256 _currentSnapshotTimestamp, uint256 _round);

  event AddRewards(
    address indexed _donor,
    uint256 indexed _round,
    uint256 _amount,
    uint256 _totalAmountAdded,
    uint256 _newRoundRewardAmount
  );

  /*//////////////////////////////////////////////////////////////////////////
                            Custom Errors
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Error emitted when user doesnt meet the criteria for call.
  error Unauthorized();

  /// @notice Error emitted via {claimRewardsForRounds} if sender has already claimed their reward one of the supplied rounds.
  error RewardAlreadyClaimed();

  /// @notice Error emitted via {claimRewardsForRounds} if too many rounds are supplied.
  error ClaimingTooManyRounds();

  /// @notice Error emitted via {claimRewardsForRounds} if claiming current round.
  error CannotClaimCurrentRound();

  /// @notice Error emitted via {claimRewardsForRounds} if claiming no rounds.
  error ClaimingZeroRounds();

  /// @notice Error emitted via {unstake} when unstaking more synthetic tokens than is in their balance.
  error InsufficientSyntheticRare();

  /// @notice Error emitted via {unstake} when the sale return proves greater than the amount staked. This should be impossible.
  error InsufficientStakedRare();

  /// @notice Error emitted via {addRewards} if adding 0 rewards.
  error CannotAddZeroRewards();

  /// @notice Emitted when Zero address provided where it is not allowed.
  error ZeroAddressUnsupported();

  /*//////////////////////////////////////////////////////////////////////////
                              Initializer
  //////////////////////////////////////////////////////////////////////////*/
  function initialize(
    address _userStakedTo,
    address _stakingRegistry,
    address _creator
  ) external;

  /*//////////////////////////////////////////////////////////////////////////
                          External Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Allocates rewards for the current round with the given amount.
  /// @param _donor Address of the account donating the $RARE.
  /// @param _amount Amount of $RARE being staked.
  function addRewards(address _donor, uint256 _amount) external;

  /// @notice Snapshots the rewards for the current round. Anyone can call this.
  function takeSnapshot() external;

  /// @notice Stake $RARE tokens to the target associated with the contract and receive synthetic tokens in return.
  /// @param _amount Amount of $RARE being staked.
  function stake(uint120 _amount) external;

  /// @notice Unstake by returning synthetic tokens and receiving previously staked $RARE in return.
  /// @param _amount Amount of synthetic tokens to unstake.
  function unstake(uint256 _amount) external;

  /// @notice Claim rewards for the _user for the number of rounds supplied since last claim. Rewards are proportional to the synthetic tokens held during the snapshot associated with each round. Throws if user has already claimed the latest round. Throws if current round is being claimed.
  /// @param _user Address of user to claim on behalf of.
  /// @param _numRounds uint256 number of rounds to claim since last claim.
  function claimRewards(address _user, uint8 _numRounds) external;

  /*//////////////////////////////////////////////////////////////////////////
                          External Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Query total amount of $RARE a user has staked on this contract.
  /// @param _user Address of staker.
  /// @return uint256 Amount of $RARE staked.
  function getAmountStakedByUser(address _user) external view returns (uint256);

  /// @notice Query current round. The current round is accumulating rewards.
  /// @return uint256 Claim round id.
  function getCurrentRound() external view returns (uint256);

  /// @notice Name of the synthetic asset.
  /// @return Name of the synthetic asset.
  function name() external view returns (string memory);

  /// @notice Symbol of the synthetic asset.
  /// @return Symbol of the synthetic asset.
  function symbol() external view returns (string memory);

  /// @notice Query the target being staked on by this contract.
  /// @return Address of target being staked on;
  function getTargetBeingStakedOn() external view returns (address);

  /// @notice Total rewards available for the supplied round.
  /// @return uint256 Amount of $RARE tokens allocated as rewards for round.
  function getRoundRewards(uint256 _round) external view returns (uint256);

  /// @notice Query rewards for the supplied user address for the round supplied rounds. Does not omit rewards for rounds that have already been claimed. Allows for easier historical lookups.
  /// @param _user Address of the user to get rewards.
  /// @param _rounds List of uint256 round ids to look up the rewards.
  /// @return uint256 Amount of $RARE tokens rewarded.
  function getHistoricalRewardsForUserForRounds(address _user, uint256[] memory _rounds)
    external
    view
    returns (uint256);

  /// @notice Query the available rewards for claim of the supplied user address for the number of rounds supplied. 
  /// @param _user Address of the user to get rewards.
  /// @param _numRounds Address of the user to get rewards.
  /// @return uint256 Amount of $RARE tokens rewarded.
  function getClaimableRewardsForUser(address _user, uint256 _numRounds) external view returns (uint256);

  /// @notice Calculates the number of sRare yielded from staking.
  /// @param _totalSRare Current supply of sRare.
  /// @param _stakedAmount Amount of RARE being staked.
  /// @return uint256 Amount of synthetic tokens one would get for staking {_stakedAmount} given a totalSupply of {_totalSRare}.
  function calculatePurchaseReturn(uint120 _totalSRare, uint120 _stakedAmount) external pure returns (uint256);

  /// @notice Calculates the number of rare yielded from unstaking.
  /// @param _totalSRareByUser Current balance of sRARE held by the given user.
  /// @param _totalRareStakedByUser Total Amount of RARE staked by the given user.
  /// @param _unstakeAmount Amount of sRare being traded in.
  /// @return uint256 Amount of $RARE tokens one would get for unstaking {_unstakeAmount} given {_totalSRareByUser} and {_totalRareStakedByUser}.
  function calculateSaleReturn(
    uint256 _totalSRareByUser,
    uint256 _totalRareStakedByUser,
    uint256 _unstakeAmount
  ) external pure returns (uint256);

  /// @notice Total rewards snapshotted since con.
  /// @return uint256 Amount of $RARE tokens allocated as rewards.
  function getAllTimeRewards() external view returns (uint256);

  /// @notice Get the unix creation time of the staking contract.
  /// @return uint256 unix creation time of the contract.
  function getCreationTime() external view returns (uint256);

  /// @notice Get the unix time of the most recent snapshot.
  /// @return uint256 unix time of the most recent snapshot.
  function getLastSnapshotTimestamp() external view returns (uint256);

  /// @notice Total amount of Rewards claimed.
  /// @return uint256 amount of rewards claimed.
  function getSumOfAllClaimed() external view returns (uint256);

  /// @notice Return the staking registry of the pool
  /// @return address of the staking registry.
  function getStakingRegistry() external view returns (address); 
}
