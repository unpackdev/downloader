//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./MathUpgradeable.sol";
import "./IApeNFT.sol";
import "./INFTDrip.sol";
import "./console.sol";

// Reward calculation is based on SNX pool

contract BabelGenesisDripImplementation is OwnableUpgradeable, INFTDrip{

  using MathUpgradeable for uint256;
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // Rewards are ERC20
  // If we want to distribute ERC721 / ERC1155 randomly, we could wrap them in
  // ERC20 form and distribute this way using NFT Indexing protocols
  struct Rewards {
    uint256 periodFinish;
    uint256 rewardRate;
    uint256 duration;
    uint256 lastUpdateTime;
    uint256 rewardPerTokenStored;
    mapping(address => uint256) userRewardPerTokenPaid;
    mapping(address => uint256) rewards;
  }

  address public stakingNFT;
  mapping (address => bool) public rewardDistribution;
  mapping (address => Rewards) public rewardInfos;
  address[] public rewardList;

  event RewardPayOut(address reward, uint256 amountGained, address to);
  event RewardAdded(address reward, uint256 amountAdded);
  event RewardsDurationUpdated(address targetReward, uint256 rewardsDuration);

  modifier onlyRewardDistribution() {
    require(rewardDistribution[msg.sender], "Not reward distribution");
    _;
  }

  constructor() {}

  function initialize(address _stakingNFT) public initializer {
    __Ownable_init();
    stakingNFT = _stakingNFT;
    rewardDistribution[msg.sender] = true;
  }

  // find the index of targetReward, if it doesn't exist in the list, return MAX_UINT
  function getTargetRewardIndex(address targetReward) public view returns (uint256) {
    for(uint256 i = 0 ; i < rewardList.length ; i ++) {
      if(rewardList[i] == targetReward) {
        return i;
      }
    }
    return uint256(-1);
  }

  /**
    Reward Distribution
  */

  function setRewardDistribution(address[] calldata _rewardDistributions, bool _flag) external onlyOwner {
    for(uint256 i = 0 ; i < _rewardDistributions.length; i++) {
      rewardDistribution[_rewardDistributions[i]] = _flag;
    }
  }

  function notifyTargetRewardAmount(address targetReward, uint256 reward) external onlyRewardDistribution {
    // https://sips.synthetix.io/sips/sip-77
    require(reward < uint(-1) / 1e18, "the notified reward cannot invoke multiplication overflow");

    uint256 index = getTargetRewardIndex(targetReward);
    require(index != uint256(-1), "rewardTokenIndex not found");

    Rewards storage rewardInfo = rewardInfos[targetReward];

    if (block.timestamp >= rewardInfo.periodFinish) {
      rewardInfo.rewardRate = reward.div(rewardInfo.duration);
    } else {
      uint256 remainingTime = rewardInfo.periodFinish.sub(block.timestamp);
      uint256 leftover = remainingTime.mul(rewardInfo.rewardRate);
      rewardInfo.rewardRate = reward.add(leftover).div(rewardInfo.duration);
    }
    rewardInfo.lastUpdateTime = block.timestamp;
    rewardInfo.periodFinish = block.timestamp.add(rewardInfo.duration);
    emit RewardAdded(targetReward, reward);
  }

  /*
      handling the original ERC20 functions
  */

  function totalSupply() public view returns(uint256) {
    return (IApeNFT(stakingNFT).totalSupply());
  }

  // This was a modifier in SNX pool, now it has been changed to a public function
  // to allow the NFT contract to call it
  function updateAllRewards(address targetAccount) public override {
    for(uint256 i = 0 ; i < rewardList.length; i++) {
      updateReward(rewardList[i], targetAccount);
    }
  }

  function updateReward(address targetReward, address targetAccount) public override {
    Rewards storage rewardInfo = rewardInfos[targetReward];

    rewardInfo.rewardPerTokenStored = rewardPerToken(targetReward);
    rewardInfo.lastUpdateTime = lastTimeRewardApplicable(targetReward);

    if(targetAccount != address(0)) {
      rewardInfo.rewards[targetAccount] = earned(targetReward, targetAccount);
      rewardInfo.userRewardPerTokenPaid[targetAccount] = rewardInfo.rewardPerTokenStored;
    }
  }

  /*
    Reward calculation
  */
  function lastTimeRewardApplicable(address targetReward) public view returns (uint256) {
    Rewards storage rewardInfo = rewardInfos[targetReward];
    return MathUpgradeable.min(block.timestamp, rewardInfo.periodFinish);
  }

  function rewardPerToken(address targetReward) public view returns (uint256) {
    Rewards storage rewardInfo = rewardInfos[targetReward];

    if (totalSupply() == 0) {
        return rewardInfo.rewardPerTokenStored;
    }
    return
      (rewardInfo.rewardPerTokenStored).add(
        lastTimeRewardApplicable(targetReward)
          .sub(rewardInfo.lastUpdateTime)
          .mul(rewardInfo.rewardRate)
          .mul(1e18)
          .div(totalSupply())
      );
  }

  function earned(address targetReward, address account) public view returns(uint256) {
    Rewards storage rewardInfo = rewardInfos[targetReward];
    return
        IApeNFT(stakingNFT).balanceOf(account)
          .mul(rewardPerToken(targetReward).sub(rewardInfo.userRewardPerTokenPaid[account]))
          .div(1e18)
          .add(rewardInfo.rewards[account]);
  }

  function claimAllRewards() public override {
    updateAllRewards(msg.sender);
    for(uint256 i = 0; i < rewardList.length; i++) {
      claimReward(rewardList[i]);
    }
  }

  function setRewardsDuration(address targetReward, uint256 _rewardsDuration) external onlyOwner {
    Rewards storage rewardInfo = rewardInfos[targetReward];
    require(
      block.timestamp > rewardInfo.periodFinish,
      "Previous rewards period must be complete before changing the duration for the new period"
    );
    rewardInfo.duration = _rewardsDuration;
    emit RewardsDurationUpdated(targetReward, rewardInfo.duration);
  }

  function claimReward(address targetReward) public {
    updateReward(targetReward, msg.sender);
    uint256 gained = earned(targetReward, msg.sender);
    Rewards storage rewardInfo = rewardInfos[targetReward];
    if(gained > 0 && IERC20Upgradeable(targetReward).balanceOf(address(this)) >= gained) {
      rewardInfo.rewards[msg.sender] = 0;
      IERC20Upgradeable(targetReward).safeTransfer(msg.sender, gained);
      emit RewardPayOut(targetReward, gained, msg.sender);
    }
  }

  function addReward(address targetReward, uint256 duration) external onlyOwner {
    require(getTargetRewardIndex(targetReward) == uint256(-1), "Token is already in the list");
    Rewards storage rewardInfo = rewardInfos[targetReward];
    rewardInfo.duration = duration;
    rewardList.push(targetReward);
  }

  function delReward(address targetReward) external onlyOwner {
    uint256 index = getTargetRewardIndex(targetReward);
    require(index != uint256(-1), "Cannot remove; Token not in list.");
    Rewards storage rewardInfo = rewardInfos[targetReward];
    require(rewardInfo.periodFinish < block.timestamp, "Cannot remove; distribution still active");
    require(rewardList.length > 1, "Cannot remove; last element.");
    uint256 last = rewardList.length - 1;
    rewardList[index] = rewardList[last];
    rewardList.pop();
  }

}