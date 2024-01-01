// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./AaveV3.sol";
import "./BPoolV2.sol";
import "./BVaultV2.sol";
import "./IExtendedAggregator.sol";
import "./BNum.sol";
import "./LogExpMath.sol";

/** @title BalancerV2SharedPoolPriceProvider
 * @notice Price provider for a balancer pool token
 * It calculates the price using Chainlink as an external price source and the pool's tokens balances using the weighted arithmetic mean formula.
 * If there is a price deviation, instead of the balances, it uses a weighted geometric mean with the token's weights and constant value function V.
 */

contract BalancerV2SharedPoolPriceProvider is BNum, IExtendedAggregator {
  BPoolV2 public pool;
  BVaultV2 public vault;
  bytes32 public poolId;
  address[] public tokens;
  uint256[] public weights;
  uint8[] public decimals;
  IAaveOracle public priceOracle;
  uint256 public immutable maxPriceDeviation;
  uint256 internal immutable K;

  /**
   * BalancerSharedPoolPriceProvider constructor.
   * @param _pool Balancer pool address.
   * @param _decimals Number of decimals for each token (token order determined by pool.getFinalTokens()).
   * @param _priceOracle Aave price oracle.
   * @param _maxPriceDeviation Threshold of spot prices deviation: 10ˆ16 represents a 1% deviation.
   * @param _K //Constant K = 1 / (w1ˆw1 * .. * wn^wn)
   */
  constructor(
    BPoolV2 _pool,
    BVaultV2 _vault,
    uint8[] memory _decimals,
    IAaveOracle _priceOracle,
    uint256 _maxPriceDeviation,
    uint256 _K
  ) {
    pool = _pool;
    vault = _vault;
    // Get token list
    (tokens, , ) = _vault.getPoolTokens(_pool.getPoolId());
    // Get pool id
    poolId = _pool.getPoolId();
    uint256 length = tokens.length;
    // Validate contructor params
    require(length >= 2 && length <= 3, 'ERR_INVALID_POOL_TOKENS_NUMBER');
    require(_decimals.length == length, 'ERR_INVALID_DECIMALS_LENGTH');
    for (uint8 i = 0; i < length; i++) {
      require(_decimals[i] <= 18, 'ERR_INVALID_DECIMALS');
    }
    require(_maxPriceDeviation < BONE, 'ERR_INVALID_PRICE_DEVIATION');
    require(address(_priceOracle) != address(0), 'ERR_INVALID_PRICE_PROVIDER');
    // Get token normalized weights
    uint256[] memory _weights = _pool.getNormalizedWeights();
    for (uint8 i = 0; i < length; i++) {
      weights.push(_weights[i]);
    }
    decimals = _decimals;
    priceOracle = _priceOracle;
    maxPriceDeviation = _maxPriceDeviation;
    K = _K;
  }

  /**
   * Returns the token balances in USD by multiplying each token balance with its price in usd.
   */
  function getUsdBalances() internal view returns (uint256[] memory) {
    uint256[] memory usdBalances = new uint256[](tokens.length);
    (, uint256[] memory balances, ) = vault.getPoolTokens(poolId);

    for (uint256 index; index < tokens.length; index++) {
      uint256 pi = uint256(priceOracle.getAssetPrice(tokens[index]));
      require(pi > 0, 'ERR_NO_ORACLE_PRICE');
      uint256 missingDecimals = 18 - decimals[index];
      uint256 bi = bmul(balances[index], BONE * 10 ** (missingDecimals));
      usdBalances[index] = bmul(bi, pi);
    }
    return usdBalances;
  }

  /**
   * Returns true if there is a price deviation.
   * @param usdTotals Balance of each token in usd.
   */
  function hasDeviation(uint256[] memory usdTotals) internal view returns (bool) {
    //Check for a price deviation
    uint256 length = tokens.length;
    for (uint8 i = 0; i < length; i++) {
      for (uint8 o = 0; o < length; o++) {
        if (i != o) {
          uint256 price_deviation = bdiv(
            bdiv(usdTotals[i], weights[i]),
            bdiv(usdTotals[o], weights[o])
          );
          if (
            price_deviation > (BONE + maxPriceDeviation) ||
            price_deviation < (BONE - maxPriceDeviation)
          ) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /**
   * Calculates the price of the pool token using the formula of weighted arithmetic mean.
   * @param usdTotals Balance of each token in usd.
   */
  function getArithmeticMean(uint256[] memory usdTotals) internal view returns (uint256) {
    uint256 totalUsd = 0;
    uint256 length = tokens.length;
    for (uint8 i = 0; i < length; i++) {
      totalUsd = badd(totalUsd, usdTotals[i]);
    }
    return bdiv(totalUsd, pool.totalSupply());
  }

  /**
   * Returns the weighted token balance in usd by calculating the balance in usd of the token to the power of its weight.
   * @param index Token index.
   */
  function getWeightedUsdBalanceByToken(
    uint256 index,
    uint256 usdTotal
  ) internal view returns (uint256) {
    uint256 weight = weights[index];
    return LogExpMath.pow(usdTotal, weight);
  }

  /**
   * Calculates the price of the pool token using the formula of weighted geometric mean.
   * @param usdTotals Balance of each token in usd.
   */
  function getWeightedGeometricMean(uint256[] memory usdTotals) internal view returns (uint256) {
    uint256 mult = BONE;
    uint256 length = tokens.length;
    for (uint256 i = 0; i < length; i++) {
      mult = bmul(mult, getWeightedUsdBalanceByToken(i, usdTotals[i]));
    }
    return bdiv(bmul(mult, K), pool.totalSupply());
  }

  /**
   * Returns Balancer Vault address.
   */
  function getVault() external view returns (BVaultV2) {
    return vault;
  }

  /**
   * Returns Balancer pool address.
   */
  function getPool() external view returns (BPoolV2) {
    return pool;
  }

  /**
   * Returns all tokens's weights.
   */
  function getWeights() external view returns (uint256[] memory) {
    return weights;
  }

  /**
   * @dev Returns token type for categorization
   * @return uint256 1 = Simple (Native or plain ERC20 tokens like DAI), 2 = Complex (LP Tokens, Staked tokens)
   */
  function getTokenType() external pure override returns (IExtendedAggregator.TokenType) {
    return IExtendedAggregator.TokenType.Complex;
  }

  /**
   * @dev Returns the number of tokens that composes the LP shares
   * @return address[] memory of token addresses
   */
  function getSubTokens() external view override returns (address[] memory) {
    return tokens;
  }

  /**
   * @dev Returns the LP shares token
   * @return address of the LP shares token
   */
  function getToken() external view override returns (address) {
    return address(pool);
  }

  /**
   * @dev Returns the platform id to categorize the price aggregator
   * @return uint256 1 = Uniswap, 2 = Balancer
   */
  function getPlatformId() external pure override returns (IExtendedAggregator.PlatformId) {
    return IExtendedAggregator.PlatformId.Balancer;
  }

  /**
   * @dev Returns the pool's token price.
   *   It calculates the price using Chainlink as an external price source and the pool's tokens balances using the weighted arithmetic mean formula.
   *   If there is a price deviation, instead of the balances, it uses a weighted geometric mean with the token's weights and constant value function V.
   * @return int256 price
   */
  function latestAnswer() external view override returns (int256) {
    //Get token balances in usd
    uint256[] memory usdTotals = getUsdBalances();

    if (hasDeviation(usdTotals)) {
      //Calculate the weighted geometric mean
      return int256(getWeightedGeometricMean(usdTotals));
    } else {
      //Calculate the weighted arithmetic mean
      return int256(getArithmeticMean(usdTotals));
    }
  }
}
