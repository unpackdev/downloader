pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";

import "./Ownable.sol";
import "./IStaking.sol";
import "./TokenPool.sol";


/**
 * @dev A smart-contract based mechanism to distribute tokens over time, inspired loosely by Compound and Uniswap.
 *
 *  Distribution tokens are added to a locked pool in the contract and become unlocked over time according to a once-configurable unlock schedule. Once unlocked, they are available to be claimed by users.
 *
 *  A user may deposit tokens to accrue ownership share over the unlocked pool. This owner share is a function of the number of tokens deposited as well as the length of time deposited.
 *
 *  Specifically, a user's share of the currently-unlocked pool equals their "deposit-seconds" divided by the global "deposit-seconds". This aligns the new token distribution with long term supporters of the project, addressing one of the major drawbacks of simple airdrops.
 *
 *  More background and motivation available at:
 *  https://github.com/ampleforth/RFCs/blob/master/RFCs/rfc-1.md
 */
contract TokenGeyser is IStaking, Ownable
{
  using SafeMath for uint;


  // single stake for user; user may have multiple.
  struct Stake
  {
    uint stakingShares;
    uint timestampSec;
  }

  // caches aggregated values from the User->Stake[] map to save computation.
  // if lastAccountingTimestampSec is 0, there's no entry for that user.
  struct UserTotals
  {
    uint stakingShares;
    uint stakingShareSeconds;
    uint lastAccountingTimestampSec;
  }

  // locked/unlocked state
  struct UnlockSchedule
  {
    uint initialLockedShares;
    uint unlockedShares;
    uint lastUnlockTimestampSec;
    uint endAtSec;
    uint durationSec;
  }


  TokenPool private _lockedPool;
  TokenPool private _unlockedPool;
  TokenPool private _stakingPool;

  UnlockSchedule[] public unlockSchedules;


  // time-bonus params
  uint public startBonus = 0;
  uint public bonusPeriodSec = 0;
  uint public constant BONUS_DECIMALS = 2;


  // global accounting state
  uint public totalLockedShares = 0;
  uint public totalStakingShares = 0;
  uint private _maxUnlockSchedules = 0;
  uint private _initialSharesPerToken = 0;
  uint private _totalStakingShareSeconds = 0;
  uint private _lastAccountingTimestampSec = now;


  // timestamp ordered stakes for each user, earliest to latest.
  mapping(address => Stake[]) private _userStakes;

  // staking values per user
  mapping(address => UserTotals) private _userTotals;

  mapping(address => uint) public initStakeTimestamps;


  event Staked(address indexed user, uint amount, uint total, bytes data);
  event Unstaked(address indexed user, uint amount, uint total, bytes data);

  event TokensClaimed(address indexed user, uint amount);
  event TokensLocked(uint amount, uint durationSec, uint total);
  event TokensUnlocked(uint amount, uint remainingLocked);


  /**
   * @param stakingToken The token users deposit as stake.
   * @param distributionToken The token users receive as they unstake.
   * @param maxUnlockSchedules Max number of unlock stages, to guard against hitting gas limit.
   * @param startBonus_ Starting time bonus, BONUS_DECIMALS fixed point. e.g. 25% means user gets 25% of max distribution tokens.
   * @param bonusPeriodSec_ Length of time for bonus to increase linearly to max.
   * @param initialSharesPerToken Number of shares to mint per staking token on first stake.
   */
  constructor(IERC20 stakingToken, IERC20 distributionToken, uint maxUnlockSchedules, uint startBonus_, uint bonusPeriodSec_, uint initialSharesPerToken) public
  {
    // start bonus must be <= 100%
    require(startBonus_ <= 10 ** BONUS_DECIMALS, "TokenGeyser: start bonus too high");
    // if no period is desired, set startBonus = 100% & bonusPeriod to small val like 1sec.
    require(bonusPeriodSec_ != 0, "TokenGeyser: bonus period is 0");
    require(initialSharesPerToken > 0, "TokenGeyser: initialSharesPerToken is 0");

    _stakingPool = new TokenPool(stakingToken);
    _lockedPool = new TokenPool(distributionToken);
    _unlockedPool = new TokenPool(distributionToken);

    startBonus = startBonus_;
    bonusPeriodSec = bonusPeriodSec_;
    _maxUnlockSchedules = maxUnlockSchedules;
    _initialSharesPerToken = initialSharesPerToken;
  }


  /**
   * @dev Returns the number of unlockable shares from a given schedule. The returned value depends on the time since the last unlock. This function updates schedule accounting, but does not actually transfer any tokens.
   *
   * @param s Index of the unlock schedule.
   *
   * @return The number of unlocked shares.
   */
  function unlockScheduleShares(uint s) private returns (uint)
  {
    UnlockSchedule storage schedule = unlockSchedules[s];

    if (schedule.unlockedShares >= schedule.initialLockedShares)
    {
      return 0;
    }

    uint sharesToUnlock = 0;

    // Special case to handle any leftover dust from integer division
    if (now >= schedule.endAtSec)
    {
      sharesToUnlock = (schedule.initialLockedShares.sub(schedule.unlockedShares));
      schedule.lastUnlockTimestampSec = schedule.endAtSec;
    }
    else
    {
      sharesToUnlock = now.sub(schedule.lastUnlockTimestampSec).mul(schedule.initialLockedShares).div(schedule.durationSec);

      schedule.lastUnlockTimestampSec = now;
    }

    schedule.unlockedShares = schedule.unlockedShares.add(sharesToUnlock);

    return sharesToUnlock;
  }

  /**
   * @dev Moves distribution tokens from the locked pool to the unlocked pool, according to the previously defined unlock schedules. Publicly callable.
   *
   * @return Number of newly unlocked distribution tokens.
   */
  function unlockTokens() public returns (uint)
  {
    uint unlockedTokens = 0;
    uint lockedTokens = totalLocked();

    if (totalLockedShares == 0)
    {
      unlockedTokens = lockedTokens;
    }
    else
    {
      uint unlockedShares = 0;

      for (uint s = 0; s < unlockSchedules.length; s++)
      {
        unlockedShares = unlockedShares.add(unlockScheduleShares(s));
      }

      unlockedTokens = unlockedShares.mul(lockedTokens).div(totalLockedShares);
      totalLockedShares = totalLockedShares.sub(unlockedShares);
    }

    if (unlockedTokens > 0)
    {
      require(_lockedPool.transfer(address(_unlockedPool), unlockedTokens), "TokenGeyser: tx out of locked pool failed");

      emit TokensUnlocked(unlockedTokens, totalLocked());
    }

    return unlockedTokens;
  }

  /**
   * @dev A globally callable function to update the accounting state of the system.
   *      Global state and state for the caller are updated.
   *
   * @return [0] balance of the locked pool
   * @return [1] balance of the unlocked pool
   * @return [2] caller's staking share seconds
   * @return [3] global staking share seconds
   * @return [4] Rewards caller has accumulated, optimistically assumes max time-bonus.
   *
   * @return [5] block timestamp
   */
  function updateAccounting() public returns (uint, uint, uint, uint, uint, uint)
  {
    unlockTokens();


    uint newStakingShareSeconds = now.sub(_lastAccountingTimestampSec).mul(totalStakingShares);

    _totalStakingShareSeconds = _totalStakingShareSeconds.add(newStakingShareSeconds);
    _lastAccountingTimestampSec = now;


    UserTotals storage totals = _userTotals[msg.sender];

    uint newUserStakingShareSeconds = now.sub(totals.lastAccountingTimestampSec).mul(totals.stakingShares);

    totals.stakingShareSeconds = totals.stakingShareSeconds.add(newUserStakingShareSeconds);
    totals.lastAccountingTimestampSec = now;

    uint totalUserRewards = (_totalStakingShareSeconds > 0) ? totalUnlocked().mul(totals.stakingShareSeconds).div(_totalStakingShareSeconds) : 0;

    return (totalLocked(), totalUnlocked(), totals.stakingShareSeconds, _totalStakingShareSeconds, totalUserRewards, now);
  }

  /**
   * @dev allows the contract owner to add more locked distribution tokens, along with the associated "unlock schedule". These locked tokens immediately begin unlocking linearly over the duration of durationSec timeframe.
   *
   * @param amount Number of distribution tokens to lock. These are transferred from the caller.
   *
   * @param durationSec Length of time to linear unlock the tokens.
   */
  function lockTokens(uint amount, uint durationSec) external onlyOwner
  {
    require(unlockSchedules.length < _maxUnlockSchedules, "TokenGeyser: reached max unlock schedules");

    // update lockedTokens amount before using it in computations after.
    updateAccounting();

    UnlockSchedule memory schedule;

    uint lockedTokens = totalLocked();
    uint mintedLockedShares = (lockedTokens > 0) ? totalLockedShares.mul(amount).div(lockedTokens) : amount.mul(_initialSharesPerToken);


    schedule.initialLockedShares = mintedLockedShares;
    schedule.lastUnlockTimestampSec = now;
    schedule.endAtSec = now.add(durationSec);
    schedule.durationSec = durationSec;
    unlockSchedules.push(schedule);

    totalLockedShares = totalLockedShares.add(mintedLockedShares);

    require(_lockedPool.token().transferFrom(msg.sender, address(_lockedPool), amount), "TokenGeyser: transfer into locked pool failed");

    emit TokensLocked(amount, durationSec, totalLocked());
  }


  /**
   * @dev Transfers amount of deposit tokens from the user.
   * @param amount Number of deposit tokens to stake.
   * @param data Not used.
   */
  function stake(uint amount, bytes calldata data) external
  {
    _stakeFor(msg.sender, msg.sender, amount);
  }

  /**
   * @dev Transfers amount of deposit tokens from the caller on behalf of user.
   * @param user User address who gains credit for this stake operation.
   * @param amount Number of deposit tokens to stake.
   * @param data Not used.
   */
  function stakeFor(address user, uint amount, bytes calldata data) external onlyOwner
  {
    _stakeFor(msg.sender, user, amount);
  }

  /**
   * @dev Private implementation of staking methods.
   * @param staker User address who deposits tokens to stake.
   * @param beneficiary User address who gains credit for this stake operation.
   * @param amount Number of deposit tokens to stake.
   */
  function _stakeFor(address staker, address beneficiary, uint amount) private
  {
    require(amount > 0, "TokenGeyser: stake amt is 0");
    require(beneficiary != address(0), "TokenGeyser: beneficiary is 0 addr");
    require(totalStakingShares == 0 || totalStaked() > 0, "TokenGeyser: Invalid state. Staking shares exist, but no staking tokens do");


    if (initStakeTimestamps[beneficiary] == 0)
    {
      initStakeTimestamps[beneficiary] = now;
    }


    uint mintedStakingShares = (totalStakingShares > 0) ? totalStakingShares.mul(amount).div(totalStaked()) : amount.mul(_initialSharesPerToken);


    require(mintedStakingShares > 0, "TokenGeyser: Stake too small");

    updateAccounting();


    UserTotals storage totals = _userTotals[beneficiary];

    totals.stakingShares = totals.stakingShares.add(mintedStakingShares);
    totals.lastAccountingTimestampSec = now;


    Stake memory newStake = Stake(mintedStakingShares, now);

    _userStakes[beneficiary].push(newStake);
    totalStakingShares = totalStakingShares.add(mintedStakingShares);

    require(_stakingPool.token().transferFrom(staker, address(_stakingPool), amount), "TokenGeyser: tx into staking pool failed");

    emit Staked(beneficiary, amount, totalStakedFor(beneficiary), "");
  }


  /**
   * @dev Applies an additional time-bonus to a distribution amount. This is necessary to encourage long-term deposits instead of constant unstake/restakes.
   * The bonus-multiplier is the result of a linear function that starts at startBonus and ends at 100% over bonusPeriodSec, then stays at 100% thereafter.

   * @param currentRewardTokens The current number of distribution tokens already allotted for this unstake op. Any bonuses are already applied.

   * @param stakingShareSeconds The stakingShare-seconds that are being burned for new distribution tokens.

   * @param stakeTimeSec Length of time for which the tokens were staked. Needed to calculate the time-bonus.

   * @return Updated amount of distribution tokens to award, with any bonus included on the newly added tokens.
   */
  function computeNewReward(uint currentRewardTokens, uint stakingShareSeconds, uint stakeTimeSec) private view returns (uint)
  {
    uint newRewardTokens = totalUnlocked().mul(stakingShareSeconds).div(_totalStakingShareSeconds);

    if (stakeTimeSec >= bonusPeriodSec)
    {
      return currentRewardTokens.add(newRewardTokens);
    }

    uint oneHundredPct = 10 ** BONUS_DECIMALS;
    uint bonusedReward = startBonus.add(oneHundredPct.sub(startBonus).mul(stakeTimeSec).div(bonusPeriodSec)).mul(newRewardTokens).div(oneHundredPct);

    return currentRewardTokens.add(bonusedReward);
  }

  /**
   * @dev Unstakes a certain amount of previously deposited tokens. User also receives their allotted number of distribution tokens.
   * @param amount Number of deposit tokens to unstake / withdraw.
   * @param data Not used.
   */
  function unstake(uint amount, bytes calldata data) external
  {
    _unstake(amount);
  }

  /**
   * @param amount Number of deposit tokens to unstake / withdraw.
   * @return The total number of distribution tokens that would be rewarded.
   */
  function unstakeQuery(uint amount) public returns (uint)
  {
    return _unstake(amount);
  }

  /**
   * @dev Unstakes a certain amount of previously deposited tokens. User also receives their allotted number of distribution tokens.
   * @param amount Number of deposit tokens to unstake / withdraw.

   * @return The total number of distribution tokens rewarded.
   */
  function _unstake(uint amount) private returns (uint)
  {
    uint initStakeTimestamp = initStakeTimestamps[msg.sender];

    require(now > initStakeTimestamp.add(10 days), "TokenGeyser: in cooldown");

    updateAccounting();

    require(amount > 0, "TokenGeyser: unstake amt is 0");
    require(totalStakedFor(msg.sender) >= amount, "TokenGeyser: unstake amt > total user stakes");

    uint stakingSharesToBurn = totalStakingShares.mul(amount).div(totalStaked());

    require(stakingSharesToBurn > 0, "TokenGeyser: unstake too small");


    UserTotals storage totals = _userTotals[msg.sender];
    Stake[] storage accountStakes = _userStakes[msg.sender];

    // redeem from most recent stake and go backwards in time.
    uint rewardAmount = 0;
    uint stakingShareSecondsToBurn = 0;
    uint sharesLeftToBurn = stakingSharesToBurn;

    while (sharesLeftToBurn > 0)
    {
      Stake storage lastStake = accountStakes[accountStakes.length - 1];
      uint stakeTimeSec = now.sub(lastStake.timestampSec);
      uint newStakingShareSecondsToBurn = 0;

      if (lastStake.stakingShares <= sharesLeftToBurn)
      {
        // fully redeem a past stake
        newStakingShareSecondsToBurn = lastStake.stakingShares.mul(stakeTimeSec);
        rewardAmount = computeNewReward(rewardAmount, newStakingShareSecondsToBurn, stakeTimeSec);
        stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(newStakingShareSecondsToBurn);
        sharesLeftToBurn = sharesLeftToBurn.sub(lastStake.stakingShares);
        accountStakes.length--;
      }
      else
      {
        // partially redeem a past stake
        newStakingShareSecondsToBurn = sharesLeftToBurn.mul(stakeTimeSec);
        rewardAmount = computeNewReward(rewardAmount, newStakingShareSecondsToBurn, stakeTimeSec);
        stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(newStakingShareSecondsToBurn);
        lastStake.stakingShares = lastStake.stakingShares.sub(sharesLeftToBurn);
        sharesLeftToBurn = 0;
      }
    }

    totals.stakingShareSeconds = totals.stakingShareSeconds.sub(stakingShareSecondsToBurn);
    totals.stakingShares = totals.stakingShares.sub(stakingSharesToBurn);


    _totalStakingShareSeconds = _totalStakingShareSeconds.sub(stakingShareSecondsToBurn);
    totalStakingShares = totalStakingShares.sub(stakingSharesToBurn);


    uint unstakeFee = amount.mul(100).div(10000);

    if (now >= initStakeTimestamp.add(45 days))
    {
      unstakeFee = amount.mul(75).div(10000);
    }

    require(_stakingPool.transfer(owner(), unstakeFee), "TokenGeyser: err tx'ing fee");

    require(_stakingPool.transfer(msg.sender, amount.sub(unstakeFee)), "TokenGeyser: tx out of staking pool failed");
    require(_unlockedPool.transfer(msg.sender, rewardAmount), "TokenGeyser: tx out of unlocked pool failed");

    emit Unstaked(msg.sender, amount, totalStakedFor(msg.sender), "");
    emit TokensClaimed(msg.sender, rewardAmount);

    require(totalStakingShares == 0 || totalStaked() > 0, "TokenGeyser: Err unstaking. Staking shares exist, but no staking tokens do");

    return rewardAmount;
  }


  /**
   * @param addr  user to look up staking information for.
   * @return The number of staking tokens deposited for addr.
   */
  function totalStakedFor(address addr) public view returns (uint)
  {
    return totalStakingShares > 0 ? totalStaked().mul(_userTotals[addr].stakingShares).div(totalStakingShares) : 0;
  }

  /**
   * @return The total number of deposit tokens staked globally, by all users.
   */
  function totalStaked() public view returns (uint)
  {
    return _stakingPool.balance();
  }

  /**
   * @return Total number of locked distribution tokens.
   */
  function totalLocked() public view returns (uint)
  {
    return _lockedPool.balance();
  }

  /**
   * @return Total number of unlocked distribution tokens.
   */
  function totalUnlocked() public view returns (uint)
  {
    return _unlockedPool.balance();
  }

  /**
   * @return Number of unlock schedules.
   */
  function unlockScheduleCount() public view returns (uint)
  {
    return unlockSchedules.length;
  }


  // getUserTotals, getTotalStakingShareSeconds, getLastAccountingTimestamp functions added for Yield

  /**
   * @param addr  user to look up staking information for

   * @return The UserStakes for this address
   */
  function getUserStakes(address addr) public view returns (Stake[] memory)
  {
    Stake[] memory userStakes = _userStakes[addr];

    return userStakes;
  }

  /**
   * @param addr user to look up staking information for

   * @return The UserTotals for this address.
   */
  function getUserTotals(address addr) public view returns (UserTotals memory)
  {
    UserTotals memory userTotals = _userTotals[addr];

    return userTotals;
  }

  /**
   * @return The total staking share seconds
   */
  function getTotalStakingShareSeconds() public view returns (uint256)
  {
    return _totalStakingShareSeconds;
  }

  /**
   * @return The last global accounting timestamp.
   */
  function getLastAccountingTimestamp() public view returns (uint256)
  {
    return _lastAccountingTimestampSec;
  }

  /**
   * @return The token users receive as they unstake.
   */
  function getDistributionToken() public view returns (IERC20)
  {
    assert(_unlockedPool.token() == _lockedPool.token());

    return _unlockedPool.token();
  }

  /**
   * @return The token users deposit as stake.
   */
  function getStakingToken() public view returns (IERC20)
  {
    return _stakingPool.token();
  }

  /**
   * @dev Note that this application has a staking token as well as a distribution token, which may be different. This function is required by EIP-900.

   * @return The deposit token used for staking.
   */
  function token() external view returns (address)
  {
    return address(getStakingToken());
  }
}
