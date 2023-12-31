
pragma solidity ^0.8.0;

import "./IBalancerVault.sol";

uint constant WANT_INDEX = 2;
uint constant INTEREST_RATE_MODE = 2;
uint8 constant BASE_TOKENS_COUNT = 3;

interface Config {
  struct Data {
    address loanToken0;
    address loanToken1;
    address want;
    bytes32 decimals;
    uint nativeIndex;

    uint proportion;
    uint borrowRate;

    AaveContracts aaveContracts;
    BalancerContracts balancerContracts;
    AuraContracts auraContracts;
    PoolIds poolIds;
  }

  struct AaveContracts {
    address lendingPool; // Aave lending pool
    address priceOracle; // Aave price oracle
    address dataProvider; // Aave data provider
    address rewardsController; // Aave rewards controller
  }

  struct BalancerContracts {
    address balancerVault; // Balancer Vault
    address bptPool1; // balancer LP
    address bptPool2; // balancer LP
  }

  struct AuraContracts {
    address booster; // Aura booster
    address auraClaimZapV3; // Aura rewards claimer
    address stakingToken; // Aura staking token
  }

  struct PoolIds {
    bytes32 poolId1; // Balancer pool Id
    bytes32 poolId2; // Balancer pool Id
    uint256 pidAura; // Aura staking pool id
  }

  // struct getter
  function get() external view returns (Data memory);
}

interface ConfigExt {
  struct Data {
    address[] tokens;
    bytes32[] routing; // routing[sourceTokenIndex][targetTokenIndex] = nextTokenIndex or (poolIndex + tokensCount)
                       // routing[poolIndex + tokensCount] = poolId
    address[] rewardersAura;
    bytes32 rewardTokens; // tokenIndexesAura | tokenIndexesAave, last byte is length 
    bool harvestOnDeposit;
    uint withdrawMin; // min rate to be withdrawn from Balancer
  }

  function get() external view returns (Data memory);
}

struct Configs {
  Config.Data base;
  ConfigExt.Data ext;
}

function getRoute(Configs memory configs, uint tokenInIndex, uint tokenOutIndex) pure returns (uint[] memory path, bytes32[] memory pools) {
  (path, pools) = buildRoute(configs.ext, tokenInIndex, tokenOutIndex, 1);
  path[0] = tokenInIndex;
}

function buildRoute(ConfigExt.Data memory configExt, uint tokenInIndex, uint tokenOutIndex, uint depth) pure returns (uint[] memory path, bytes32[] memory pools) {
  unchecked {
    bytes32 route = configExt.routing[tokenInIndex];
    uint step = uint8(route[tokenOutIndex]);
    uint poolIndex;
    uint tokenIndex;
    if (step < configExt.tokens.length + BASE_TOKENS_COUNT) {
      tokenIndex = step;
      poolIndex = uint8(route[tokenIndex]);
      (path, pools) = buildRoute(configExt, tokenIndex, tokenOutIndex, depth + 1);
    } else {
      require(step < type(uint8).max, "No route found");
      tokenIndex = tokenOutIndex;
      poolIndex = step;
      path = new uint[](depth + 1);
      pools = new bytes32[](depth);
    }

    path[depth] = tokenIndex;
    pools[depth - 1] = configExt.routing[poolIndex];
  }
}

function getProportion(Configs memory configs, uint tokenIndex) pure returns (uint) {
  if (tokenIndex == 0) {
    return configs.base.proportion;
  }
  if (tokenIndex == 1) {
    return 1 ether - configs.base.proportion;
  }
  revert("Proportion not found");
}

function getTokenAddress(Configs memory configs, uint tokenIndex) pure returns (address) {
  if (tokenIndex == 0) {
    return configs.base.loanToken0;
  }
  if (tokenIndex == 1) {
    return configs.base.loanToken1;
  }
  if (tokenIndex == WANT_INDEX) {
    return configs.base.want;
  }

  return configs.ext.tokens[tokenIndex - BASE_TOKENS_COUNT];
}

function getTokenIndex(Configs memory configs, address tokenAddress) pure returns (uint tokenIndex) {
  unchecked {
    for(tokenIndex = 0; tokenIndex < BASE_TOKENS_COUNT + configs.ext.tokens.length; tokenIndex++) {
      if (getTokenAddress(configs, tokenIndex) == tokenAddress) {
        return tokenIndex;
      }
    }

    revert("Token not found");
  }
}

function getRouteAddresses(Configs memory configs, uint tokenInIndex, uint tokenOutIndex) pure returns (address[] memory tokens, bytes32[] memory pools) {
  uint[] memory route;
  (route, pools) = getRoute(configs, tokenInIndex, tokenOutIndex);
  tokens = new address[](route.length);
  unchecked {
    for(uint i = 0; i < route.length; i++) {
      tokens[i] = getTokenAddress(configs, route[i]);
    }
  }
}

function getRewardTokensCount(Configs memory configs) pure returns (uint) {
  return uint8(uint(configs.ext.rewardTokens));
}

function getRewardToken(Configs memory configs, uint rewardTokenIndex) pure returns (uint) {
  return uint8(configs.ext.rewardTokens[rewardTokenIndex]);
}