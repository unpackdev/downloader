// SPDX-License-Identifier: MIT
import "./ERC20.sol";
import "./IBEP20.sol";
import "./IMooniFactory.sol";
import "./IMooniswap.sol";
import "./SwapBase.sol";

pragma solidity 0.6.12;

contract OneInchSwap is SwapBase {

  IMooniFactory oneInchFactory;

  address public baseCurrency = address(0);

  constructor(address _factoryAddress, address _baseCurrency) SwapBase(_factoryAddress) public {
    baseCurrency = _baseCurrency;
  }

  function initializeFactory() internal virtual override {
    oneInchFactory =  IMooniFactory(factoryAddress);
  }

  /// @dev Check what token is pool of this Swap
  function isPool(address token) public virtual override view returns(bool){
    return oneInchFactory.isPool(token);
  }

  /// @dev Get underlying tokens and amounts
  function getUnderlying(address token) public virtual override view returns (address[] memory, uint256[] memory){
    IMooniswap pair = IMooniswap(token);
    address[] memory tokens  = new address[](2);
    uint256[] memory amounts = new uint256[](2);
    tokens[0] = pair.token0();
    tokens[1] = pair.token1();
    uint256 token0Decimals = (tokens[0]==address(0))? 18:ERC20(tokens[0]).decimals();
    uint256 token1Decimals = ERC20(tokens[1]).decimals();
    uint256 supplyDecimals = ERC20(token).decimals();
    uint256 reserve0 = pair.getBalanceForRemoval(tokens[0]);
    uint256 reserve1 = pair.getBalanceForRemoval(tokens[1]);
    uint256 totalSupply = pair.totalSupply();
    if (reserve0 == 0 || reserve1 == 0 || totalSupply == 0) {
      amounts[0] = 0;
      amounts[1] = 0;
      return (tokens, amounts);
    }
    amounts[0] = reserve0*10**(supplyDecimals-token0Decimals+PRECISION_DECIMALS)/totalSupply;
    amounts[1] = reserve1*10**(supplyDecimals-token1Decimals+PRECISION_DECIMALS)/totalSupply;

    //MAINNET:
    //1INCH uses ETH, instead of WETH in pools. For further calculations we continue with WETH instead.
    //ETH will always be the first in the pair, so no need to check tokens[1]
    //BSC:
    //1INCH uses BNB, instead of WBNB in pools. For further calculations we continue with WBNB instead.
    //BNB will always be the first in the pair, so no need to check tokens[1]
    if (tokens[0] == address(0)) {
      tokens[0] = baseCurrency;
    }
    return (tokens, amounts);
  }

  /// @dev Gives a pool with largest liquidity for a given token and a given tokenset (either keyTokens or pricingTokens)
  function getLargestPool(address token, address[] memory tokenList) public virtual override view returns (address, address, uint256) {
    uint256 largestPoolSize = 0;
    address largestKeyToken;
    address largestPoolAddress;
    address pairAddress;
    uint256 poolSize;
    uint256 i;
    for (i = 0; i < tokenList.length; i++) {
      pairAddress = oneInchFactory.pools(token, tokenList[i]);
      if (pairAddress != address(0)) {
        poolSize = get1InchPoolSize(pairAddress, token);
      } else {
        poolSize = 0;
      }
      if (poolSize > largestPoolSize) {
        largestPoolSize = poolSize;
        largestKeyToken = tokenList[i];
        largestPoolAddress = pairAddress;
      }
    }
    return (largestKeyToken, largestPoolAddress, largestPoolSize);
  }

  function get1InchPoolSize(address pairAddress, address token) internal view returns (uint256) {
    IMooniswap pair = IMooniswap(pairAddress);
    address token0 = pair.token0();
    address token1 = pair.token1();
    uint256 poolSize0;
    uint256 poolSize1;

    try pair.getBalanceForRemoval(token0) returns (uint256 poolSize) {
      poolSize0 = poolSize;
    } catch {
      poolSize0 = 0;
    }

    try pair.getBalanceForRemoval(token1) returns (uint256 poolSize) {
      poolSize1 = poolSize;
    } catch {
      poolSize1 = 0;
    }

    if (token0 == address(0)) {
      token0 = baseCurrency;
    }
    uint256 poolSize = (token == token0) ? poolSize0 : poolSize1;
    return poolSize;
  }


  /// @dev Generic function giving the price of a given token vs another given token
  function getPriceVsToken(address token0, address token1, address /*poolAddress*/) public virtual override view returns (uint256) {
    address pairAddress = oneInchFactory.pools(token0, token1);
    IMooniswap pair = IMooniswap(pairAddress);
    uint256 reserve0 = pair.getBalanceForRemoval(token0);
    uint256 reserve1 = pair.getBalanceForRemoval(token1);
    uint256 token0Decimals = IBEP20(token0).decimals(); // was IBEP20
    uint256 token1Decimals = IBEP20(token1).decimals(); // was IBEP20
    uint256 price = (reserve1 * 10 ** (token0Decimals - token1Decimals + PRECISION_DECIMALS)) / reserve0;
    return price;
  }

}
