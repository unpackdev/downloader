// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ModuleMapConsumer.sol";
import "./Controlled.sol";
import "./IStrategyMap.sol";
import "./IIntegrationMap.sol";
import "./IUserPositions.sol";
import "./IYieldManager.sol";

contract StrategyMap is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  IStrategyMap
{
  // #### Global State
  // Strategy id => Strategy
  mapping(uint256 => Strategy) internal strategies;

  // Strategy => token => balance
  mapping(uint256 => mapping(address => uint256)) internal strategyBalances;

  // User => strategy => token => balance
  mapping(address => mapping(uint256 => mapping(address => uint256)))
    internal userStrategyBalances;

  // User => token => balance
  mapping(address => mapping(address => uint256)) internal userInvestedBalances;

  // Token => balance
  mapping(address => uint256) internal totalBalances;

  // Integration => token => gross balance inclusive of reserve amount
  mapping(address => mapping(address => uint256)) internal integrationBalances;

  // Integration => weight
  mapping(address => uint256) internal integrationWeights;
  uint256 internal totalSystemWeight;

  uint256 public override idCounter;

  // #### Functions
  function initialize(address[] memory controllers_, address moduleMap_)
    public
    initializer
  {
    __Controlled_init(controllers_, moduleMap_);
  }

  function addStrategy(
    string calldata name,
    WeightedIntegration[] memory integrations,
    address[] calldata tokens
  ) external override onlyController {
    require(bytes(name).length > 0, "Must have a name");
    require(integrations.length > 0, "Must have >= 1 integration");
    require(tokens.length > 0, "Must have tokens");

    idCounter++;
    uint256 strategyID = idCounter;
    strategies[strategyID].name = name;
    

    for (uint256 i = 0; i < tokens.length; i++) {
      strategies[strategyID].enabledTokens[tokens[i]] = true;
      strategies[strategyID].tokens.push(tokens[i]);
    }

    uint256 totalStrategyWeight = 0;
    uint256 _systemWeight = totalSystemWeight;
    for (uint256 i = 0; i < integrations.length; i++) {
      if (integrations[i].weight > 0) {
        _systemWeight += integrations[i].weight;
        integrationWeights[integrations[i].integration] += integrations[i]
          .weight;
        strategies[strategyID].integrations.push(integrations[i]);
        totalStrategyWeight += integrations[i].weight;
      }
    }
    totalSystemWeight = _systemWeight;
    strategies[strategyID].totalStrategyWeight = totalStrategyWeight;

    emit NewStrategy(strategyID, name, integrations, tokens);
  }

  function updateName(uint256 id, string calldata name)
    external
    override
    onlyController
  {
    require(bytes(name).length > 0, "Must have a name");
    require(
      strategies[id].integrations.length > 0 &&
        bytes(strategies[id].name).length > 0,
      "Strategy must exist"
    );
    strategies[id].name = name;
    emit UpdateName(id, name);
  }

  function updateTokens(uint256 id, address[] calldata tokens)
    external
    override
    onlyController
  {
    address[] memory oldTokens = strategies[id].tokens;
    for (uint256 i; i < oldTokens.length; i++) {
      strategies[id].enabledTokens[oldTokens[i]] = false;
    }
    for (uint256 i; i < tokens.length; i++) {
      strategies[id].enabledTokens[tokens[i]] = true;
    }
    delete strategies[id].tokens;
    strategies[id].tokens = tokens;
    emit UpdateTokens(id, tokens);
  }

  function updateIntegrations(
    uint256 id,
    WeightedIntegration[] memory integrations
  ) external override onlyController {
    StrategySummary memory currentStrategy = _getStrategySummary(id);
    require(
      currentStrategy.integrations.length > 0 &&
        bytes(currentStrategy.name).length > 0,
      "Strategy must exist"
    );

    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    WeightedIntegration[] memory currentIntegrations = strategies[id]
      .integrations;

    uint256 tokenCount = integrationMap.getTokenAddressesLength();

    uint256 _systemWeight = totalSystemWeight;
    for (uint256 i = 0; i < currentIntegrations.length; i++) {
      _systemWeight -= currentIntegrations[i].weight;
      integrationWeights[
        currentIntegrations[i].integration
      ] -= currentIntegrations[i].weight;
    }
    delete strategies[id].integrations;

    uint256 newStrategyTotalWeight;
    for (uint256 i = 0; i < integrations.length; i++) {
      if (integrations[i].weight > 0) {
        newStrategyTotalWeight += integrations[i].weight;
        strategies[id].integrations.push(integrations[i]);
        _systemWeight += integrations[i].weight;
        integrationWeights[integrations[i].integration] += integrations[i]
          .weight;
      }
    }

    totalSystemWeight = _systemWeight;
    strategies[id].totalStrategyWeight = newStrategyTotalWeight;

    for (uint256 i = 0; i < tokenCount; i++) {
      address token = integrationMap.getTokenAddress(i);
      if (strategyBalances[id][token] > 0) {
        for (uint256 j = 0; j < currentIntegrations.length; j++) {
          // Remove token amounts from integration balances

          integrationBalances[currentIntegrations[j].integration][
            token
          ] -= _calculateIntegrationAllocation(
            strategyBalances[id][token],
            currentIntegrations[j].weight,
            currentStrategy.totalStrategyWeight
          );
        }
        for (uint256 j = 0; j < integrations.length; j++) {
          if (integrations[j].weight > 0) {
            // Add new token balances
            integrationBalances[integrations[j].integration][
              token
            ] += _calculateIntegrationAllocation(
              strategyBalances[id][token],
              integrations[j].weight,
              newStrategyTotalWeight
            );
          }
        }
      }
    }

    emit UpdateIntegrations(id, integrations);
  }

  function deleteStrategy(uint256 id) external override onlyController {
    StrategySummary memory currentStrategy = _getStrategySummary(id);
    // Checks
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    uint256 tokenCount = integrationMap.getTokenAddressesLength();

    for (uint256 i = 0; i < tokenCount; i++) {
      require(
        getStrategyTokenBalance(id, integrationMap.getTokenAddress(i)) == 0,
        "Strategy in use"
      );
    }
    uint256 _systemWeight = totalSystemWeight;
    for (uint256 i = 0; i < currentStrategy.integrations.length; i++) {
      _systemWeight -= currentStrategy.integrations[i].weight;
      integrationWeights[
        currentStrategy.integrations[i].integration
      ] -= currentStrategy.integrations[i].weight;
    }
    totalSystemWeight = _systemWeight;

    delete strategies[id];

    emit DeleteStrategy(
      id,
      currentStrategy.name,
      currentStrategy.tokens,
      currentStrategy.integrations
    );
  }

  function _deposit(
    uint256 id,
    address user,
    StrategyTransaction memory deposits
  ) internal {
    StrategySummary memory strategy = _getStrategySummary(id);
    require(strategy.integrations.length > 0, "Strategy doesn't exist");

    strategyBalances[id][deposits.token] += deposits.amount;
    userInvestedBalances[user][deposits.token] += deposits.amount;
    userStrategyBalances[user][id][deposits.token] += deposits.amount;
    totalBalances[deposits.token] += deposits.amount;

    for (uint256 j = 0; j < strategy.integrations.length; j++) {
      integrationBalances[strategy.integrations[j].integration][
        deposits.token
      ] += _calculateIntegrationAllocation(
        deposits.amount,
        strategy.integrations[j].weight,
        strategy.totalStrategyWeight
      );
    }
  }

  function _withdraw(
    uint256 id,
    address user,
    StrategyTransaction memory withdrawals
  ) internal {
    StrategySummary memory strategy = _getStrategySummary(id);
    require(strategy.integrations.length > 0, "Strategy doesn't exist");

    strategyBalances[id][withdrawals.token] -= withdrawals.amount;
    userInvestedBalances[user][withdrawals.token] -= withdrawals.amount;
    userStrategyBalances[user][id][withdrawals.token] -= withdrawals.amount;
    totalBalances[withdrawals.token] -= withdrawals.amount;

    for (uint256 j = 0; j < strategy.integrations.length; j++) {
      integrationBalances[strategy.integrations[j].integration][
        withdrawals.token
      ] -= _calculateIntegrationAllocation(
        withdrawals.amount,
        strategy.integrations[j].weight,
        strategy.totalStrategyWeight
      );
    }
  }

  function enterStrategy(
    uint256 id,
    address user,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external override onlyController {
    require(amounts.length == tokens.length, "Length mismatch");
    require(strategies[id].integrations.length > 0, "Strategy must exist");
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );

    IUserPositions userPositions = IUserPositions(
      moduleMap.getModuleAddress(Modules.UserPositions)
    );
    for (uint256 i = 0; i < tokens.length; i++) {
      require(amounts[i] > 0, "Amount is 0");
      require(strategies[id].enabledTokens[tokens[i]], "Invalid token");
      require(
        integrationMap.getTokenAcceptingDeposits(tokens[i]),
        "Token unavailable"
      );

      // Check that a user has enough funds on deposit
      require(
        userPositions.userTokenBalance(tokens[i], user) >= amounts[i],
        "User lacks funds"
      );
      _deposit(
        id,
        user,
        IStrategyMap.StrategyTransaction(amounts[i], tokens[i])
      );
    }

    emit EnterStrategy(id, user, tokens, amounts);
  }

  function exitStrategy(
    uint256 id,
    address user,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external override onlyController {
    require(amounts.length == tokens.length, "Length mismatch");
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );

    for (uint256 i = 0; i < tokens.length; i++) {
      require(
        getUserInvestedAmountByToken(tokens[i], user) >= amounts[i],
        "Insufficient Funds"
      );

      require(
        integrationMap.getTokenAcceptingWithdrawals(tokens[i]),
        "Token unavailable"
      );
      require(amounts[i] > 0, "Amount is 0");

      _withdraw(
        id,
        user,
        IStrategyMap.StrategyTransaction(amounts[i], tokens[i])
      );
    }

    emit ExitStrategy(id, user, tokens, amounts);
  }

  /**
    @notice Calculates the amount of tokens to adjust an integration's expected invested amount by
    @param totalDepositedAmount  the total amount a user is depositing or withdrawing from a strategy
    @param integrationWeight  the weight of the integration as part of the strategy
    @param strategyWeight  the sum of all weights in the strategy
    @return amount  the amount to adjust the integration balance by
     */
  function _calculateIntegrationAllocation(
    uint256 totalDepositedAmount,
    uint256 integrationWeight,
    uint256 strategyWeight
  ) internal pure returns (uint256 amount) {
    return (totalDepositedAmount * integrationWeight) / strategyWeight;
  }

  function _getStrategySummary(uint256 id)
    internal
    view
    returns (StrategySummary memory)
  {
    StrategySummary memory result;
    result.integrations = strategies[id].integrations;
    result.name = strategies[id].name;
    result.tokens = strategies[id].tokens;
    result.totalStrategyWeight = strategies[id].totalStrategyWeight;
    return result;
  }

  function getStrategyTokenBalance(uint256 id, address token)
    public
    view
    override
    returns (uint256 amount)
  {
    amount = strategyBalances[id][token];
  }

  function getUserStrategyBalanceByToken(
    uint256 id,
    address token,
    address user
  ) public view override returns (uint256 amount) {
    amount = userStrategyBalances[user][id][token];
  }

  function getUserInvestedAmountByToken(address token, address user)
    public
    view
    override
    returns (uint256 amount)
  {
    amount = userInvestedBalances[user][token];
  }

  function getTokenTotalBalance(address token)
    public
    view
    override
    returns (uint256 amount)
  {
    amount = totalBalances[token];
  }

  function getStrategy(uint256 id)
    external
    view
    override
    returns (StrategySummary memory)
  {
    return _getStrategySummary(id);
  }

  function getExpectedBalance(address integration, address token)
    external
    view
    override
    returns (uint256 balance)
  {
    return integrationBalances[integration][token];
  }

  function getIntegrationWeight(address integration)
    external
    view
    override
    returns (uint256)
  {
    return integrationWeights[integration];
  }

  function getIntegrationWeightSum() external view override returns (uint256) {
    return totalSystemWeight;
  }
}
