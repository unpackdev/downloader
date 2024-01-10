// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./AggregatorV3Interface.sol";
import "./IChainLinkOracle.sol";

contract ChainLinkOracle is AccessControl, IChainLinkOracle {
  bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

  mapping(address => address) public availableTokens;

  event UpdateChainLinkOracleTokens(address, address);

  modifier onlyAdmin() {
    require(hasRole(ROLE_ADMIN, msg.sender), "Sender is not admin");
    _;
  }

  constructor(
    address _admin,
    address[] memory tokenAddresss,
    address[] memory dataFeedAddresses
  ) {
    require(_admin != address(0), "Admin cannot be zero address");
    _setupRole(ROLE_ADMIN, _admin);
    _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);
    for (uint256 i = 0; i < tokenAddresss.length; i++) {
      availableTokens[tokenAddresss[i]] = dataFeedAddresses[i];
    }
  }

  /**
   * @dev Get validity of chainlink token
   *
   * Params:
   * address tokenAddress
   */
  function getAvailableToken(address tokenAddress)
    external
    view
    override
    returns (address)
  {
    return availableTokens[tokenAddress];
  }

  /**
   * @dev Set valid chainlink token
   *
   * Params:
   * address tokenAddress
   * address dataFeedAddress
   */
  function setAvailableToken(address tokenAddress, address dataFeedAddress)
    external
    override
    onlyAdmin
  {
    availableTokens[tokenAddress] = dataFeedAddress;
    emit UpdateChainLinkOracleTokens(tokenAddress, dataFeedAddress);
  }

  /**
   * @dev Get validity chainlink tokens in batch
   *
   * Params:
   * address[] tokenAddresss
   */
  function getAvailableTokenBatch(address[] memory tokenAddresss)
    external
    view
    override
    returns (address[] memory)
  {
    address[] memory result = new address[](tokenAddresss.length);
    for (uint256 i = 0; i < tokenAddresss.length; i++) {
      result[i] = availableTokens[tokenAddresss[i]];
    }
    return result;
  }

  /**
   * @dev Set valid chainlink tokens in batch
   *
   * Params:
   * address[] tokenAddresss
   * address[] dataFeedAddresses
   */
  function setAvailableTokenBatch(
    address[] memory tokenAddresss,
    address[] memory dataFeedAddresses
  ) external override onlyAdmin {
    for (uint256 i = 0; i < tokenAddresss.length; i++) {
      availableTokens[tokenAddresss[i]] = dataFeedAddresses[i];
      emit UpdateChainLinkOracleTokens(tokenAddresss[i], dataFeedAddresses[i]);
    }
  }

  /**
   * @dev Get latest price of token from chainlink oracle
   *
   * Params:
   * address tokenAddresss
   *
   * Returns the latest price
   */
  function getLatestPrice(address tokenAddress)
    external
    view
    override
    returns (uint256)
  {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(
      availableTokens[tokenAddress]
    );
    (
      
      /*uint80 roundID*/,
      int256 price,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = 
      priceFeed.latestRoundData();
    return uint256(price);
  }

  function hasToken(address tokenAddress) public view override returns (bool) {
    return (availableTokens[tokenAddress] != address(0));
  }
}
