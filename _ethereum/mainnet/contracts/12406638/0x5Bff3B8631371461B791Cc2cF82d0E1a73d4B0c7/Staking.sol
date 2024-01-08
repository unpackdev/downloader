// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ERC20.sol";
import "./Ownable.sol";

import "./CappedRewardCalculator.sol";
import "./ClaimsRegistry.sol";

/// @title A staking contract which allows only verified users (by checking a separate contract for a valid signature)
/// @author Miguel Palhas <miguel@subvisual.co>
contract Staking is CappedRewardCalculator, Ownable {
  /// @notice the token to stake
  ERC20 public immutable erc20;

  /// @notice claim registry where signatures are to be stored and verified
  IClaimsRegistryVerifier public immutable registry;

  /// @notice The expected attester address against which claims will be verified
  ///   (i.e. they must be signed by this address)
  address public immutable claimAttester;

  /// @notice The minimum staking amount per account
  uint public immutable minAmount;

  /// @notice The maximum staking amount per account
  uint public immutable maxAmount;

  /// @notice Locked rewards pending withdrawal
  uint public lockedReward = 0;

  /// @notice Rewards already distributed
  uint public distributedReward = 0;

  /// @notice How much is currently staked
  uint public stakedAmount = 0;

  /// @notice Subscription details for each account
  mapping(address => Subscription) public subscriptions;

  /// @notice Emitted when an account stakes tokens and creates a new subscription
  event Subscribed(
    address subscriber,
    uint date,
    uint stakedAmount,
    uint maxReward
  );

  /// @notice Emitted when an account withdraws an existing stake
  event Withdrawn(
    address subscriber,
    uint date,
    uint withdrawAmount
  );

  /// @notice Details of a particular subscription
  struct Subscription {
    bool active;
    address subscriberAddress; // addres the subscriptions refers to
    uint startDate;      // Block timestamp at which the subscription was made
    uint stakedAmount;   // How much was staked
    uint maxReward;      // Maximum reward given if user stays until the end of the staking period
    uint withdrawAmount; // Total amount withdrawn (initial amount + final calculated reward)
    uint withdrawDate;   // Block timestamp at which the subscription was withdrawn (or 0 while staking is in progress)
  }

  /// @notice Staking constructor
  /// @param _token ERC20 token address to use
  /// @param _registry ClaimsRegistry address to use
  /// @param _attester expected attester of claims when verifying them
  /// @param _startDate timestamp starting at which stakes are allowed. Must be greater than instantiation timestamp
  /// @param _endDate timestamp at which staking is over (no more rewards are given, and new stakes are not allowed)
  /// @param _minAmount minimum staking amount for each account
  /// @param _maxAmount maximum staking amount for each account
  /// @param _cap max % of individual reward for curve period
  constructor(
    address _token,
    address _registry,
    address _attester,
    uint _startDate,
    uint _endDate,
    uint _minAmount,
    uint _maxAmount,
    uint _cap
  ) CappedRewardCalculator(_startDate, _endDate, _cap) {
    require(_token != address(0), "Staking: token address cannot be 0x0");
    require(_registry != address(0), "Staking: claims registry address cannot be 0x0");
    require(_attester != address(0), "Staking: claim attester cannot be 0x0");
    require(block.timestamp <= _startDate, "Staking: start date must be in the future");
    require(_minAmount > 0, "Staking: invalid individual min amount");
    require(_maxAmount > _minAmount, "Staking: max amount must be higher than min amount");

    erc20 = ERC20(_token);
    registry = IClaimsRegistryVerifier(_registry);
    claimAttester = _attester;

    minAmount = _minAmount;
    maxAmount = _maxAmount;
  }

  /// @notice Get the total size of the reward pool
  /// @return Returns the total size of the reward pool, including locked and distributed tokens
  function totalPool() public view returns (uint) {
    return erc20.balanceOf(address(this)) - stakedAmount + distributedReward;
  }

  /// @notice Get the available size of the reward pool
  /// @return Returns the available size of the reward pool, no including locked or distributed rewards
  function availablePool() public view returns (uint) {
    return erc20.balanceOf(address(this)) - stakedAmount - lockedReward;
  }

  /// @notice Requests a new stake to be created. Only one stake per account is
  ///   created, maximum rewards are calculated upfront, and a valid claim
  ///   signature needs to be provided, which will be checked against the expected
  ///   attester on the registry contract
  /// @param _amount Amount of tokens to stake
  /// @param claimSig Signature to check against the registry contract
  function stake(uint _amount, bytes calldata claimSig) external {
    uint time = block.timestamp;
    address subscriber = msg.sender;

    require(registry.verifyClaim(msg.sender, claimAttester, claimSig), "Staking: could not verify claim");
    require(_amount >= minAmount, "Staking: staked amount needs to be greater than or equal to minimum amount");
    require(_amount <= maxAmount, "Staking: staked amount needs to be lower than or equal to maximum amount");
    require(time >= startDate, "Staking: staking period not started");
    require(time < endDate, "Staking: staking period finished");
    require(subscriptions[subscriber].active == false, "Staking: this account has already staked");


    uint maxReward = calculateReward(time, endDate, _amount);
    require(maxReward <= availablePool(), "Staking: not enough tokens available in the pool");
    lockedReward += maxReward;
    stakedAmount += _amount;

    subscriptions[subscriber] = Subscription(
      true,
      subscriber,
      time,
      _amount,
      maxReward,
      0,
      0
    );

    // transfer tokens from subscriber to the contract
    require(erc20.transferFrom(subscriber, address(this), _amount),
      "Staking: Could not transfer tokens from subscriber");

    emit Subscribed(subscriber, time, _amount, maxReward);
  }

  /// @notice Withdrawn the stake belonging to `msg.sender`
  function withdraw() external {
    address subscriber = msg.sender;
    uint time = block.timestamp;

    require(subscriptions[subscriber].active == true, "Staking: no active subscription found for this address");

    Subscription memory sub = subscriptions[subscriber];

    uint actualReward = calculateReward(sub.startDate, time, sub.stakedAmount);
    uint total = sub.stakedAmount + actualReward;

    // update subscription state
    sub.withdrawAmount = total;
    sub.withdrawDate = time;
    sub.active = false;
    subscriptions[subscriber] = sub;

    // update locked amount
    lockedReward -= sub.maxReward;
    distributedReward += actualReward;
    stakedAmount -= sub.stakedAmount;

    // transfer tokens back to subscriber
    require(erc20.transfer(subscriber, total), "Staking: Transfer has failed");

    emit Withdrawn(subscriber, time, total);
  }

  /// @notice returns the initial amount staked by a given account
  /// @param _subscriber The account to check
  /// @return The amount that was staked by the given account
  function getStakedAmount(address _subscriber) external view returns (uint) {
    if (subscriptions[_subscriber].stakedAmount > 0 && subscriptions[_subscriber].withdrawDate == 0) {
      return subscriptions[_subscriber].stakedAmount;
    } else {
      return 0;
    }
  }

  /// @notice Gets the maximum reward for an existing subscription
  /// @param _subscriber address of the subscription to check
  /// @return Maximum amount of tokens the subscriber can get by staying until the end of the staking period
  function getMaxStakeReward(address _subscriber) external view returns (uint) {
    Subscription memory sub = subscriptions[_subscriber];

    if (sub.active) {
      return subscriptions[_subscriber].maxReward;
    } else {
      return 0;
    }
  }

  /// @notice Gets the amount already earned by an existing subscription
  /// @param _subscriber address of the subscription to check
  /// @return Amount the subscriber has earned to date
  function getCurrentReward(address _subscriber) external view returns (uint) {
    Subscription memory sub = subscriptions[_subscriber];

    if (sub.active) {
      return calculateReward(sub.startDate, block.timestamp, sub.stakedAmount);
    } else {
      return 0;
    }
  }

  /// @notice Withdraws all unlocked tokens from the pool to the owner. Only works if staking period has already ended
  function withdrawPool() external onlyOwner {
    require(block.timestamp > endDate, "Staking: staking not over yet");

    erc20.transfer(owner(), availablePool());
  }
}
