// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;
import "./IIntegration.sol";

interface IStrategyMap {
  // #### Structs
  struct WeightedIntegration {
    address integration;
    uint256 weight;
  }

  struct Strategy {
    string name;
    uint256 totalStrategyWeight;
    mapping(address => bool) enabledTokens;
    address[] tokens;
    WeightedIntegration[] integrations;
  }

  struct StrategySummary {
    string name;
    uint256 totalStrategyWeight;
    address[] tokens;
    WeightedIntegration[] integrations;
  }

  struct StrategyTransaction {
    uint256 amount;
    address token;
  }

  // #### Events
  event NewStrategy(
    uint256 indexed id,
    string name,
    WeightedIntegration[] integrations,
    address[] tokens
  );
  event UpdateName(uint256 indexed id, string name);
  event UpdateIntegrations(
    uint256 indexed id,
    WeightedIntegration[] integrations
  );
  event UpdateTokens(uint256 indexed id, address[] tokens);
  event DeleteStrategy(
    uint256 indexed id,
    string name,
    address[] tokens,
    WeightedIntegration[] integrations
  );

  event EnterStrategy(
    uint256 indexed id,
    address indexed user,
    address[] tokens,
    uint256[] amounts
  );
  event ExitStrategy(
    uint256 indexed id,
    address indexed user,
    address[] tokens,
    uint256[] amounts
  );

  // #### Functions
  /**
     @notice Adds a new strategy to the list of available strategies
     @param name  the name of the new strategy
     @param integrations  the integrations and weights that form the strategy
     */
  function addStrategy(
    string calldata name,
    WeightedIntegration[] memory integrations,
    address[] calldata tokens
  ) external;

  /**
    @notice Updates the strategy name
    @param name  the new name
     */
  function updateName(uint256 id, string calldata name) external;

  /**
  @notice Updates a strategy's accepted tokens
  @param id  The strategy ID
  @param tokens  The new tokens to allow
  */
  function updateTokens(uint256 id, address[] calldata tokens) external;

  /**
    @notice Updates the strategy integrations 
    @param integrations  the new integrations
     */
  function updateIntegrations(
    uint256 id,
    WeightedIntegration[] memory integrations
  ) external;

  /**
    @notice Deletes a strategy
    @dev This can only be called successfully if the strategy being deleted doesn't have any assets invested in it
    @param id  the strategy to delete
     */
  function deleteStrategy(uint256 id) external;

  /**
    @notice Increases the amount of a set of tokens in a strategy
    @param id  the strategy to deposit into
    @param tokens  the tokens to deposit
    @param amounts  The amounts to be deposited
     */
  function enterStrategy(
    uint256 id,
    address user,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external;

  /**
    @notice Decreases the amount of a set of tokens invested in a strategy
    @param id  the strategy to withdraw assets from
    @param tokens  the tokens to withdraw
    @param amounts  The amounts to be withdrawn
     */
  function exitStrategy(
    uint256 id,
    address user,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external;

  /**
    @notice Getter function to return the nested arrays as well as the name
    @param id  the strategy to return
     */
  function getStrategy(uint256 id)
    external
    view
    returns (StrategySummary memory);

  /**
    @notice Returns the expected balance of a given token in a given integration
    @param integration  the integration the amount should be invested in
    @param token  the token that is being invested
    @return balance  the balance of the token that should be currently invested in the integration 
     */
  function getExpectedBalance(address integration, address token)
    external
    view
    returns (uint256 balance);

  /**
    @notice Returns the amount of a given token currently invested in a strategy
    @param id  the strategy id to check
    @param token  The token to retrieve the balance for
    @return amount  the amount of token that is invested in the strategy
     */
  function getStrategyTokenBalance(uint256 id, address token)
    external
    view
    returns (uint256 amount);

  /**
    @notice returns the amount of a given token a user has invested in a given strategy
    @param id  the strategy id
    @param token  the token address
    @param user  the user who holds the funds
    @return amount  the amount of token that the user has invested in the strategy 
     */
  function getUserStrategyBalanceByToken(
    uint256 id,
    address token,
    address user
  ) external view returns (uint256 amount);

  /**
    @notice Returns the amount of a given token that a user has invested across all strategies
    @param token  the token address
    @param user  the user holding the funds
    @return amount  the amount of tokens the user has invested across all strategies
     */
  function getUserInvestedAmountByToken(address token, address user)
    external
    view
    returns (uint256 amount);

  /**
    @notice Returns the total amount of a token invested across all strategies
    @param token  the token to fetch the balance for
    @return amount  the amount of the token currently invested
    */
  function getTokenTotalBalance(address token)
    external
    view
    returns (uint256 amount);

  /**
  @notice Returns the weight of an individual integration within the system
  @param integration  the integration to look up
  @return The weight of the integration
   */
  function getIntegrationWeight(address integration)
    external
    view
    returns (uint256);

  /**
  @notice Returns the sum of all weights in the system.
  @return The sum of all integration weights within the system
   */
  function getIntegrationWeightSum() external view returns (uint256);

  /// @notice autogenerated getter definition
  function idCounter() external view returns(uint256);
}
