// SPDX-License-Identifier: MIT
// https://uniswap.org/blog/uniswap-v3/

import "./ERC20.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./SwapBase.sol";

pragma solidity 0.6.12;

contract UniSwapV3 is SwapBase {

  uint256 public constant ONE = 10**PRECISION_DECIMALS;
  uint256 public constant ONE2 = ONE**2;

  IUniswapV3Factory uniswapFactory;

  // @dev array of fee rate tiers
  // The initially supported fee tiers are 0.05%, 0.30%, and 1%.
  // UNI governance is able to add additional values to this set.
  // denominated in hundredths of a bip
  uint24[] public fees = [500, 3000, 10000];

  constructor(address _factoryAddress) SwapBase(_factoryAddress) public {
  }

  function initializeFactory() internal virtual override {
    uniswapFactory = IUniswapV3Factory(factoryAddress);
  }

  function checkFactory(IUniswapV3Pool pair, address compareFactory) internal view returns (bool) {
    bool check;
    try pair.factory{gas: 3000}() returns (address factory) {
      check = (factory == compareFactory);
    } catch {
      check = false;
    }
    return check;
  }

  /// @dev Check what token is pool of this Swap
  function isPool(address token) public virtual override view returns(bool){
    IUniswapV3Pool pair = IUniswapV3Pool(token);
    return checkFactory(pair, factoryAddress);
  }

  /// @dev Get underlying tokens and amounts. In UniV3 pool address should be passed instead token address
  function getUnderlying(address token) public virtual override view returns (address[] memory, uint256[] memory){
    IUniswapV3Pool pair = IUniswapV3Pool(token);
    address[] memory tokens  = new address[](2);
    uint256[] memory amounts = new uint256[](2);
    tokens[0] = pair.token0();
    tokens[1] = pair.token1();
    uint256 token0Decimals = ERC20(tokens[0]).decimals();
    uint256 token1Decimals = ERC20(tokens[1]).decimals();
    uint256 liquidity = pair.liquidity();
    if (liquidity == 0) {
      amounts[0] = 0;
      amounts[1] = 0;
      return (tokens, amounts);
    }
    amounts[0] = liquidity; //TODO How we have to do with liquidity in comparison with UniSwap.sol (V2)?
    amounts[1] = liquidity;
    return (tokens, amounts);
  }

  /// @dev Returns pool size
  function getPoolSize(address pairAddress) internal view returns(uint256){
    IUniswapV3Pool pair = IUniswapV3Pool(pairAddress);
    uint256 poolSize = pair.liquidity(); // The currently in range liquidity available to the pool
    /// This value has no relationship to the total liquidity across all ticks
    return poolSize;
  }

  /// @dev Gives a pool with largest liquidity for a given token and a given tokenset (either keyTokens or pricingTokens)
  function getLargestPool(address token, address[] memory tokenList) public virtual override view returns (address, address, uint256){
    uint256 largestPoolSize = 0;
    address largestKeyToken;
    address largestPool;
    uint256 poolSize;
    for (uint256 i=0;i<tokenList.length;i++) {
      for (uint256 f=0;f<fees.length;f++) { // iterate fees pools from lowest to highest
        address poolAddress = uniswapFactory.getPool(token,tokenList[i], fees[f]);
        poolSize = poolAddress !=address(0) ? getPoolSize(poolAddress) : 0;
        if (poolSize > largestPoolSize) {
          largestKeyToken = tokenList[i];
          largestPool = poolAddress;
          largestPoolSize = poolSize;
        }
      }
    }
    return (largestKeyToken, largestPool, largestPoolSize);
  }

  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    } else z = 0;
  }

  /// @dev Generic function giving the price of a given token vs another given token
  function getPriceVsToken(address token1, address token0, address _poolAddress) // to have same result as uniV2, token0 and token1 was swapped here
  public virtual override view returns (uint256)
  {
    address poolAddress;
    if (_poolAddress!=address(0))
      poolAddress = _poolAddress;
    else {
      for (uint256 f=0;f<fees.length;f++) { // iterate fees pools from lowest to highest
        poolAddress = uniswapFactory.getPool(token0, token1, fees[f]);
        if (poolAddress !=address(0)) break;
      }
    }

    if (poolAddress ==address(0)) return 0;

    IUniswapV3Pool pair = IUniswapV3Pool(poolAddress);
    uint256 token0Decimals = ERC20(token0).decimals();
    uint256 token1Decimals = ERC20(token1).decimals();

    (uint160 sqrtPriceX96,,,,,,) = pair.slot0();

    bool reverse = token0 == pair.token0();

    uint decimals = reverse ?
      PRECISION_DECIMALS + token0Decimals - token1Decimals :
      PRECISION_DECIMALS + token1Decimals - token0Decimals;
    uint multiplier = (10**decimals);

    uint256 sqrtPrice = uint(sqrtPriceX96).mul(sqrt(multiplier)) >> 96;
    uint256 price = sqrtPrice.mul(sqrtPrice);

    if (reverse) price = ONE2.div(price);

    return price;
  }

}
