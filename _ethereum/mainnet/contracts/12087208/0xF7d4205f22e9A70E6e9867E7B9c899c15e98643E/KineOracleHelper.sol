// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./KineOracle.sol";
import "./SafeMath.sol";
import "./UniswapV2Library.sol";

contract KineOracleHelper is Ownable {
    using SafeMath for uint;
    using FixedPoint for *;

    address public factory;
    bytes32 constant ethHash = keccak256(abi.encodePacked("ETH"));
    bytes32 constant mcdHash = keccak256(abi.encodePacked("MCD"));

    constructor(address factory_) public {
        factory = factory_;
    }

    function setNewFactory(address factory_) public onlyOwner {
        factory = factory_;
    }

    function getPairAddress(address tokenA, address tokenB) public view returns (address){
        return UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }

    function getCurrentCumulativePrices(address pair) public view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp){
        return UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
    }

    function currentCumulativePriceInOracleCal(address oracle, string memory symbol) public view returns (uint) {
        KineOracle oracleInstance = KineOracle(oracle);
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        PriceConfig.KTokenConfig memory config = oracleInstance.getKTokenConfigBySymbolHash(symbolHash);
        (uint cumulativePrice0, uint cumulativePrice1,) = UniswapV2OracleLibrary.currentCumulativePrices(config.uniswapMarket);
        if (config.isUniswapReversed) {
            return cumulativePrice1;
        } else {
            return cumulativePrice0;
        }
    }

    function pokeWindowValuesView(address oracle, string memory symbol) public view returns (uint, uint, uint, uint){
        KineOracle oracleInstance = KineOracle(oracle);
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        uint cumulativePrice = currentCumulativePriceInOracleCal(oracle, symbol);

        (uint timestamp, uint acc) = oracleInstance.newObservations(symbolHash);
        KineOracle.Observation memory newObservation = KineOracle.Observation(timestamp, acc);

        (uint oldObservationTs, uint oldObservationAcc) = oracleInstance.oldObservations(symbolHash);

        uint timeElapsed = block.timestamp - newObservation.timestamp;
        uint anchorPeriod = oracleInstance.anchorPeriod();
        if (timeElapsed >= anchorPeriod) {
            (oldObservationTs, oldObservationAcc) = oracleInstance.newObservations(symbolHash);
        }
        return (cumulativePrice, oldObservationAcc, oldObservationTs, timeElapsed);
    }

    function fetchEthPrice(address oracle) public view returns (uint){
        KineOracle oracleInstance = KineOracle(oracle);
        bytes32 symbolHash = keccak256(abi.encodePacked('ETH'));
        PriceConfig.KTokenConfig memory config = oracleInstance.getKTokenConfigBySymbolHash(symbolHash);
        (uint nowCumulativePrice, uint oldCumulativePrice, uint oldTimestamp,) = pokeWindowValuesView(oracle, 'ETH');

        // This should be impossible, but better safe than sorry
        require(block.timestamp > oldTimestamp, "now must come after before");
        uint timeElapsed = block.timestamp - oldTimestamp;

        // Calculate uniswap time-weighted average price
        // Underflow is a property of the accumulators: https://uniswap.org/audit.html#orgc9b3190
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(uint224((nowCumulativePrice - oldCumulativePrice) / timeElapsed));
        uint rawUniswapPriceMantissa = priceAverage.decode112with18();
        uint unscaledPriceMantissa = SafeMath.mul(rawUniswapPriceMantissa, oracleInstance.ethBaseUnit());
        uint anchorPrice;

        // Adjust rawUniswapPrice according to the units of the non-ETH asset
        // In the case of ETH, we would have to scale by 1e6 / USDC_UNITS, but since baseUnit2 is 1e6 (USDC), it cancels
        anchorPrice = SafeMath.mul(unscaledPriceMantissa, config.baseUnit) / oracleInstance.ethBaseUnit() / oracleInstance.expScale();
        return anchorPrice;
    }

    function fetchAnchorPriceView(address oracle, string memory symbol) public view returns (uint, uint, uint, uint){
        KineOracle oracleInstance = KineOracle(oracle);
        uint rawUniswapPriceMantissa;
        uint timeElapsed;
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        PriceConfig.KTokenConfig memory config = oracleInstance.getKTokenConfigBySymbolHash(symbolHash);
        {
            (uint nowCumulativePrice, uint oldCumulativePrice, uint oldTimestamp,) = pokeWindowValuesView(oracle, symbol);
            timeElapsed = block.timestamp - oldTimestamp;
            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(uint224((nowCumulativePrice - oldCumulativePrice) / timeElapsed));
            rawUniswapPriceMantissa = priceAverage.decode112with18();
        }

        uint conversionFactor;
        if (symbolHash == ethHash) {
            conversionFactor = oracleInstance.ethBaseUnit();
        } else {
            conversionFactor = fetchEthPrice(oracle);
        }
        uint unscaledPriceMantissa = SafeMath.mul(rawUniswapPriceMantissa, conversionFactor);

        uint anchorPrice;
        // Adjust rawUniswapPrice according to the units of the non-ETH asset
        // In the case of ETH, we would have to scale by 1e6 / USDC_UNITS, but since baseUnit2 is 1e6 (USDC), it cancels
        anchorPrice = SafeMath.mul(unscaledPriceMantissa, config.baseUnit) / oracleInstance.ethBaseUnit() / oracleInstance.expScale();

        return (timeElapsed, rawUniswapPriceMantissa, conversionFactor, anchorPrice);
    }

    // returns the timestamp, symbol and price
    function fetchOwnedPriceAndTs(address oracle, string memory symbol) public view returns (uint, string memory, uint){
        KineOracle oracleInstance = KineOracle(oracle);
        uint timestamp = oracleInstance.mcdLastUpdatedAt();
        uint price = oracleInstance.price(symbol);
        return (timestamp, symbol, price);
    }
}