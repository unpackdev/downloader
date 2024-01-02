// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// File: contracts/ETHtoUSDT.sol



pragma solidity ^0.8.2;


/// @title ETH/USD to ETH/USDT Chainlink Price Converter
/// @notice Deploys a contract that converts ETH/USD Chainlink price feed to ETH/USDT
contract ETHtoUSDT {

    address public immutable ETH_USD_PRICEFEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public immutable USDT_USD_PRICEFEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    uint8 public immutable DECIMALS = 8;

    function getDerivedPrice() public view returns (int256) {
        // Retrieves Decimals and Price from ETH/USD price feed
        int256 decimals = int256(10 ** uint256(DECIMALS));
        (, int256 ethusdPrice, , , ) = AggregatorV3Interface(ETH_USD_PRICEFEED).latestRoundData();
        uint8 ethusdDecimals = AggregatorV3Interface(ETH_USD_PRICEFEED).decimals();
        ethusdPrice = scalePrice(ethusdPrice, ethusdDecimals, DECIMALS);

        // Retrieves Decimals and Price from USDT/USD price feed
        (, int256 usdtusdPrice, , , ) = AggregatorV3Interface(USDT_USD_PRICEFEED).latestRoundData();
        uint8 usdtusdDecimals = AggregatorV3Interface(USDT_USD_PRICEFEED).decimals();
        usdtusdPrice = scalePrice(usdtusdPrice, usdtusdDecimals, DECIMALS);

        return (ethusdPrice * decimals) / usdtusdPrice;
    }

    function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }
}