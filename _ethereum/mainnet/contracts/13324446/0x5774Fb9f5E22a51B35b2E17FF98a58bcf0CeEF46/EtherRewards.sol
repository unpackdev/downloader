// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./IEtherRewards.sol";
import "./IIntegrationMap.sol";
import "./IStrategyMap.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";

contract EtherRewards is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  IEtherRewards
{
  /// @param controllers_ The array of controllers for this contract
  /// @param moduleMap_ The address of the ModuleMap contract
  function initialize(address[] memory controllers_, address moduleMap_)
    public
    initializer
  {
    __Controlled_init(controllers_, moduleMap_);
    __ModuleMapConsumer_init(moduleMap_);
  }

  uint256 private totalEthRewards;
  uint256 private totalClaimedEthRewards;
  mapping(address => uint256) private totalUserClaimedEthRewards;
  mapping(address => uint256) private tokenRewardRate;
  mapping(address => uint256) private tokenEthRewards;
  mapping(address => mapping(address => uint256)) private userTokenRewardRate;
  mapping(address => mapping(address => uint256))
    private userTokenAccumulatedRewards;

  /// @param token The address of the token ERC20 contract
  /// @param user The address of the user
  function updateUserRewards(address token, address user)
    public
    override
    onlyController
  {
    uint256 userTokenDeposits = IStrategyMap(
      moduleMap.getModuleAddress(Modules.StrategyMap)
    ).getUserInvestedAmountByToken(token, user);

    userTokenAccumulatedRewards[token][user] +=
      ((tokenRewardRate[token] - userTokenRewardRate[token][user]) *
        userTokenDeposits) /
      10**18;

    userTokenRewardRate[token][user] = tokenRewardRate[token];
  }

  /// @param token The address of the token ERC20 contract
  /// @param ethRewardsAmount The amount of Ether rewards to add
  function increaseEthRewards(address token, uint256 ethRewardsAmount)
    external
    override
    onlyController
  {
    uint256 tokenTotalDeposits = IStrategyMap(
      moduleMap.getModuleAddress(Modules.StrategyMap)
    ).getTokenTotalBalance(token);
    require(
      tokenTotalDeposits > 0,
      "EtherRewards::increaseEthRewards: Token has not been deposited yet"
    );

    totalEthRewards += ethRewardsAmount;
    tokenEthRewards[token] += ethRewardsAmount;
    tokenRewardRate[token] += (ethRewardsAmount * 10**18) / tokenTotalDeposits;
  }

  /// @param user The address of the user
  /// @return ethRewards The amount of Ether claimed
  function claimEthRewards(address user)
    external
    override
    onlyController
    returns (uint256 ethRewards)
  {
    address integrationMap = moduleMap.getModuleAddress(Modules.IntegrationMap);
    uint256 tokenCount = IIntegrationMap(integrationMap)
      .getTokenAddressesLength();

    for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
      address token = IIntegrationMap(integrationMap).getTokenAddress(tokenId);
      ethRewards += claimTokenEthRewards(token, user);
    }
  }

  /// @param token The address of the token ERC20 contract
  /// @param user The address of the user
  /// @return ethRewards The amount of Ether claimed
  function claimTokenEthRewards(address token, address user)
    private
    returns (uint256 ethRewards)
  {
    updateUserRewards(token, user);
    ethRewards = userTokenAccumulatedRewards[token][user];

    userTokenAccumulatedRewards[token][user] = 0;
    tokenEthRewards[token] -= ethRewards;
    totalEthRewards -= ethRewards;
    totalClaimedEthRewards += ethRewards;
    totalUserClaimedEthRewards[user] += ethRewards;
  }

  /// @param token The address of the token ERC20 contract
  /// @param user The address of the user
  /// @return ethRewards The amount of Ether claimed
  function getUserTokenEthRewards(address token, address user)
    public
    view
    override
    returns (uint256 ethRewards)
  {
    uint256 userTokenDeposits = IStrategyMap(
      moduleMap.getModuleAddress(Modules.StrategyMap)
    ).getUserInvestedAmountByToken(token, user);

    ethRewards =
      userTokenAccumulatedRewards[token][user] +
      ((tokenRewardRate[token] - userTokenRewardRate[token][user]) *
        userTokenDeposits) /
      10**18;
  }

  /// @param user The address of the user
  /// @return ethRewards The amount of Ether claimed
  function getUserEthRewards(address user)
    external
    view
    override
    returns (uint256 ethRewards)
  {
    address integrationMap = moduleMap.getModuleAddress(Modules.IntegrationMap);
    uint256 tokenCount = IIntegrationMap(integrationMap)
      .getTokenAddressesLength();

    for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
      address token = IIntegrationMap(integrationMap).getTokenAddress(tokenId);
      ethRewards += getUserTokenEthRewards(token, user);
    }
  }

  /// @param token The address of the token ERC20 contract
  /// @return The amount of Ether rewards for the specified token
  function getTokenEthRewards(address token)
    external
    view
    override
    returns (uint256)
  {
    return tokenEthRewards[token];
  }

  /// @return The total value of ETH claimed by users
  function getTotalClaimedEthRewards()
    external
    view
    override
    returns (uint256)
  {
    return totalClaimedEthRewards;
  }

  /// @return The total value of ETH claimed by a user
  function getTotalUserClaimedEthRewards(address account)
    external
    view
    override
    returns (uint256)
  {
    return totalUserClaimedEthRewards[account];
  }

  /// @return The total amount of Ether rewards
  function getEthRewards() external view override returns (uint256) {
    return totalEthRewards;
  }
}
