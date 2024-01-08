// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IOracle.sol";
import "./SafeMath.sol";
import "./LibraryV2Oracle.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./Ownable.sol";

interface IERC20 {
  function decimals() external view returns (uint8);
}

contract V2Oracle is IOracle, Ownable {
  using FixedPoint for *;
  using SafeMath for uint256;

  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant AQUA = 0xD34a24006b862f4E9936c506691539D6433aD297;
  address public constant UNISWAP_V2_FACTORY =
    0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

  uint256 public WINDOW;

  mapping(address => uint256) public cummulativeAveragePrice;
  mapping(address => uint256) public cummulativeEthPrice;
  mapping(address => uint32) public tokenToTimestampLast;
  mapping(address => uint256) public cummulativeAveragePriceReserve;
  mapping(address => uint256) public cummulativeEthPriceReserve;
  mapping(address => uint32) public lastTokenTimestamp;

  event AssetValue(uint256, uint256);

  constructor(uint256 window) {
    WINDOW = window;
  }

  function setWindow(uint256 newWindow) external onlyOwner {
    WINDOW = newWindow;
  }

  function setValues(address token) internal {
    address pool = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(WETH, token);
    if (pool != address(0)) {
      if (WETH < token) {
        (
          cummulativeEthPrice[token],
          cummulativeAveragePrice[token],
          tokenToTimestampLast[token]
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pool));
        cummulativeAveragePriceReserve[token] = IUniswapV2Pair(pool)
          .price0CumulativeLast();
        cummulativeEthPriceReserve[token] = IUniswapV2Pair(pool)
          .price1CumulativeLast();
      } else {
        (
          cummulativeAveragePrice[token],
          cummulativeEthPrice[token],
          tokenToTimestampLast[token]
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pool));
        cummulativeAveragePriceReserve[token] = IUniswapV2Pair(pool)
          .price1CumulativeLast();
        cummulativeEthPriceReserve[token] = IUniswapV2Pair(pool)
          .price0CumulativeLast();
      }
      lastTokenTimestamp[token] = uint32(block.timestamp);
    }
  }

  function fetch(address token, bytes calldata)
    external
    override
    returns (uint256 price)
  {
    uint256 ethPerAqua = _getAmounts(AQUA);
    emit AssetValue(ethPerAqua, block.timestamp);
    uint256 ethPerToken = _getAmounts(token);
    emit AssetValue(ethPerToken, block.timestamp);
    if (ethPerToken == 0 || ethPerAqua == 0) return 0;
    price = (ethPerToken.mul(1e18)).div(ethPerAqua);
    emit AssetValue(price, block.timestamp);
  }

  function fetchAquaPrice() external override returns (uint256 price) {
    // to get aqua per eth
    if (
      cummulativeAveragePrice[AQUA] == 0 ||
      (uint32(block.timestamp) - lastTokenTimestamp[AQUA]) >= WINDOW
    ) {
      setValues(AQUA);
    }
    uint32 timeElapsed = lastTokenTimestamp[AQUA] - tokenToTimestampLast[AQUA];
    price = _calculate(
      cummulativeEthPrice[AQUA],
      cummulativeAveragePriceReserve[AQUA],
      timeElapsed,
      AQUA
    );
    emit AssetValue(price, block.timestamp);
  }

  function _getAmounts(address token) internal returns (uint256 ethPerToken) {
    if (
      cummulativeAveragePrice[token] == 0 ||
      (uint32(block.timestamp) - lastTokenTimestamp[token]) >= WINDOW
    ) {
      setValues(token);
    }
    address poolAddress = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(
      WETH,
      token
    );
    if (poolAddress == address(0)) return 0;
    uint32 timeElapsed = lastTokenTimestamp[token] -
      tokenToTimestampLast[token];
    ethPerToken = _calculate(
      cummulativeAveragePrice[token],
      cummulativeEthPriceReserve[token],
      timeElapsed,
      token
    );
  }

  function _calculate(
    uint256 latestCommulative,
    uint256 oldCommulative,
    uint32 timeElapsed,
    address token
  ) public view returns (uint256 assetValue) {
    FixedPoint.uq112x112 memory priceTemp = FixedPoint.uq112x112(
      uint224((latestCommulative.sub(oldCommulative)).div(timeElapsed))
    );
    uint8 decimals = IERC20(token).decimals();
    assetValue = priceTemp.mul(10**decimals).decode144();
  }
}
