// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ModuleMapConsumer.sol";
import "./Controlled.sol";
import "./IIntegrationMap.sol";
import "./console.sol";

contract IntegrationMap is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  IIntegrationMap
{
  uint32 private constant RESERVE_RATIO_DENOMINATOR = 1_000_000;
  address private wethTokenAddress;
  address private biosTokenAddress;
  address[] private tokenAddresses;
  address[] private integrationAddresses;

  // Integration address => Integration details
  mapping(address => Integration) private integrations;
  // Token address => Token details
  mapping(address => Token) private tokens;

  function initialize(
    address[] memory controllers_,
    address moduleMap_,
    address wethTokenAddress_,
    address biosTokenAddress_
  ) public initializer {
    __Controlled_init(controllers_, moduleMap_);
    wethTokenAddress = wethTokenAddress_;
    biosTokenAddress = biosTokenAddress_;

    _addToken(wethTokenAddress_, true, true, 1000, 50000);
    _addToken(biosTokenAddress_, true, true, 1000, 0);
  }

  /// @param contractAddress The address of the integration contract
  /// @param name The name of the protocol being integrated to
  function addIntegration(address contractAddress, string memory name)
    external
    override
    onlyController
  {
    require(
      !integrations[contractAddress].added,
      "IntegrationMap::addIntegration: Integration already added"
    );
    integrations[contractAddress].added = true;
    integrations[contractAddress].name = name;
    integrationAddresses.push(contractAddress);
  }

  /// @param tokenAddress The address of the ERC20 token contract
  /// @param acceptingDeposits Whether token deposits are enabled
  /// @param acceptingWithdrawals Whether token withdrawals are enabled
  /// @param biosRewardWeight Token weight for BIOS rewards
  /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
  function _addToken(
    address tokenAddress,
    bool acceptingDeposits,
    bool acceptingWithdrawals,
    uint256 biosRewardWeight,
    uint256 reserveRatioNumerator
  ) internal {
    require(
      !tokens[tokenAddress].added,
      "IntegrationMap::addToken: Token already added"
    );
    require(
      reserveRatioNumerator <= RESERVE_RATIO_DENOMINATOR,
      "IntegrationMap::addToken: reserveRatioNumerator must be less than or equal to reserve ratio denominator"
    );

    tokens[tokenAddress].id = tokenAddresses.length;
    tokens[tokenAddress].added = true;
    tokens[tokenAddress].acceptingDeposits = acceptingDeposits;
    tokens[tokenAddress].acceptingWithdrawals = acceptingWithdrawals;
    tokens[tokenAddress].biosRewardWeight = biosRewardWeight;
    tokens[tokenAddress].reserveRatioNumerator = reserveRatioNumerator;
    tokenAddresses.push(tokenAddress);
  }

  /// @param tokenAddress The address of the ERC20 token contract
  /// @param acceptingDeposits Whether token deposits are enabled
  /// @param acceptingWithdrawals Whether token withdrawals are enabled
  /// @param biosRewardWeight Token weight for BIOS rewards
  /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio

  function addToken(
    address tokenAddress,
    bool acceptingDeposits,
    bool acceptingWithdrawals,
    uint256 biosRewardWeight,
    uint256 reserveRatioNumerator
  ) external override onlyController {
    _addToken(
      tokenAddress,
      acceptingDeposits,
      acceptingWithdrawals,
      biosRewardWeight,
      reserveRatioNumerator
    );
  }

  /// @param tokenAddress The address of the token ERC20 contract
  function enableTokenDeposits(address tokenAddress)
    external
    override
    onlyController
  {
    require(
      tokens[tokenAddress].added,
      "IntegrationMap::enableTokenDeposits: Token does not exist"
    );
    require(
      !tokens[tokenAddress].acceptingDeposits,
      "IntegrationMap::enableTokenDeposits: Token already accepting deposits"
    );

    tokens[tokenAddress].acceptingDeposits = true;
  }

  /// @param tokenAddress The address of the token ERC20 contract
  function disableTokenDeposits(address tokenAddress)
    external
    override
    onlyController
  {
    require(
      tokens[tokenAddress].added,
      "IntegrationMap::disableTokenDeposits: Token does not exist"
    );
    require(
      tokens[tokenAddress].acceptingDeposits,
      "IntegrationMap::disableTokenDeposits: Token deposits already disabled"
    );

    tokens[tokenAddress].acceptingDeposits = false;
  }

  /// @param tokenAddress The address of the token ERC20 contract
  function enableTokenWithdrawals(address tokenAddress)
    external
    override
    onlyController
  {
    require(
      tokens[tokenAddress].added,
      "IntegrationMap::enableTokenWithdrawals: Token does not exist"
    );
    require(
      !tokens[tokenAddress].acceptingWithdrawals,
      "IntegrationMap::enableTokenWithdrawals: Token already accepting withdrawals"
    );

    tokens[tokenAddress].acceptingWithdrawals = true;
  }

  /// @param tokenAddress The address of the token ERC20 contract
  function disableTokenWithdrawals(address tokenAddress)
    external
    override
    onlyController
  {
    require(
      tokens[tokenAddress].added,
      "IntegrationMap::disableTokenWithdrawals: Token does not exist"
    );
    require(
      tokens[tokenAddress].acceptingWithdrawals,
      "IntegrationMap::disableTokenWithdrawals: Token withdrawals already disabled"
    );

    tokens[tokenAddress].acceptingWithdrawals = false;
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @param rewardWeight The updated token BIOS reward weight
  function updateTokenRewardWeight(address tokenAddress, uint256 rewardWeight)
    external
    override
    onlyController
  {
    require(
      tokens[tokenAddress].added,
      "IntegrationMap::updateTokenRewardWeight: Token does not exist"
    );
    // require(
    //   tokens[tokenAddress].biosRewardWeight != rewardWeight,
    //   "IntegrationMap::updateTokenRewardWeight: Updated weight must not equal current weight"
    // );

    tokens[tokenAddress].biosRewardWeight = rewardWeight;
  }

  /// @param tokenAddress the address of the token ERC20 contract
  /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
  function updateTokenReserveRatioNumerator(
    address tokenAddress,
    uint256 reserveRatioNumerator
  ) external override onlyController {
    require(
      tokens[tokenAddress].added,
      "IntegrationMap::updateTokenReserveRatioNumerator: Token does not exist"
    );
    require(
      reserveRatioNumerator <= RESERVE_RATIO_DENOMINATOR,
      "IntegrationMap::addToken: reserveRatioNumerator must be less than or equal to reserve ratio denominator"
    );

    tokens[tokenAddress].reserveRatioNumerator = reserveRatioNumerator;
  }

  /// @param integrationId The ID of the integration
  /// @return The address of the integration contract
  function getIntegrationAddress(uint256 integrationId)
    external
    view
    override
    returns (address)
  {
    require(
      integrationId < integrationAddresses.length,
      "IntegrationMap::getIntegrationAddress: Integration does not exist"
    );

    return integrationAddresses[integrationId];
  }

  /// @param integrationAddress The address of the integration contract
  /// @return The name of the of the protocol being integrated to
  function getIntegrationName(address integrationAddress)
    external
    view
    override
    returns (string memory)
  {
    require(
      integrations[integrationAddress].added,
      "IntegrationMap::getIntegrationName: Integration does not exist"
    );

    return integrations[integrationAddress].name;
  }

  /// @return The address of the WETH token
  function getWethTokenAddress() external view override returns (address) {
    return wethTokenAddress;
  }

  /// @return The address of the BIOS token
  function getBiosTokenAddress() external view override returns (address) {
    return biosTokenAddress;
  }

  /// @param tokenId The ID of the token
  /// @return The address of the token ERC20 contract
  function getTokenAddress(uint256 tokenId)
    external
    view
    override
    returns (address)
  {
    require(
      tokenId < tokenAddresses.length,
      "IntegrationMap::getTokenAddress: Token does not exist"
    );
    return (tokenAddresses[tokenId]);
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @return The index of the token in the tokens array
  function getTokenId(address tokenAddress)
    external
    view
    override
    returns (uint256)
  {
    require(
      tokens[tokenAddress].added,
      "IntegrationMap::getTokenId: Token does not exist"
    );
    return (tokens[tokenAddress].id);
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @return The token BIOS reward weight
  function getTokenBiosRewardWeight(address tokenAddress)
    external
    view
    override
    returns (uint256)
  {
    require(
      tokens[tokenAddress].added,
      "IntegrationMap::getTokenBiosRewardWeight: Token does not exist"
    );
    return (tokens[tokenAddress].biosRewardWeight);
  }

  /// @return rewardWeightSum reward weight of depositable tokens
  function getBiosRewardWeightSum()
    external
    view
    override
    returns (uint256 rewardWeightSum)
  {
    for (uint256 tokenId; tokenId < tokenAddresses.length; tokenId++) {
      rewardWeightSum += tokens[tokenAddresses[tokenId]].biosRewardWeight;
    }
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @return bool indicating whether depositing this token is currently enabled
  function getTokenAcceptingDeposits(address tokenAddress)
    external
    view
    override
    returns (bool)
  {
    require(
      tokens[tokenAddress].added,
      "IntegrationMap::getTokenAcceptingDeposits: Token does not exist"
    );
    return tokens[tokenAddress].acceptingDeposits;
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @return bool indicating whether withdrawing this token is currently enabled
  function getTokenAcceptingWithdrawals(address tokenAddress)
    external
    view
    override
    returns (bool)
  {
    require(
      tokens[tokenAddress].added,
      "IntegrationMap::getTokenAcceptingWithdrawals: Token does not exist"
    );
    return tokens[tokenAddress].acceptingWithdrawals;
  }

  // @param tokenAddress The address of the token ERC20 contract
  // @return bool indicating whether the token has been added
  function getIsTokenAdded(address tokenAddress)
    external
    view
    override
    returns (bool)
  {
    return tokens[tokenAddress].added;
  }

  // @param integrationAddress The address of the integration contract
  // @return bool indicating whether the integration has been added
  function getIsIntegrationAdded(address integrationAddress)
    external
    view
    override
    returns (bool)
  {
    return integrations[integrationAddress].added;
  }

  /// @notice Gets the length of supported tokens
  /// @return The quantity of tokens added
  function getTokenAddressesLength() external view override returns (uint256) {
    return tokenAddresses.length;
  }

  /// @notice Gets the length of supported integrations
  /// @return The quantity of Integrations added
  function getIntegrationAddressesLength()
    external
    view
    override
    returns (uint256)
  {
    return integrationAddresses.length;
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @return The token reserve ratio numerator
  function getTokenReserveRatioNumerator(address tokenAddress)
    external
    view
    override
    returns (uint256)
  {
    require(
      tokens[tokenAddress].added,
      "IntegrationMap::getTokenReserveRatioNumerator: Token does not exist"
    );
    return tokens[tokenAddress].reserveRatioNumerator;
  }

  /// @return The token reserve ratio denominator
  function getReserveRatioDenominator()
    external
    pure
    override
    returns (uint32)
  {
    return RESERVE_RATIO_DENOMINATOR;
  }
}
