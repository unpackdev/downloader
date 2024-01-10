// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import "./AggregatorV2V3Interface.sol";
import "./OracleInterface.sol";
import "./OpynPricerInterface.sol";
import "./ChainlinkLib.sol";
import "./Ownable.sol";
import "./SafeCast.sol";

/**
 * @notice A Pricer contract for many assets as reported by Chainlink
 */
contract ChainlinkPricer is Ownable, OpynPricerInterface {
    using SafeCast for int256;

    /// @notice the opyn oracle address
    OracleInterface public immutable oracle;
    /// @notice the aggregators for each asset
    mapping(address => AggregatorV2V3Interface) public aggregators;

    /// @notice emits an event when the aggregator is updated for an asset
    event AggregatorUpdated(address indexed asset, address indexed aggregator);

    /**
     * @param _oracle Opyn Oracle address
     */
    constructor(address _oracle) public {
        require(_oracle != address(0), "ChainlinkPricer: Cannot set 0 address as oracle");

        oracle = OracleInterface(_oracle);
    }

    /**
     * @notice sets the aggregators for the assets, allows overriding existing aggregators
     * @dev can only be called by the owner
     * @param _assets assets to set the aggregator for
     * @param _aggregators chainlink aggregators for the assets
     */
    function setAggregators(address[] calldata _assets, address[] calldata _aggregators) external onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            require(_assets[i] != address(0), "ChainlinkPricer: Cannot set 0 address as asset");
            aggregators[_assets[i]] = AggregatorV2V3Interface(_aggregators[i]);

            emit AggregatorUpdated(_assets[i], _aggregators[i]);
        }
    }

    /**
     * @notice sets the expiry prices in the oracle without providing a roundId
     * @dev uses more 2.6x more gas compared to passing in a roundId
     * @param _assets assets to set the price for
     * @param _expiryTimestamps expiries to set a price for
     */
    function setExpiryPriceInOracle(address[] calldata _assets, uint256[] calldata _expiryTimestamps) external {
        for (uint256 i = 0; i < _assets.length; i++) {
            (, uint256 price) = ChainlinkLib.getRoundData(aggregators[_assets[i]], _expiryTimestamps[i]);
            oracle.setExpiryPrice(_assets[i], _expiryTimestamps[i], price);
        }
    }

    /**
     * @notice sets the expiry prices in the oracle
     * @dev a roundId must be provided to confirm price validity, which is the first Chainlink price provided after the expiryTimestamp
     * @param _assets assets to set the price for
     * @param _expiryTimestamps expiries to set a price for
     * @param _roundIds the first roundId after each expiryTimestamp
     */
    function setExpiryPriceInOracleRoundId(
        address[] calldata _assets,
        uint256[] calldata _expiryTimestamps,
        uint80[] calldata _roundIds
    ) external {
        for (uint256 i = 0; i < _assets.length; i++) {
            oracle.setExpiryPrice(
                _assets[i],
                _expiryTimestamps[i],
                ChainlinkLib.validateRoundId(aggregators[_assets[i]], _expiryTimestamps[i], _roundIds[i])
            );
        }
    }

    /**
     * @notice get the live price for the asset
     * @dev overides the getPrice function in OpynPricerInterface
     * @param _asset asset that this pricer will get a price for
     * @return price of the asset in USD, scaled by 1e8
     */
    function getPrice(address _asset) external view override returns (uint256) {
        AggregatorV2V3Interface _aggregator = aggregators[_asset];
        int256 answer = _aggregator.latestAnswer();
        require(answer > 0, "ChainlinkPricer: price is lower than 0");
        // chainlink's answer is already 1e8
        // no need to safecast since we already check if its > 0
        return ChainlinkLib.scaleToBase(uint256(answer), _aggregator.decimals());
    }

    /**
     * @notice get historical chainlink price
     * @param _asset asset that this pricer will get a price for
     * @param _roundId chainlink round id
     * @return round price and timestamp
     */
    function getHistoricalPrice(address _asset, uint80 _roundId) external view override returns (uint256, uint256) {
        AggregatorV2V3Interface _aggregator = aggregators[_asset];
        (, int256 price, , uint256 roundTimestamp, ) = _aggregator.getRoundData(_roundId);
        return (ChainlinkLib.scaleToBase(price.toUint256(), _aggregator.decimals()), roundTimestamp);
    }
}
