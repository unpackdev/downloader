// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./AggregatorV3Interface.sol";

/// @title Abstract Price Contract
/// @notice Handles the hassles of calculating the same price formula for each xAsset
/// @dev Not deployable. This has to be implemented by any xAssetPrice contract
abstract contract Price {
    using SafeMath for uint256;

    /// @dev Specify the underlying asset of each xAssetPrice contract
    address public underlyingAssetAddress;
    address public underlyingPriceFeedAddress;
    address public usdcPriceFeedAddress;

    uint256 constant FACTOR = 1e18;
    uint256 constant PRICE_DECIMALS_CORRECTION = 1e6;

    function getAssetHeld() public view virtual returns (uint256);

    /// @notice Anyone can know how much certain xAsset is worthy in USDC terms
    /// @dev This relies on the getAssetHeld function implemented by each xAssetPrice contract
    /// @dev Prices are handling 12 decimals
    /// @return capacity (uint256) How much an xAsset is worthy on USDC terms
    function getPrice() external view returns (uint256) {
        uint256 assetHeld = getAssetHeld(); // assetTotalSupply * 1e18
        uint256 assetTotalSupply = IERC20(underlyingAssetAddress).totalSupply(); // It comes with 18 decimals

        uint256 assetDecimals = AggregatorV3Interface(underlyingPriceFeedAddress).decimals(); // Depends on the aggregator decimals. Chainlink usually uses 12 decimals
        (
            uint80 roundIDUsd,
            int256 assetUsdPrice,
            ,
            uint256 timeStampUsd,
            uint80 answeredInRoundUsd
        ) = AggregatorV3Interface(underlyingPriceFeedAddress).latestRoundData();
        require(timeStampUsd != 0, "ChainlinkOracle::getLatestAnswer: round is not complete");
        require(answeredInRoundUsd >= roundIDUsd, "ChainlinkOracle::getLatestAnswer: stale data");
        uint256 usdPrice = assetHeld // 1e18
            .mul(uint256(assetUsdPrice))
            .div(assetTotalSupply)
            .mul(10**(uint256(18).sub(assetDecimals)))
            .div(FACTOR); // Price value // 1e18 // 10^(18-assetDecimals)
        uint256 usdcDecimals = AggregatorV3Interface(usdcPriceFeedAddress).decimals();
        (
            uint80 roundIDUsdc,
            int256 usdcusdPrice,
            ,
            uint256 timeStampUsdc,
            uint80 answeredInRoundUsdc
        ) = AggregatorV3Interface(usdcPriceFeedAddress).latestRoundData();
        require(timeStampUsdc != 0, "ChainlinkOracle::getLatestAnswer: round is not complete");
        require(answeredInRoundUsdc >= roundIDUsdc, "ChainlinkOracle::getLatestAnswer: stale data");
        uint256 usdcPrice = usdPrice
            .mul(FACTOR)
            .div(uint256(usdcusdPrice))
            .div(10**(uint256(18).sub(usdcDecimals)))
            .div(PRICE_DECIMALS_CORRECTION);
        return usdcPrice;
    }
}
