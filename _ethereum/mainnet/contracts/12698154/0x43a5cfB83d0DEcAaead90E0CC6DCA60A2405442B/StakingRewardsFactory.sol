// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

// Libraries
import "./SafeMath.sol";
import "./SafeERC20.sol";

// Interfaces
import "./IERC20.sol";

// Contracts
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./StakingRewards.sol";

contract StakingRewardsFactory is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  // immutables
  address public rewardsTokenDPX;
  address public rewardsTokenRDPX;
  uint256 public stakingRewardsGenesis;

  // the staking tokens for which the rewards contract has been deployed
  uint256[] public stakingID;

  // info about rewards for a particular staking token
  struct StakingRewardsInfo {
    address stakingRewards;
    uint256 rewardAmountDPX;
    uint256 rewardAmountRDPX;
    uint256 id;
  }

  // rewards info by staking token
  mapping(uint256 => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

  constructor(
    address _rewardsTokenDPX,
    address _rewardsTokenRDPX,
    uint256 _stakingRewardsGenesis
  ) Ownable() {
    require(
      _stakingRewardsGenesis >= block.timestamp,
      'StakingRewardsFactory::constructor: genesis too soon'
    );
    rewardsTokenDPX = _rewardsTokenDPX;
    rewardsTokenRDPX = _rewardsTokenRDPX;
    stakingRewardsGenesis = _stakingRewardsGenesis;
  }

  // deploy a staking reward contract for the staking token, and store the reward amount
  // the reward will be distributed to the staking reward contract no sooner than the genesis
  function deploy(
    address stakingToken,
    uint256 rewardAmountDPX,
    uint256 rewardAmountRDPX,
    uint256 rewardsDuration,
    uint256 boostedTimePeriod,
    uint256 boost,
    uint256 id
  ) public onlyOwner {
    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[id];
    require(info.id != id, 'StakingID already taken');
    require(rewardAmountDPX > 0, 'Invalid DPX reward amount');
    require(rewardAmountRDPX > 0, 'Invalid rDPX reward amount');
    info.stakingRewards = address(
      new StakingRewards(
        address(this),
        rewardsTokenDPX,
        rewardsTokenRDPX,
        stakingToken,
        rewardsDuration,
        boostedTimePeriod,
        boost,
        id
      )
    );
    info.rewardAmountDPX = rewardAmountDPX;
    info.rewardAmountRDPX = rewardAmountRDPX;
    info.id = id;
    stakingID.push(id);
  }

  // Withdraw tokens in case functions exceed gas cost
  function withdrawRewardToken(uint256 amountDPX, uint256 amountRDPX)
    public
    onlyOwner
    returns (uint256, uint256)
  {
    address OwnerAddress = owner();
    if (OwnerAddress == msg.sender) {
      IERC20(rewardsTokenDPX).transfer(OwnerAddress, amountDPX);
      IERC20(rewardsTokenRDPX).transfer(OwnerAddress, amountRDPX);
    }
    return (amountDPX, amountRDPX);
  }

  function withdrawRewardTokensFromContract(
    uint256 amountDPX,
    uint256 amountRDPX,
    uint256 id
  ) public onlyOwner {
    address OwnerAddress = owner();
    if (OwnerAddress == msg.sender) {
      StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[id];
      require(
        info.stakingRewards != address(0),
        'StakingRewardsFactory::notifyRewardAmount: not deployed'
      );
      StakingRewards(info.stakingRewards).withdrawRewardTokens(amountDPX, amountRDPX);
    }
  }

  // notify reward amount for an individual staking token.
  // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
  function notifyRewardAmount(uint256 id) public onlyOwner {
    require(
      block.timestamp >= stakingRewardsGenesis,
      'StakingRewardsFactory::notifyRewardAmount: not ready'
    );
    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[id];
    require(
      info.stakingRewards != address(0),
      'StakingRewardsFactory::notifyRewardAmount: not deployed'
    );
    require(info.rewardAmountDPX > 0, 'Reward amount must be greater than 0');
    uint256 rewardAmountDPX = 0;
    uint256 rewardAmountRDPX = 0;
    if (info.rewardAmountDPX > 0) {
      rewardAmountDPX = info.rewardAmountDPX;
      info.rewardAmountDPX = 0;
      require(
        IERC20(rewardsTokenDPX).transfer(info.stakingRewards, rewardAmountDPX),
        'StakingRewardsFactory::notifyRewardAmount: transfer failed'
      );
    }
    if (info.rewardAmountRDPX > 0) {
      rewardAmountRDPX = info.rewardAmountRDPX;
      info.rewardAmountRDPX = 0;
      require(
        IERC20(rewardsTokenRDPX).transfer(info.stakingRewards, rewardAmountRDPX),
        'StakingRewardsFactory::notifyRewardAmount: transfer failed'
      );
    }
    StakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmountDPX, rewardAmountRDPX);
  }

  ///// permissionless function

  // call notifyRewardAmount for all staking tokens.
  function notifyRewardAmounts() public onlyOwner {
    require(
      stakingID.length > 0,
      'StakingRewardsFactory::notifyRewardAmounts: called before any deploys'
    );
    for (uint256 i = 0; i < stakingID.length; i++) {
      notifyRewardAmount(stakingID[i]);
    }
  }
}
