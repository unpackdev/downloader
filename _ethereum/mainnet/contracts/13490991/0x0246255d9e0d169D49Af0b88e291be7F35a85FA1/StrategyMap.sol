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
  // #### Constants
  uint32 public constant TOKEN_WEIGHT = 100000;

  // #### Global State

  // Strategy id => Strategy
  mapping(uint256 => Strategy) internal strategies;

  // User => Strategy => Token => Balance
  mapping(address => mapping(uint256 => mapping(address => uint256)))
    internal userStrategyBalances;

  // User => Token => Amount
  mapping(address => mapping(address => uint256)) internal userTokenBalances;

  // Token => total amount in all strategies
  mapping(address => uint256) internal tokenBalances;

  // Strategy => token => balance
  mapping(uint256 => mapping(address => uint256))
    internal strategyTokenBalances;

  // Integration => pool id => token => amount to deploy
  mapping(address => mapping(uint32 => mapping(address => int256)))
    internal deployAmount;

  // integration => token => poolID[]
  mapping(address => mapping(address => uint32[])) internal pools;

  // user => abi.encode(integration, token, poolID) => withdraw amount
  mapping(address => mapping(bytes => uint256)) internal withdrawalVectors;

  uint256 public override idCounter;

  // Used for strategy verification. Contents are always deleted at the end of a tx to reduce gas hit.
  mapping(address => uint256) internal tokenWeights;

  // Users => StrategyRecord - Used to correlate multiple strategies with a user
  mapping(address => StrategyRecord[]) internal userStrategies;

  // #### Functions

  function initialize(address[] memory controllers_, address moduleMap_)
    public
    initializer
  {
    __Controlled_init(controllers_, moduleMap_);
    __ModuleMapConsumer_init(moduleMap_);
  }

  function _insertPoolID(
    address integration,
    uint32 poolID,
    address token
  ) internal {
    uint32[] memory poolIDs = pools[integration][token];
    bool found = false;
    for (uint256 i = 0; i < poolIDs.length; i++) {
      if (poolIDs[i] == poolID) {
        found = true;
        break;
      }
    }
    if (!found) {
      pools[integration][token].push(poolID);
    }
  }

  function addStrategy(
    string calldata name,
    Integration[] calldata integrations,
    Token[] calldata tokens
  ) external override onlyController {
    require(integrations.length > 0, "integrations missing");
    require(tokens.length > 0, "tokens missing");
    require(bytes(name).length > 0, "must have a name");

    idCounter++;
    uint256 strategyID = idCounter;
    _verifyAndSetStrategy(strategyID, name, integrations, tokens);

    // Emit event
    emit NewStrategy(strategyID, integrations, tokens, name);
  }

  function _verifyAndSetStrategy(
    uint256 strategyID,
    string memory name,
    Integration[] memory integrations,
    Token[] memory tokens
  ) internal {
    for (uint256 i = 0; i < integrations.length; i++) {
      require(integrations[i].integration != address(0), "bad integration");
    }

    address[] memory uniqueTokens = new address[](tokens.length);
    uint256 idx = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      require(
        tokens[i].integrationPairIdx < integrations.length,
        "integration idx out of bounds"
      );
      require(tokens[i].token != address(0), "bad token");

      if (tokenWeights[tokens[i].token] == 0) {
        uniqueTokens[idx] = tokens[i].token;
        idx++;
      }
      tokenWeights[tokens[i].token] += tokens[i].weight;
      _insertPoolID(
        integrations[tokens[i].integrationPairIdx].integration,
        integrations[tokens[i].integrationPairIdx].ammPoolID,
        tokens[i].token
      );
    }

    // Verify weights
    for (uint256 i = 0; i < idx; i++) {
      require(
        tokenWeights[uniqueTokens[i]] == TOKEN_WEIGHT,
        "invalid token weight"
      );
      strategies[strategyID].availableTokens[uniqueTokens[i]] = true;
      delete tokenWeights[uniqueTokens[i]];
    }

    strategies[strategyID].name = name;

    // Can't copy a memory array directly to storage yet, so we build it manually.
    for (uint256 i = 0; i < integrations.length; i++) {
      strategies[strategyID].integrations.push(integrations[i]);
    }
    for (uint256 i = 0; i < tokens.length; i++) {
      strategies[strategyID].tokens.push(tokens[i]);
    }
  }

  function updateName(uint256 id, string calldata name)
    external
    override
    onlyController
  {
    require(bytes(strategies[id].name).length > 0, "strategy must exist");
    require(bytes(name).length > 0, "invalid name");
    strategies[id].name = name;
    emit UpdateName(id, name);
  }

  function updateStrategy(
    uint256 id,
    Integration[] calldata integrations,
    Token[] calldata tokens
  ) external override onlyController {
    require(integrations.length > 0, "integrations missing");
    require(tokens.length > 0, "tokens missing");
    require(bytes(strategies[id].name).length > 0, "strategy must exist");

    StrategySummary memory currentStrategy = getStrategy(id);

    delete strategies[id].tokens;
    delete strategies[id].integrations;

    // Reduce deploy amount for each current token by: strat token balance * weight / TOKEN_WEIGHT

    for (uint256 i = 0; i < currentStrategy.tokens.length; i++) {
      deployAmount[
        currentStrategy
          .integrations[currentStrategy.tokens[i].integrationPairIdx]
          .integration
      ][
        currentStrategy
          .integrations[currentStrategy.tokens[i].integrationPairIdx]
          .ammPoolID
      ][currentStrategy.tokens[i].token] -= int256(
        (strategyTokenBalances[id][currentStrategy.tokens[i].token] *
          currentStrategy.tokens[i].weight) / TOKEN_WEIGHT
      );

      delete strategies[id].availableTokens[currentStrategy.tokens[i].token];
    }

    // Increase deploy amount for each new token by: strat token balance * weight / TOKEN_WEIGHT
    for (uint256 i = 0; i < tokens.length; i++) {
      if (strategyTokenBalances[id][tokens[i].token] > 0) {
        deployAmount[integrations[tokens[i].integrationPairIdx].integration][
          integrations[tokens[i].integrationPairIdx].ammPoolID
        ][tokens[i].token] += int256(
          (strategyTokenBalances[id][tokens[i].token] * tokens[i].weight) /
            TOKEN_WEIGHT
        );
      }
    }

    _verifyAndSetStrategy(id, currentStrategy.name, integrations, tokens);

    emit UpdateStrategy(id, integrations, tokens);
  }

  function deleteStrategy(uint256 id) external override onlyController {
    StrategySummary memory strategy = getStrategy(id);
    for (uint256 i = 0; i < strategy.tokens.length; i++) {
      require(
        strategyTokenBalances[id][strategy.tokens[i].token] == 0,
        "strategy in use"
      );
      delete strategies[id].availableTokens[strategy.tokens[i].token];
    }
    delete strategies[id];
    emit DeleteStrategy(id);
  }

  function enterStrategy(
    uint256 id,
    address user,
    TokenMovement[] calldata tokens
  ) external override onlyController {
    StrategySummary memory strategy = getStrategy(id);

    for (uint256 i = 0; i < tokens.length; i++) {
      require(strategies[id].availableTokens[tokens[i].token], "invalid token");
      // Check for virtual funds
      _processVirtualFunds(user, tokens[i].token, tokens[i].amount);

      // Update state
      tokenWeights[tokens[i].token] = tokens[i].amount;
      userStrategyBalances[user][id][tokens[i].token] += tokens[i].amount;
      userTokenBalances[user][tokens[i].token] += tokens[i].amount;
      tokenBalances[tokens[i].token] += tokens[i].amount;
      strategyTokenBalances[id][tokens[i].token] += tokens[i].amount;
    }

    for (uint256 i = 0; i < strategy.tokens.length; i++) {
      // Increase deploy amounts
      Token memory token = strategy.tokens[i];
      deployAmount[strategy.integrations[token.integrationPairIdx].integration][
        strategy.integrations[token.integrationPairIdx].ammPoolID
      ][token.token] += int256(
        (tokenWeights[token.token] * token.weight) / TOKEN_WEIGHT
      );
    }

    for (uint256 i = 0; i < tokens.length; i++) {
      delete tokenWeights[tokens[i].token];
    }

    userStrategies[user].push(StrategyRecord({strategyId: id, timestamp: block.timestamp}));

    emit EnterStrategy(id, user, tokens);
  }

  function _processVirtualFunds(
    address user,
    address token,
    uint256 tokenAmountRequired
  ) private {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    uint256 integrationCount = integrationMap.getIntegrationAddressesLength();
    IUserPositions userPositions = IUserPositions(
      moduleMap.getModuleAddress(Modules.UserPositions)
    );
    uint256 virtualBalance = userPositions.getUserVirtualBalance(user, token);
    if (virtualBalance > 0) {
      uint256 currentAmount = tokenAmountRequired;
      for (uint256 i = 0; i < integrationCount; i++) {
        uint32[] memory tokenPools = pools[
          integrationMap.getIntegrationAddress(i)
        ][token];
        if (tokenPools.length > 0) {
          for (uint256 j = 0; j < tokenPools.length; j++) {
            bytes memory key = abi.encode(
              integrationMap.getIntegrationAddress(i),
              token,
              tokenPools[j]
            );
            uint256 withdrawalBalance = withdrawalVectors[user][key];
            if (withdrawalBalance > 0 && currentAmount > 0) {
              if (withdrawalBalance >= currentAmount) {
                withdrawalVectors[user][key] -= currentAmount;
                currentAmount = 0;
                deployAmount[integrationMap.getIntegrationAddress(i)][
                  tokenPools[j]
                ][token] -= int256(currentAmount);
              } else {
                withdrawalVectors[user][key] = 0;
                currentAmount -= withdrawalBalance;
                deployAmount[integrationMap.getIntegrationAddress(i)][
                  tokenPools[j]
                ][token] -= int256(withdrawalBalance);
              }
            }
            if (currentAmount == 0) {
              break;
            }
          }
        }
        if (currentAmount == 0) {
          break;
        }
      }
    }
  }

  function exitStrategy(
    uint256 id,
    address user,
    TokenMovement[] calldata tokens
  ) external override onlyController {
    // IMPORTANT: Should allow a user to withdraw orphaned funds
    StrategySummary memory strategy = getStrategy(id);

    for (uint256 i = 0; i < tokens.length; i++) {
      // Check user has balance and that user is invested in strategy
      require(
        userTokenBalances[user][tokens[i].token] >= tokens[i].amount,
        "insufficient funds"
      );
      require(
        userStrategyBalances[user][id][tokens[i].token] >= tokens[i].amount,
        "invalid strategy"
      );

      // Update strategy balances
      strategyTokenBalances[id][tokens[i].token] -= tokens[i].amount;

      // Update user balances
      userStrategyBalances[user][id][tokens[i].token] -= tokens[i].amount;
      userTokenBalances[user][tokens[i].token] -= tokens[i].amount;

      // Update global balances
      tokenBalances[tokens[i].token] -= tokens[i].amount;
      tokenWeights[tokens[i].token] = tokens[i].amount;
    }
    if (strategy.tokens.length > 0) {
      // If the strategy hasn't been deleted, we need to unwind the positions
      for (uint256 i = 0; i < strategy.tokens.length; i++) {
        // Set the user withdrawal amounts (-tokens[i].amount)
        Token memory token = strategy.tokens[i];
        if (tokenWeights[token.token] > 0) {
          withdrawalVectors[user][
            abi.encode(
              strategy.integrations[token.integrationPairIdx].integration,
              token.token,
              strategy.integrations[token.integrationPairIdx].ammPoolID
            )
          ] += (tokenWeights[token.token] * token.weight) / TOKEN_WEIGHT;
        }
      }
    }

    for (uint256 i = 0; i < tokens.length; i++) {
      delete tokenWeights[tokens[i].token];
    }
    emit ExitStrategy(id, user, tokens);
  }

  function decreaseDeployAmountChange(
    address integration,
    uint32 poolID,
    address token,
    uint256 amount
  ) external override {
    int256 currentAmount = deployAmount[integration][poolID][token];

    if (currentAmount >= 0) {
      deployAmount[integration][poolID][token] -= int256(amount);
    } else {
      deployAmount[integration][poolID][token] += int256(amount);
    }
  }

  function getStrategy(uint256 id)
    public
    view
    override
    returns (StrategySummary memory)
  {
    StrategySummary memory result;
    result.name = strategies[id].name;
    result.integrations = strategies[id].integrations;
    result.tokens = strategies[id].tokens;
    return result;
  }

  function getMultipleStrategies(uint256[] calldata ids)
    external
    view
    override
    returns (StrategySummary[] memory)
  {
    StrategySummary[] memory strategies = new StrategySummary[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      strategies[i] = getStrategy(ids[i]);
    }
    return strategies;
  }

  function getStrategyTokenBalance(uint256 id, address token)
    public
    view
    override
    returns (uint256 amount)
  {
    amount = strategyTokenBalances[id][token];
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
    amount = userTokenBalances[user][token];
  }

  function getTokenTotalBalance(address token)
    public
    view
    override
    returns (uint256 amount)
  {
    amount = tokenBalances[token];
  }

  function getDeployAmount(
    address integration,
    uint32 poolID,
    address token
  ) external view override returns (int256) {
    return deployAmount[integration][poolID][token];
  }

  function getPools(address integration, address token)
    external
    view
    override
    returns (uint32[] memory)
  {
    return pools[integration][token];
  }

  function getUserWithdrawalVector(
    address user,
    address token,
    address integration,
    uint32 poolID
  ) external view override returns (uint256) {
    return withdrawalVectors[user][abi.encode(integration, token, poolID)];
  }

  function getAllStrategyRecords(address user) 
    public
    view
    returns(StrategyRecord[] memory) {
      return userStrategies[user];
  }

  function updateUserWithdrawalVector(
    address user,
    address token,
    address integration,
    uint32 poolID,
    uint256 amount
  ) external override onlyController {
    bytes memory key = abi.encode(integration, token, poolID);
    if (withdrawalVectors[user][key] >= amount) {
      withdrawalVectors[user][key] -= amount;
    }
  }

  function getUserBalances(
    address user,
    uint256[] calldata _strategies,
    address[] calldata _tokens
  )
    external
    view
    override
    returns (
      StrategyBalance[] memory strategyBalance,
      GeneralBalance[] memory userBalance
    )
  {
    strategyBalance = new StrategyBalance[](_strategies.length);
    userBalance = new GeneralBalance[](_tokens.length);

    for (uint256 i = 0; i < _tokens.length; i++) {
      userBalance[i].token = _tokens[i];
      userBalance[i].balance = userTokenBalances[user][_tokens[i]];
    }

    for (uint256 i = 0; i < _strategies.length; i++) {
      Token[] memory strategyTokens = strategies[_strategies[i]].tokens;
      strategyBalance[i].tokens = new GeneralBalance[](strategyTokens.length);
      strategyBalance[i].strategyID = _strategies[i];
      for (uint256 j = 0; j < strategyTokens.length; j++) {
        strategyBalance[i].tokens[j].token = strategyTokens[j].token;
        strategyBalance[i].tokens[j].balance = userStrategyBalances[user][
          _strategies[i]
        ][strategyTokens[j].token];
      }
    }
  }

  function getStrategyBalances(
    uint256[] calldata _strategies,
    address[] calldata _tokens
  )
    external
    view
    override
    returns (
      StrategyBalance[] memory strategyBalances,
      GeneralBalance[] memory generalBalances
    )
  {
    strategyBalances = new StrategyBalance[](_strategies.length);
    generalBalances = new GeneralBalance[](_tokens.length);

    for (uint256 i = 0; i < _tokens.length; i++) {
      generalBalances[i].token = _tokens[i];
      generalBalances[i].balance = tokenBalances[_tokens[i]];
    }

    for (uint256 i = 0; i < _strategies.length; i++) {
      Token[] memory strategyTokens = strategies[_strategies[i]].tokens;
      strategyBalances[i].tokens = new GeneralBalance[](strategyTokens.length);
      strategyBalances[i].strategyID = _strategies[i];
      for (uint256 j = 0; j < strategyTokens.length; j++) {
        strategyBalances[i].tokens[j].token = strategyTokens[j].token;
        strategyBalances[i].tokens[j].balance = strategyTokenBalances[
          _strategies[i]
        ][strategyTokens[j].token];
      }
    }
  }
}
