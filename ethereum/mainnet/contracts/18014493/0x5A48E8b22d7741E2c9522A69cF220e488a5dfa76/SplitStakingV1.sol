// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStakingManagerV1.sol";
import "./Address.sol";
import "./Dex.sol";
import "./Governable.sol";
import "./Pausable.sol";
import "./IStakingV1.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

struct AccountBountyRewards {
  uint256 count;
  uint256 claimed;
}

contract SplitStakingV1 is Governable, Pausable, ReentrancyGuard {
  using Address for address payable;

  event DepositedEth(address indexed account, uint256 amount);
  event DistributedRewards(
    address indexed account,
    uint256 soloStakingRewards,
    uint256 lpStakingRewards,
    uint256 distributorReward
  );

  /** @dev set the deployer as both owner and governor initially */
  constructor() Governable(_msgSender(), _msgSender()) {
    // use a real value for this, but make sure to subtract
    // the cooldown duration so we can immediately distribute
    // _lastDistributionAt = block.timestamp - _distributionCooldown;
    _lastActionAt = block.timestamp;
    // _lastDistributionAt = block.timestamp;
  }

  address internal constant UNSET_ID = address(0);

  address internal _soloStakingAddress = UNSET_ID;
  address internal _lpStakingAddress = UNSET_ID;

  IERC20 internal _soloStakingToken;
  IUniswapV2Pair internal _lpStakingToken;

  /** @dev 0-10000 based percent for fee rewarded for distributing */
  uint16 internal _rewardForDistributing = 300; // 3%

  // TODO 5 eth per day is high currently, but it's easier to test with. change this later.
  uint256 internal _distributionRewardRate = uint256(5 * 10 ** 18) / 1 days; // 5 eth per day
  uint256 internal _distributionRewardAmountModifier = 1000 * 10 ** 11;

  uint256 internal _totalRewards = 0;
  // uint256 internal _waitingRewards = 0;
  uint256 internal _distributedRewards = 0;
  uint256 internal _cachedRewards = 0;

  /** @dev if this is too low, the gas cost of distributing will be greater than the reward */
  uint256 internal _minimumRewardsForDistribution = 1; // 1 * 10 ** 17; // 0.1 eth
  /** @dev if this is too high, this contract might run out of rewards too quickly */
  uint256 internal _maximumRewardsForDistribution = 35 * 10 ** 16; // 0.35 eth
  /** @dev start this at a low value for testing, since waiting is no good. increase this on mainnets */
  uint256 internal _distributionCooldown = 0; // minutes;
  // uint256 internal _lastDistributionAt = 0;
  uint256 internal _lastActionAt = 0;

  /** @dev 0 = auto, 1 = only lp, 2 = only solo */
  uint8 internal _rewardsMode = 0;

  mapping(address => AccountBountyRewards) internal _bountyRewards;

  /** @dev 0 = auto, 1 = only lp, 2 = only solo */
  function rewardsMode() external view returns (uint8) {
    return _rewardsMode;
  }

  /**
   * @dev 0 = auto, 1 = only lp, 2 = only solo
   */
  function setRewardsMode(uint8 value) external onlyOwner {
    require(value <= 2, "Invalid rewardsMode value");

    _rewardsMode = value;
  }

  function rewardForDistributing() external view returns (uint16) {
    return _rewardForDistributing;
  }

  function setRewardForDistributing(uint16 value) external onlyGovernor {
    // hard cap reward at 10%, which is probably higher than it ever should be
    _rewardForDistributing = value < 1000 ? value : 1000;
  }

  function distributionRewardRate() external view returns (
    uint256 rate,
    uint256 amountModifier
  ) {
    rate = _distributionRewardRate;
    amountModifier = _distributionRewardAmountModifier;
  }

  function setDistributionRewardRate(
    uint256 distributionRewardRate_,
    uint256 distributionRewardAmountModifier_
  ) external onlyGovernor {
    _distributionRewardRate = distributionRewardRate_;
    _distributionRewardAmountModifier = distributionRewardAmountModifier_;
  }

  function setRewardsForDistribution(uint256 min, uint256 max) external onlyGovernor {
    _minimumRewardsForDistribution = min;
    _maximumRewardsForDistribution = max;
  }

  /**
   * @dev this is here for public visibility.
   */
  function getRewardsForDistribution() external view returns (uint256 min, uint256 max) {
    min = _minimumRewardsForDistribution;
    max = _maximumRewardsForDistribution;
  }

  function setDistributionCooldown(uint256 sec) external onlyGovernor {
    _distributionCooldown = sec;
  }

  function setSoloStakingAddress(address address_) external onlyOwner {
    IStakingV1 stake = IStakingV1(address_);
    require(!stake.rewardsAreToken(), "Split rewards cannot be a token");
    _soloStakingAddress = address_;
    (,address stakedToken,,,,) = stake.getStakingData();
    _soloStakingToken = IERC20(stakedToken);
  }

  function setLpStakingAddress(address address_) external onlyOwner {
    IStakingV1 stake = IStakingV1(address_);
    require(!stake.rewardsAreToken(), "Split rewards cannot be a token");
    _lpStakingAddress = address_;
    (,address stakedToken,,,,) = stake.getStakingData();
    _lpStakingToken = IUniswapV2Pair(stakedToken);
  }

  function _ready() internal virtual view returns (bool) {
    return _soloStakingAddress != UNSET_ID && _lpStakingAddress != UNSET_ID;
  }

  function getGlobalStakingData() external view returns (
    bool ready,
    address mainToken,
    address soloStakingAddress,
    address lpStakingAddress,
    uint16 liquidityRatio,
    uint16 rewardsRatio
  ) {
    ready = _ready();
    mainToken = address(_soloStakingToken);
    soloStakingAddress = _soloStakingAddress;
    lpStakingAddress = _lpStakingAddress;
    liquidityRatio = _getLiquidityRatio();
    rewardsRatio = _getRewardsRatio();
  }

  /**
   * @return main token price in eth
   */
  function _getMainTokenPrice() internal virtual view returns (uint256) {
    if (!_ready())
      return 0;

    address lpAddress = address(_lpStakingToken);
    uint256 soloBalance = _soloStakingToken.balanceOf(lpAddress);
    uint256 pairedBalance = _getPairedTokenBalance();

    if (soloBalance == 0 || pairedBalance == 0)
      return 0;
    
    return pairedBalance * 10**18 / soloBalance;
  }

  function getMainTokenPrice() external view returns (uint256) {
    return _getMainTokenPrice();
  }

  function _getPairedTokenBalance() internal virtual view returns (uint256) {
    if (!_ready())
      return 0;
    
    IERC20 pairedToken = IERC20(
      _lpStakingToken.token0() == address(_soloStakingToken)
        ? _lpStakingToken.token1()
        : _lpStakingToken.token0()
    );

    return pairedToken.balanceOf(address(_lpStakingToken));
  }

  /**
   * @return main token market cap, in eth
   */
  function _getMainTokenMarketCap() internal virtual view returns (uint256) {
    if (!_ready())
      return 0;
    
    return _getMainTokenPrice() * (_soloStakingToken.totalSupply() / 10 ** _soloStakingToken.decimals());
  }

  function getMainTokenMarketCap() external view returns (uint256) {
    return _getMainTokenMarketCap();
  }

  function _getLiquidityRatio() internal virtual view returns (uint16) {
    if (!_ready())
      return 1000;
    
    uint256 marketCap = _getMainTokenMarketCap();

    // avoid dividing by zero, even though market cap should never be 0
    if (marketCap == 0)
      return 1000;
    
    uint256 ratio = _getPairedTokenBalance() * 10000 / marketCap;
    return uint16(ratio < 10000 ? ratio : 10000);

    // uint256 ratio = _soloStakingToken.balanceOf(address(_lpStakingToken)) * 10000 / _soloStakingToken.totalSupply();
    // return uint16(ratio < 10000 ? ratio : 10000);
  }

  function getLiquidityRatio() external view returns (uint16) {
    return _getLiquidityRatio();
  }

  function _getRewardsRatio() internal virtual view returns (uint16) {
    if (_rewardsMode == 1) {
      return 0;
    } else if (_rewardsMode == 2) {
      return 10000;
    }

    uint16 liquidityRatio = _getLiquidityRatio();

    return liquidityRatio <= 1000
      ? liquidityRatio * 5
      : 5000 + ((liquidityRatio - 1000) / 2);
  }

  function getRewardsRatio() external view returns (uint16) {
    return _getRewardsRatio();
  }

  /**
   * @param rewards amount of rewards to clamp
   * @param subtractAmount amount to subtract from contract balance - used when depositing
   */
  function _clampRewards(uint256 rewards, uint256 subtractAmount) internal virtual view returns (uint256) {
    if (rewards < _minimumRewardsForDistribution)
      return 0;

    return Math.min(rewards, Math.min(address(this).balance - subtractAmount, _maximumRewardsForDistribution));
  }

  function _getAvailableRewardsUnclamped() internal virtual view returns (uint256) {
    uint256 rewardsBalance = address(this).balance;
    if (rewardsBalance == 0) return 0;
    uint256 diff = block.timestamp - _lastActionAt;
    uint256 rewards = _cachedRewards;
    rewards += diff * _distributionRewardRate;
    rewards += Math.mulScale(
      rewardsBalance,
      diff * _distributionRewardAmountModifier,
      10 ** 18
    );
    
    return rewards;
  }

  function _getAvailableRewards() internal virtual view returns (uint256) {
    return _clampRewards(_getAvailableRewardsUnclamped(), 0);
  }

  function getAvailableRewards() external view returns (uint256) {
    return _getAvailableRewards();
  }

  function _canDistribute() internal virtual view returns (bool) {
    return (
      (
        _rewardsMode == 0 && _ready()
      ) || (
        _rewardsMode == 1 && _lpStakingAddress != UNSET_ID
      ) || (
        _rewardsMode == 2 && _soloStakingAddress != UNSET_ID
      )
    ) && _getAvailableRewards() >= _minimumRewardsForDistribution;
  }

  function canDistribute() external view returns (bool) {
    return _canDistribute();
  }

  function _getStakingRewards(bool includeDistributorReward) internal virtual view returns (
    uint256 combinedRewards,
    uint256 soloStakingRewards,
    uint256 lpStakingRewards,
    uint256 distributorReward,
    uint256 totalRewards,
    uint256 waitingRewards
    // uint256 lastDistributionAt
  ){
    // lastDistributionAt = _lastDistributionAt;
    totalRewards = _totalRewards;
    waitingRewards = address(this).balance;
    combinedRewards = _getAvailableRewards();
    
    if (combinedRewards != 0) {
      distributorReward = includeDistributorReward
        ? Math.mulScale(combinedRewards, _rewardForDistributing, 10000)
        : 0;
      
      uint256 leftoverRewards = combinedRewards - distributorReward;

      if (_rewardsMode == 1) {
        // give all rewards to lp staking when rewardsMode == 1
        lpStakingRewards = leftoverRewards;
      } else if (_rewardsMode == 2) {
        // give all rewards to solo staking when rewardsMode == 2
        soloStakingRewards = leftoverRewards;
      } else {
        // automatically distribute rewards between solo & lp staking
        soloStakingRewards = Math.mulScale(leftoverRewards, _getRewardsRatio(), 10000);
        lpStakingRewards = leftoverRewards - soloStakingRewards;
      }
    }
  }

  function getStakingRewards() external view returns (
    uint256 combinedRewards,
    uint256 soloStakingRewards,
    uint256 lpStakingRewards,
    uint256 distributorReward,
    uint256 totalRewards,
    uint256 waitingRewards
    // uint256 lastDistributionAt
  ){
    return _getStakingRewards(true);
  }

  function _distribute(address payable distributor, bool revertOnFailure) internal virtual {
    if (!_canDistribute()) {
      if (revertOnFailure)
        revert("Cannot distribute");
      else return;
    }

    (
      uint256 combinedRewards,
      uint256 soloStakingRewards,
      uint256 lpStakingRewards,
      uint256 distributorReward,,
    // contracts are exempt from receiving rewards - sorry not sorry
    ) = _getStakingRewards(!distributor.isContract());

    if (combinedRewards == 0) {
      if (revertOnFailure)
        revert("No rewards to distribute");
      else return;
    }

    _cachedRewards = 0;

    // keep track of the last timestamp that we're distributing rewards,
    // so we can use the cooldown feature to limit the number of rewards transactions.
    _lastActionAt = block.timestamp;

    if (soloStakingRewards != 0)
      payable(_soloStakingAddress).sendValue(soloStakingRewards);
    if (lpStakingRewards != 0)
      payable(_lpStakingAddress).sendValue(lpStakingRewards);
    if (distributorReward != 0) {
      _bountyRewards[distributor].count++;
      _bountyRewards[distributor].claimed += distributorReward;
      distributor.sendValue(distributorReward);
    }
    
    emit DistributedRewards(
      distributor,
      soloStakingRewards,
      lpStakingRewards,
      distributorReward
    );
  }

  function distribute() external nonReentrant {
    _distribute(payable(_msgSender()), true);
  }

  function getSplitStakingRewardsForAddress(address account) external view returns (uint256 pending, uint256 claimed) {
    uint256 soloPending;
    uint256 soloClaimed;
    uint256 lpPending;
    uint256 lpClaimed;

    if (_soloStakingAddress != UNSET_ID)
      (,,soloPending,soloClaimed) = IStakingV1(_soloStakingAddress).getStakingDataForAccount(account);
    if (_lpStakingAddress != UNSET_ID)
      (,,lpPending,lpClaimed) = IStakingV1(_lpStakingAddress).getStakingDataForAccount(account);

    pending = soloPending + lpPending;
    claimed = _bountyRewards[account].claimed + soloClaimed + lpClaimed;
  }

  function _claimByAddress(address account, address address_, bool revertOnFailure, bool doAutoClaim) internal virtual {
    if (address_ != UNSET_ID)
      IStakingV1(address_).claimFor(account, revertOnFailure, doAutoClaim);
    else if (revertOnFailure)
      revert("Invalid id");
  }

  /** NOTE!!! this currently doesn't revert when there's nothing to do */
  function _claimSplitStaking(address account) internal virtual {
    _distribute(payable(account), false);
    _claimByAddress(account, _soloStakingAddress, false, false);
    _claimByAddress(account, _lpStakingAddress, false, false);
  }

  function claimSplitStaking() external nonReentrant {
    _claimSplitStaking(_msgSender());
  }

  function _depositEth(address account, uint256 amount) internal virtual onlyNotPaused {
    require(amount != 0, "Amount cannot be 0");
    require(_ready(), "Split staking is not ready");

    // subtract the incoming amount from the balance to get the old balance
    uint256 oldBalance = address(this).balance - amount;

    if (oldBalance == 0) {
      // if the balance was 0, we definitely have 0 cached rewards
      _cachedRewards = 0;
    } else {
      // cache the rewards before resetting _lastDistributionAt
      uint256 unclampedRewards = _getAvailableRewardsUnclamped();

      if (unclampedRewards > _minimumRewardsForDistribution || unclampedRewards > oldBalance) {
        // clamp rewards, and subtract the incoming amount
        _cachedRewards = _clampRewards(unclampedRewards, amount);
      } else {
        _cachedRewards = unclampedRewards;
      }
    }

    _lastActionAt = block.timestamp;
    _totalRewards += amount;

    emit DepositedEth(account, amount);
  }

  /**
   * @dev receive eth for split staking rewards
   */
  receive() external virtual payable nonReentrant {
    _depositEth(_msgSender(), msg.value);
  }
}
