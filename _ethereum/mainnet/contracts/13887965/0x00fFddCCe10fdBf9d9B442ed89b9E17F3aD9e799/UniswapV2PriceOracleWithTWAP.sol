// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./SafeMath.sol";

import "./IPriceOracle.sol";
import "./IERC20Metadata.sol";
import "./IUniswapV2Pair.sol";

interface IUniswapTWAPOracle {
  function pair() external view returns (address);

  function quote(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 points
  ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo);
}

contract UniswapV2PriceOracleWithTWAP is Ownable, IPriceOracle {
  using SafeMath for uint256;

  event UpdatePair(address indexed asset, address pair);
  event UpdateTWAP(address indexed asset, address pair);
  event UpdateMaxPriceDiff(address indexed asset, uint256 maxPriceDiff);
  event UpdateMaxTimestampDelta(uint256 maxTimestampDelta);

  // The address of Chainlink Oracle
  address public immutable chainlink;

  // The address base token.
  address public immutable base;

  // Mapping from asset address to uniswap v2 like pair.
  mapping(address => address) public pairs;

  // Mapping from pair address to twap address.
  mapping(address => address) public twaps;

  // The max price diff between spot price and twap price.
  mapping(address => uint256) public maxPriceDiff;

  // The max timestamp delta between current block and twap last updated timestamp.
  uint256 public maxTimestampDelta = 24 * 60 * 60;

  /// @param _chainlink The address of chainlink oracle.
  /// @param _base The address of base token.
  constructor(address _chainlink, address _base) {
    require(_chainlink != address(0), "UniswapV2PriceOracleWithTWAP: zero address");
    require(_base != address(0), "UniswapV2PriceOracleWithTWAP: zero address");

    chainlink = _chainlink;
    base = _base;
  }

  /// @dev Return the usd price of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  function price(address _asset) public view override returns (uint256) {
    address _pair = pairs[_asset];
    require(_pair != address(0), "UniswapV2PriceOracleWithTWAP: not supported");

    address _base = base;
    uint256 _basePrice = IPriceOracle(chainlink).price(_base);
    (uint256 _reserve0, uint256 _reserve1, ) = IUniswapV2Pair(_pair).getReserves();
    address _token0 = IUniswapV2Pair(_pair).token0();
    address _token1 = IUniswapV2Pair(_pair).token1();

    // validate price
    if (_asset == _token0) {
      _validate(_pair, _base, _asset, _reserve1, _reserve0);
    } else {
      _validate(_pair, _base, _asset, _reserve0, _reserve1);
    }

    // make reserve with scale 1e18
    if (IERC20Metadata(_token0).decimals() < 18) {
      _reserve0 = _reserve0.mul(10**(18 - IERC20Metadata(_token0).decimals()));
    }
    if (IERC20Metadata(_token1).decimals() < 18) {
      _reserve1 = _reserve1.mul(10**(18 - IERC20Metadata(_token1).decimals()));
    }

    if (_asset == _token0) {
      return _basePrice.mul(_reserve1).div(_reserve0);
    } else {
      return _basePrice.mul(_reserve0).div(_reserve1);
    }
  }

  /// @dev Return the usd value of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  /// @param _amount The amount of asset
  function value(address _asset, uint256 _amount) external view override returns (uint256) {
    uint256 _price = price(_asset);
    return _price.mul(_amount).div(10**IERC20Metadata(_asset).decimals());
  }

  /// @dev Update the UniswapV2 pair for asset
  /// @param _asset The address of asset
  /// @param _pair The address of UniswapV2 pair
  function updatePair(address _asset, address _pair) external onlyOwner {
    require(_pair != address(0), "UniswapV2PriceOracleWithTWAP: invalid pair");

    address _base = base;
    require(_base != _asset, "UniswapV2PriceOracleWithTWAP: invalid asset");

    address _token0 = IUniswapV2Pair(_pair).token0();
    address _token1 = IUniswapV2Pair(_pair).token1();
    require(_token0 == _asset || _token1 == _asset, "UniswapV2PriceOracleWithTWAP: invalid pair");
    require(_token0 == _base || _token1 == _base, "UniswapV2PriceOracleWithTWAP: invalid pair");

    pairs[_asset] = _pair;

    emit UpdatePair(_asset, _pair);
  }

  /// @dev Update the TWAP Oracle address for UniswapV2 pair
  /// @param _pair The address of UniswapV2 pair
  /// @param _twap The address of twap oracle.
  function updateTWAP(address _pair, address _twap) external onlyOwner {
    require(IUniswapTWAPOracle(_twap).pair() == _pair, "UniswapV2PriceOracleWithTWAP: invalid twap");

    twaps[_pair] = _twap;

    emit UpdateTWAP(_pair, _twap);
  }

  /// @dev Update the max price diff between spot price and twap price.
  /// @param _asset The address of asset.
  /// @param _maxPriceDiff The max price diff.
  function updatePriceDiff(address _asset, uint256 _maxPriceDiff) external onlyOwner {
    require(_maxPriceDiff <= 2e17, "UniswapV2PriceOracleWithTWAP: should <= 20%");

    maxPriceDiff[_asset] = _maxPriceDiff;

    emit UpdateMaxPriceDiff(_asset, _maxPriceDiff);
  }

  /// @dev Update max timestamp delta between current block and twap last updated timestamp.
  /// @param _maxTimestampDelta The value of max timestamp delta, in seconds.
  function updateMaxTimestampDelta(uint256 _maxTimestampDelta) external onlyOwner {
    maxTimestampDelta = _maxTimestampDelta;

    emit UpdateMaxTimestampDelta(_maxTimestampDelta);
  }

  function _validate(
    address _pair,
    address _base,
    address _asset,
    uint256 _reserveBase,
    uint256 _reserveAsset
  ) internal view {
    address _twap = twaps[_pair];
    // skip check if twap not available, usually will be used in test.
    if (_twap == address(0)) return;
    uint256 _priceDiff = maxPriceDiff[_asset];
    uint256 _unitAmount = 10**IERC20Metadata(_asset).decimals();

    // number of base token that 1 asset can swap right now.
    uint256 _amount = _reserveBase.mul(_unitAmount).div(_reserveAsset);
    // number of base token that 1 asset can swap in twap.
    (uint256 _twapAmount, uint256 _lastUpdatedAgo) = IUniswapTWAPOracle(_twap).quote(_asset, _unitAmount, _base, 2);

    require(_lastUpdatedAgo <= maxTimestampDelta, "UniswapV2PriceOracleWithTWAP: twap price too old");
    require(_amount >= _twapAmount.mul(1e18 - _priceDiff).div(1e18), "UniswapV2PriceOracleWithTWAP: price too small");
    require(_amount <= _twapAmount.mul(1e18 + _priceDiff).div(1e18), "UniswapV2PriceOracleWithTWAP: price too large");
  }
}
