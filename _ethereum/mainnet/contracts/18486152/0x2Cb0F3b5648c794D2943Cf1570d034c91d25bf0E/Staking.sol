// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Imports
import "./Pausable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./AccessControl.sol";
import "./IStaking.sol";

/**
 * @notice Staking smart contract
 * @dev This smart contract currently DOES NOT support fee-on-transfer or rebasing 
        tokens so you MUST NOT use them.
 */
contract Staking is AccessControl, Pausable, IStaking {
  using SafeERC20 for IERC20;

  // Structures
  struct StakePosition {
    uint amount; // amount of tokens staked
    uint timestamp; // block timestamp of the stake operation
    uint rewardsPercentage; // rewards for this position
    bool singleClaimed; // true if user unstakes ONLY this exact position 
  }

  // Constants
  uint public constant REWARDS_DIVIDER = 10000;
  uint public immutable STAKING_TERM;

  // Members
  uint public rewardsPercentage;
  uint public availableRewards;
  uint public totalStakedTokens;
  IERC20 public tokenToStake;
  IERC20 public rewardToken;
  mapping (address => uint) public totalStakedByUser;
  mapping (address => uint) public tail;
  mapping (address => uint) public head;
  mapping (address => mapping(uint => StakePosition) ) public stakeQueue;

  /**
   * @notice Constructor
   * @param _tokenToStake Address of the staking token
   * @param _rewardToken Address of the reward token
   * @param _rewardsPercentage Percentage of token to distribute as a reward
            for the stakers
   * @param _stakingTerm Seconds that needs to pass from the stake to consider
            the position eligible for rewards
   */
  constructor (
    address _tokenToStake, 
    address _rewardToken,  
    uint _rewardsPercentage, 
    uint _stakingTerm
  ) {
    require(_stakingTerm <= 365 days, "constructor: invalid term");

    // Setup roles
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    tokenToStake = IERC20(_tokenToStake);
    rewardToken = IERC20(_rewardToken);

    rewardsPercentage = _rewardsPercentage;
    STAKING_TERM = _stakingTerm;
  }

  /////////////////////////////////////////////////////////////////////////////
  // EXTERNAL FUNCTIONS

  /**
   * @notice Stake tokens
   * @param _amount Amount of tokens to stake
   * @dev Caller has to approve the transger of _amount staking tokens from
            its wallet to this contract
   */
  function stake(
    uint _amount
  ) external override  whenNotPaused {
    require (_amount > 0, "Invalid amount");

    // Get tokens
    SafeERC20.safeTransferFrom(tokenToStake, msg.sender, address(this), _amount);

    // Create staking position
    uint positionIndex = head[msg.sender];

    StakePosition storage position = stakeQueue[msg.sender][positionIndex];
    position.amount = _amount;
    position.timestamp = block.timestamp;
    position.rewardsPercentage = rewardsPercentage;
    position.singleClaimed = false;

    // Update staked tokens
    totalStakedByUser[msg.sender] += _amount;
    totalStakedTokens += _amount;

    // Update head
    head[msg.sender] = positionIndex + 1;

    // emit event
    emit Stake(msg.sender, _amount, block.timestamp);
  }

  /**
   * @notice Unstake positions that are eligible for the rewards
   */
  function unstake() external override {
    _unstake(msg.sender, false);
  }

  /**
   * @notice Unstake all positions (also ones not eligible for the rewards)
   */
  function unstakeForced() external override {
    _unstake(msg.sender, true);
  }

  /**
   * @notice Unstake single position in the queue
   * @param _index Index of the position in the queue
   */
  function unstakeSingle(
    uint _index
  ) external override {
    // Check that index is valid
    require (_index < head[msg.sender] && _index >= tail[msg.sender], "Invalid index");
    
    // Check position hasn't been already claimed
    StakePosition storage position = stakeQueue[msg.sender][_index];
    require (! position.singleClaimed, "Already claimed");

    // Check if eligible for rewards and eventually compute them
    uint timeDiff = block.timestamp - position.timestamp;
    uint totalRewards = 0;
    if (timeDiff >= STAKING_TERM) {
      totalRewards = position.amount * position.rewardsPercentage / REWARDS_DIVIDER;

      // Sanity check. Do not transfer more than what's in the contract
      if (totalRewards > availableRewards) {
        totalRewards = availableRewards;
      }

      // Update available rewards
      availableRewards -= totalRewards;
    }

    // Transfer staked tokens
    SafeERC20.safeTransfer(tokenToStake, msg.sender, position.amount);

    totalStakedByUser[msg.sender] -= position.amount;
    totalStakedTokens -= position.amount;

    // Transfer rewards
    if (totalRewards > 0) {
      rewardToken.transfer(msg.sender, totalRewards);
    }

    // Update position as claimed
    position.singleClaimed = true;

    // Emit unstale event
    emit Unstake(msg.sender, position.amount, totalRewards, block.timestamp);
  }

  /**
   * @notice Compute staking rewards for an address
   * @param _staker Address of which you want to compute rewards
   */
  function computeRewards(
    address _staker
  ) external view override returns (uint) {
    (uint rewards , , ) = _rewards(_staker, false);

    return rewards;
  }

  /**
   * @notice Compute staking rewards for an address
   * @param _staker Address of which you want to compute rewards
   * @param _unstakeAll If true, simulates unstaking all position. If not,
              simulates unstaking only position available for rewards.
   */
  function previewUnstake(
    address _staker,
    bool _unstakeAll
  ) external view override returns (uint, uint) {
    (uint rewards , uint totalStaked , ) = _rewards(_staker, _unstakeAll);

    return (rewards, totalStaked);
  }

  /**
   * @notice Compute rewards for a single stake
   * @param _staker Address of which you want to compute rewards
   * @param _index Index of the stake position
   */
  function computeRewardsSingle(
    address _staker,
    uint _index
  ) external view override returns (uint) {
    // Check that index is valid
    require (_index < head[_staker] && _index >= tail[_staker], "Invalid index");
    
    // Check position hasn't been already claimed
    StakePosition storage position = stakeQueue[_staker][_index];
    require (! position.singleClaimed, "Already claimed");

    // Check if eligible for rewards and eventually compute them
    uint timeDiff = block.timestamp - position.timestamp;
    uint totalRewards = 0;
    if (timeDiff >= STAKING_TERM) {
      totalRewards = position.amount * position.rewardsPercentage / REWARDS_DIVIDER;
    }

    return totalRewards;
  }

  /////////////////////////////////////////////////////////////////////////////
  // PRIVILEGED FUNCTIONS
  /**
   * @notice Add rewards to the staking
   * @param _amount Amount of rewards to add
   * @dev Caller has to approve the transfer of _amount reward tokens from its
            wallet to this contract
   */
  function addRewards(
    uint _amount
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    // Get tokens 
    SafeERC20.safeTransferFrom(rewardToken, msg.sender, address(this), _amount);

    // Update counter
    availableRewards += _amount;
  }

  /**
   * @notice Update rewards percentage for new positions
   * @param _percentage New reward percentage
   */
  function updateRewardsPercentage(
    uint _percentage
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    rewardsPercentage = _percentage;

    emit UpdatedRewardsPercentage(_percentage);
  }

  /**
   * @notice Pause staking functionality
   */
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  /**
   * @notice Pause staking functionality
   */
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  /////////////////////////////////////////////////////////////////////////////
  // INTERNAL FUNCTIONS
  /**
   * @notice Compute rewards and staked tokens for an address
   * @param _staker Address of the staker
   * @param _forced If true, counts staked tokens for every position. If not,
            only checks for rewards eligible positions
   * @return totalRewards Rewards generated by the stakers
   * @return totalStaked Number of staked tokens by the staker
   * @return tailPosition New tail position if the staker effectively unstake
   */
  function _rewards(
    address _staker,
    bool _forced
  ) internal view returns (uint, uint, uint) {
    uint totalRewards = 0;
    uint totalStaked = 0;

    // Compute total rewards 
    uint tailPosition = tail[_staker];
    for (; tailPosition < head[_staker]; tailPosition++) {
      StakePosition memory position = stakeQueue[_staker][tailPosition];  

      // Check if position has already been exclusively claimed
      if (position.singleClaimed) {
        continue;
      }

      // Compute time difference and check if stake is eligible 
      uint timeDiff = block.timestamp - position.timestamp;
      if (timeDiff >= STAKING_TERM) {
        // Since it's eligible, add rewards
        totalRewards += position.amount * position.rewardsPercentage / REWARDS_DIVIDER;
      } else if (! _forced) {
        break;
      }

      // Update staked tokens to transfer
      totalStaked += position.amount;
    }

    // Sanity check. Do not transfer more than what's in the contract
    if (totalRewards > availableRewards) {
      totalRewards = availableRewards;
    }

    return (totalRewards, totalStaked, tailPosition);
  }

  /**
   * @notice Internal unstake
   * @param _staker Address of the staker
   * @param _forceUnstake If true, unstake every position (also the ones that 
            won't receive rewards)
   * @dev Transfer accumulated rewards and also staked tokens 
   */
  function _unstake(
    address _staker, 
    bool _forceUnstake
  ) internal {
    (uint totalRewards, uint totalStaked, uint tailPosition) = _rewards(_staker, _forceUnstake);

    // Transfer rewards
    if (totalRewards > 0) {
      SafeERC20.safeTransfer(rewardToken, _staker, totalRewards);
    }

    // Transfer staked tokens
    if (totalStaked > 0) {
      SafeERC20.safeTransfer(tokenToStake, _staker, totalStaked);

      // Update total staked
      totalStakedByUser[_staker] -= totalStaked;
      totalStakedTokens -= totalStaked;
    }

    // Update available rewards
    availableRewards -= totalRewards;

    // Update tail
    tail[msg.sender] = tailPosition;

    // Emit event
    emit Unstake(_staker, totalStaked, totalRewards, block.timestamp);
  }
}
