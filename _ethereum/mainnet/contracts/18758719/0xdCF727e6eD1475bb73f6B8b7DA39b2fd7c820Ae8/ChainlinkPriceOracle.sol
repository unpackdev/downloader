// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import "./UtilLib.sol";

import "./IPriceFetcher.sol";
import "./LRTConfigRoleChecker.sol";

import "./Initializable.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface IAssetPriceFeed {
    // events
    event AssetPriceFeedUpdate(address indexed asset, address indexed priceFeed);

    function assetPriceFeed(address asset) external view returns (address);
}

/// @title ChainlinkPriceOracle Contract
/// @notice contract that fetches the exchange rate of assets from chainlink price feeds
contract ChainlinkPriceOracle is IPriceFetcher, IAssetPriceFeed, LRTConfigRoleChecker, Initializable {
    mapping(address asset => address priceFeed) public override assetPriceFeed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract
    /// @param lrtConfig_ LRT config address
    function initialize(address lrtConfig_) external initializer {
        UtilLib.checkNonZeroAddress(lrtConfig_);

        lrtConfig = ILRTConfig(lrtConfig_);
        emit UpdatedLRTConfig(lrtConfig_);
    }

    /// @notice Fetches Asset/ETH exchange rate
    /// @param asset the asset for which exchange rate is required
    /// @return assetPrice exchange rate of asset
    function getAssetPrice(address asset) external view onlySupportedAsset(asset) returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(assetPriceFeed[asset]);

        (, int256 price,,,) = priceFeed.latestRoundData();

        return uint256(price) * 1e18 / 10 ** uint256(priceFeed.decimals());
    }

    /// @dev add/update the price oracle of any supported asset
    /// @dev only LRTManager is allowed
    /// @param asset asset address for which oracle price feed needs to be added/updated
    /// @param priceFeed chainlink price feed contract which contains exchange rate info
    function updatePriceFeedFor(address asset, address priceFeed) external onlyLRTManager onlySupportedAsset(asset) {
        UtilLib.checkNonZeroAddress(priceFeed);
        assetPriceFeed[asset] = priceFeed;
        emit AssetPriceFeedUpdate(asset, priceFeed);
    }
}
