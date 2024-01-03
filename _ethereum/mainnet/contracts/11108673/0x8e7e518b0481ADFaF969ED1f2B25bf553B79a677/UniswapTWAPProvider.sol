// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./UniswapConfig.sol";
import "./UniswapLib.sol";


abstract contract UniswapTWAPProvider is UniswapConfig {
  using FixedPoint for *;
  using SafeMath for uint256;

  /// @notice The number of wei in 1 ETH
  uint public constant ethBaseUnit = 1e18;

  /// @notice A common scaling factor to maintain precision
  uint public constant expScale = 1e18;

  bytes32 internal constant cvpHash = keccak256(abi.encodePacked("CVP"));
  bytes32 internal constant ethHash = keccak256(abi.encodePacked("ETH"));
  bytes32 internal constant rotateHash = keccak256(abi.encodePacked("rotate"));

  /// @notice The event emitted when anchor price is updated
  event AnchorPriceUpdated(string symbol, uint anchorPrice, uint oldTimestamp, uint newTimestamp);

  /// @notice The event emitted when the uniswap window changes
  event UniswapWindowUpdated(bytes32 indexed symbolHash, uint oldTimestamp, uint newTimestamp, uint oldPrice, uint newPrice);

  struct Observation {
    uint timestamp;
    uint acc;
  }

  /// @notice The minimum amount of time in seconds required for the old uniswap price accumulator to be replaced
  uint public immutable anchorPeriod;

  /// @notice The old observation for each symbolHash
  mapping(bytes32 => Observation) public oldObservations;

  /// @notice The new observation for each symbolHash
  mapping(bytes32 => Observation) public newObservations;

  constructor(
    uint anchorPeriod_,
    TokenConfig[] memory configs
  ) public {
    anchorPeriod = anchorPeriod_;

    for (uint i = 0; i < configs.length; i++) {
      TokenConfig memory config = configs[i];
      require(config.baseUnit > 0, "baseUnit must be greater than zero");
      address uniswapMarket = config.uniswapMarket;
      if (config.priceSource == PriceSource.REPORTER) {
        require(uniswapMarket != address(0), "reported prices must have an anchor");
        bytes32 symbolHash = config.symbolHash;
        uint cumulativePrice = currentCumulativePrice(config);
        oldObservations[symbolHash].timestamp = block.timestamp;
        newObservations[symbolHash].timestamp = block.timestamp;
        oldObservations[symbolHash].acc = cumulativePrice;
        newObservations[symbolHash].acc = cumulativePrice;
        emit UniswapWindowUpdated(symbolHash, block.timestamp, block.timestamp, cumulativePrice, cumulativePrice);
      } else {
        require(uniswapMarket == address(0), "only reported prices utilize an anchor");
      }
    }
  }

  /**
    * @dev Fetches the current token/eth price accumulator from uniswap.
    */
  function currentCumulativePrice(TokenConfig memory config) internal view returns (uint) {
    (uint cumulativePrice0, uint cumulativePrice1,) = UniswapV2OracleLibrary.currentCumulativePrices(config.uniswapMarket);
    if (config.isUniswapReversed) {
      return cumulativePrice1;
    } else {
      return cumulativePrice0;
    }
  }

  /**
   * @dev Fetches the current eth/usd price from uniswap, with 6 decimals of precision.
   *  Conversion factor is 1e18 for eth/usdc market, since we decode uniswap price statically with 18 decimals.
   */
  function fetchEthPrice() internal returns (uint) {
    return fetchAnchorPrice("ETH", getTokenConfigBySymbolHash(ethHash), ethBaseUnit);
  }

  function fetchCvpPrice(uint256 ethPrice) internal returns (uint) {
    return fetchAnchorPrice("CVP", getTokenConfigBySymbolHash(cvpHash), ethPrice);
  }

  /**
   * @dev Fetches the current token/usd price from uniswap, with 6 decimals of precision.
   * @param conversionFactor 1e18 if seeking the ETH price, and a 6 decimal ETH-USDC price in the case of other assets
   */
  function fetchAnchorPrice(string memory symbol, TokenConfig memory config, uint conversionFactor) internal virtual returns (uint) {
    (uint nowCumulativePrice, uint oldCumulativePrice, uint oldTimestamp) = pokeWindowValues(config);

    // This should be impossible, but better safe than sorry
    require(block.timestamp > oldTimestamp, "now must come after before");
    uint timeElapsed = block.timestamp - oldTimestamp;

    // Calculate uniswap time-weighted average price
    // Underflow is a property of the accumulators: https://uniswap.org/audit.html#orgc9b3190
    FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(uint224((nowCumulativePrice - oldCumulativePrice) / timeElapsed));
    uint rawUniswapPriceMantissa = priceAverage.decode112with18();
    uint unscaledPriceMantissa = mul(rawUniswapPriceMantissa, conversionFactor);
    uint anchorPrice;

    // Adjust rawUniswapPrice according to the units of the non-ETH asset
    // In the case of ETH, we would have to scale by 1e6 / USDC_UNITS, but since baseUnit2 is 1e6 (USDC), it cancels
    if (config.isUniswapReversed) {
      // unscaledPriceMantissa * ethBaseUnit / config.baseUnit / expScale, but we simplify bc ethBaseUnit == expScale
      anchorPrice = unscaledPriceMantissa / config.baseUnit;
    } else {
      anchorPrice = mul(unscaledPriceMantissa, config.baseUnit) / ethBaseUnit / expScale;
    }

    emit AnchorPriceUpdated(symbol, anchorPrice, oldTimestamp, block.timestamp);

    return anchorPrice;
  }

  /**
   * @dev Get time-weighted average prices for a token at the current timestamp.
   *  Update new and old observations of lagging window if period elapsed.
   */
  function pokeWindowValues(TokenConfig memory config) internal returns (uint, uint, uint) {
    bytes32 symbolHash = config.symbolHash;
    uint cumulativePrice = currentCumulativePrice(config);

    Observation memory newObservation = newObservations[symbolHash];

    // Update new and old observations if elapsed time is greater than or equal to anchor period
    uint timeElapsed = block.timestamp - newObservation.timestamp;
    if (timeElapsed >= anchorPeriod) {
      oldObservations[symbolHash].timestamp = newObservation.timestamp;
      oldObservations[symbolHash].acc = newObservation.acc;

      newObservations[symbolHash].timestamp = block.timestamp;
      newObservations[symbolHash].acc = cumulativePrice;
      emit UniswapWindowUpdated(config.symbolHash, newObservation.timestamp, block.timestamp, newObservation.acc, cumulativePrice);
    }
    return (cumulativePrice, oldObservations[symbolHash].acc, oldObservations[symbolHash].timestamp);
  }

  /// @dev Overflow proof multiplication
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) return 0;
    uint c = a * b;
    require(c / a == b, "multiplication overflow");
    return c;
  }
}
