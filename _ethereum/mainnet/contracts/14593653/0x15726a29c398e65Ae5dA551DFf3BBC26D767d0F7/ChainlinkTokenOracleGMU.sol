// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";
import "./IPriceFeed.sol";
import "./IOracle.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

interface IERC20WithDecimals is IERC20 {
  function decimals() external view returns (uint256);
}

contract ChainlinkTokenOracleGMU is IPriceFeed {
  using SafeMath for uint256;

  IERC20WithDecimals public token;
  AggregatorV3Interface public chainlink;

  IOracle public gmuOracle;
  uint256 public constant TARGET_DIGITS = 18;

  struct ChainlinkResponse {
    uint80 roundId;
    int256 answer;
    uint256 timestamp;
    bool success;
    uint8 decimals;
  }

  constructor(
    address _chainlink,
    address _gmuOracle,
    address _token
  ) {
    chainlink = AggregatorV3Interface(_chainlink);
    gmuOracle = IOracle(_gmuOracle);
    token = IERC20WithDecimals(_token);
  }

  function priceFor(uint256 amount) external view returns (uint256) {
    return
      _scalePriceByDigits(amount, token.decimals()).mul(_fetchPrice()).div(
        1e18
      );
  }

  function fetchPrice() external view override returns (uint256) {
    return _fetchPrice();
  }

  function _fetchPrice() internal view returns (uint256) {
    return _fetchWithChainlink(chainlink);
  }

  function _fetchWithChainlink(AggregatorV3Interface agg)
    internal
    view
    returns (uint256)
  {
    uint256 gmuPrice = fetchGMUPrice();
    uint256 chainlinkPrice = _fetchChainlinkPrice(agg);
    return (chainlinkPrice.mul(10**TARGET_DIGITS).div(gmuPrice));
  }

  function _scalePriceByDigits(uint256 _price, uint256 _answerDigits)
    internal
    pure
    returns (uint256)
  {
    // Convert the price returned by the oracle to an 18-digit decimal for use.
    uint256 price;
    if (_answerDigits >= TARGET_DIGITS) {
      // Scale the returned price value down to Liquity's target precision
      price = _price.div(10**(_answerDigits - TARGET_DIGITS));
    } else if (_answerDigits < TARGET_DIGITS) {
      // Scale the returned price value up to Liquity's target precision
      price = _price.mul(10**(TARGET_DIGITS - _answerDigits));
    }
    return price;
  }

  function fetchGMUPrice() public view returns (uint256) {
    uint256 gmuPrice = gmuOracle.getPrice();
    uint256 gmuPricePrecision = gmuOracle.getDecimalPercision();
    return _scalePriceByDigits(gmuPrice, gmuPricePrecision);
  }

  function _fetchChainlinkPrice(AggregatorV3Interface agg)
    internal
    view
    returns (uint256)
  {
    ChainlinkResponse memory chainlinkResponse = _getCurrentChainlinkResponse(
      agg
    );
    uint256 scaledChainlinkPrice = _scalePriceByDigits(
      uint256(chainlinkResponse.answer),
      chainlinkResponse.decimals
    );
    return scaledChainlinkPrice;
  }

  function _getCurrentChainlinkResponse(AggregatorV3Interface agg)
    internal
    view
    returns (ChainlinkResponse memory chainlinkResponse)
  {
    // First, try to get current decimal precision:
    try agg.decimals() returns (uint8 decimals) {
      // If call to Chainlink succeeds, record the current decimal precision
      chainlinkResponse.decimals = decimals;
    } catch {
      // If call to Chainlink aggregator reverts, return a zero response with success = false
      return chainlinkResponse;
    }

    // Secondly, try to get latest price data:
    try agg.latestRoundData() returns (
      uint80 roundId,
      int256 answer,
      uint256, /* startedAt */
      uint256 timestamp,
      uint80 /* answeredInRound */
    ) {
      // If call to Chainlink succeeds, return the response and success = true
      chainlinkResponse.roundId = roundId;
      chainlinkResponse.answer = answer;
      chainlinkResponse.timestamp = timestamp;
      chainlinkResponse.success = true;
      return chainlinkResponse;
    } catch {
      // If call to Chainlink aggregator reverts, return a zero response with success = false
      return chainlinkResponse;
    }
  }
}
