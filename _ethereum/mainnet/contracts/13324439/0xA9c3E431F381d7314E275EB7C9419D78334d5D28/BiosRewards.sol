// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./MathUpgradeable.sol";
import "./IBiosRewards.sol";
import "./IUserPositions.sol";
import "./IIntegrationMap.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";

contract BiosRewards is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  IBiosRewards
{
  uint256 private totalBiosRewards;
  uint256 private totalClaimedBiosRewards;
  mapping(address => uint256) private totalUserClaimedBiosRewards;
  mapping(address => uint256) public periodFinish;
  mapping(address => uint256) public rewardRate;
  mapping(address => uint256) public lastUpdateTime;
  mapping(address => uint256) public rewardPerTokenStored;
  mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
  mapping(address => mapping(address => uint256)) public rewards;

  event RewardAdded(address indexed token, uint256 reward, uint32 duration);

  function initialize(address[] memory controllers_, address moduleMap_)
    public
    initializer
  {
    __Controlled_init(controllers_, moduleMap_);
    __ModuleMapConsumer_init(moduleMap_);
  }

  modifier updateReward(address token, address account) {
    rewardPerTokenStored[token] = rewardPerToken(token);
    lastUpdateTime[token] = lastTimeRewardApplicable(token);
    if (account != address(0)) {
      rewards[token][account] = earned(token, account);
      userRewardPerTokenPaid[token][account] = rewardPerTokenStored[token];
    }
    _;
  }

  /// @param token The address of the ERC20 token contract
  /// @param reward The updated reward amount
  /// @param duration The duration of the rewards period
  function notifyRewardAmount(
    address token,
    uint256 reward,
    uint32 duration
  ) external override onlyController updateReward(token, address(0)) {
    if (block.timestamp >= periodFinish[token]) {
      rewardRate[token] = reward / duration;
    } else {
      uint256 remaining = periodFinish[token] - block.timestamp;
      uint256 leftover = remaining * rewardRate[token];
      rewardRate[token] = (reward + leftover) / duration;
    }
    lastUpdateTime[token] = block.timestamp;
    periodFinish[token] = block.timestamp + duration;
    totalBiosRewards += reward;
    emit RewardAdded(token, reward, duration);
  }

  function increaseRewards(
    address token,
    address account,
    uint256 amount
  ) public override onlyController updateReward(token, account) {
    require(amount > 0, "BiosRewards::increaseRewards: Cannot increase 0");
  }

  function decreaseRewards(
    address token,
    address account,
    uint256 amount
  ) public override onlyController updateReward(token, account) {
    require(amount > 0, "BiosRewards::decreaseRewards: Cannot decrease 0");
  }

  function claimReward(address token, address account)
    public
    override
    onlyController
    updateReward(token, account)
    returns (uint256 reward)
  {
    reward = earned(token, account);
    if (reward > 0) {
      rewards[token][account] = 0;
      totalBiosRewards -= reward;
      totalClaimedBiosRewards += reward;
      totalUserClaimedBiosRewards[account] += reward;
    }
    return reward;
  }

  function lastTimeRewardApplicable(address token)
    public
    view
    override
    returns (uint256)
  {
    return MathUpgradeable.min(block.timestamp, periodFinish[token]);
  }

  function rewardPerToken(address token)
    public
    view
    override
    returns (uint256)
  {
    uint256 totalSupply = IUserPositions(
      moduleMap.getModuleAddress(Modules.UserPositions)
    ).totalTokenBalance(token);
    if (totalSupply == 0) {
      return rewardPerTokenStored[token];
    }
    return
      rewardPerTokenStored[token] +
      (((lastTimeRewardApplicable(token) - lastUpdateTime[token]) *
        rewardRate[token] *
        1e18) / totalSupply);
  }

  function earned(address token, address account)
    public
    view
    override
    returns (uint256)
  {
    IUserPositions userPositions = IUserPositions(
      moduleMap.getModuleAddress(Modules.UserPositions)
    );
    return
      ((userPositions.userTokenBalance(token, account) *
        (rewardPerToken(token) - userRewardPerTokenPaid[token][account])) /
        1e18) + rewards[token][account];
  }

  function getUserBiosRewards(address account)
    external
    view
    override
    returns (uint256 userBiosRewards)
  {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );

    for (
      uint256 tokenId;
      tokenId < integrationMap.getTokenAddressesLength();
      tokenId++
    ) {
      userBiosRewards += earned(
        integrationMap.getTokenAddress(tokenId),
        account
      );
    }
  }

  function getTotalClaimedBiosRewards()
    external
    view
    override
    returns (uint256)
  {
    return totalClaimedBiosRewards;
  }

  function getTotalUserClaimedBiosRewards(address account)
    external
    view
    override
    returns (uint256)
  {
    return totalUserClaimedBiosRewards[account];
  }

  function getBiosRewards() external view override returns (uint256) {
    return totalBiosRewards;
  }
}
