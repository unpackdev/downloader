// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import "./FeedRegistryInterface.sol";
import "./OracleInterface.sol";
import "./OpynPricerInterface.sol";
import "./ChainlinkLib.sol";
import "./SafeCast.sol";

/**
 * @notice A Pricer contract for all assets available on the Chainlink Feed Registry
 */
contract ChainlinkRegistryPricer is OpynPricerInterface {
    using SafeCast for int256;

    /// @notice the opyn oracle address
    OracleInterface public immutable oracle;
    /// @notice the chainlink feed registry
    FeedRegistryInterface public immutable registry;
    /// @dev weth address
    address public immutable weth;
    /// @dev wbtc address
    address public immutable wbtc;

    /**
     * @param _oracle Opyn Oracle address
     */
    constructor(
        address _oracle,
        address _registry,
        address _weth,
        address _wbtc
    ) public {
        require(_oracle != address(0), "ChainlinkRegistryPricer: Cannot set 0 address as oracle");
        require(_registry != address(0), "ChainlinkRegistryPricer: Cannot set 0 address as registry");
        require(_weth != address(0), "ChainlinkRegistryPricer: Cannot set 0 address as weth");
        require(_wbtc != address(0), "ChainlinkRegistryPricer: Cannot set 0 address as wbtc");

        oracle = OracleInterface(_oracle);
        registry = FeedRegistryInterface(_registry);
        weth = _weth;
        wbtc = _wbtc;
    }

    /**
     * @notice sets the expiry prices in the oracle without providing a roundId
     * @dev uses more 2.6x more gas compared to passing in a roundId
     * @param _assets assets to set the price for
     * @param _expiryTimestamps expiries to set a price for
     */
    function setExpiryPriceInOracle(address[] calldata _assets, uint256[] calldata _expiryTimestamps) external {
        for (uint256 i = 0; i < _assets.length; i++) {
            (, uint256 price) = ChainlinkLib.getRoundData(
                registry.getFeed(ChainlinkLib.getBase(_assets[i], weth, wbtc), ChainlinkLib.QUOTE),
                _expiryTimestamps[i]
            );
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
                ChainlinkLib.validateRoundId(
                    registry.getFeed(ChainlinkLib.getBase(_assets[i], weth, wbtc), ChainlinkLib.QUOTE),
                    _expiryTimestamps[i],
                    _roundIds[i]
                )
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
        address base = ChainlinkLib.getBase(_asset, weth, wbtc);
        int256 answer = registry.latestAnswer(base, ChainlinkLib.QUOTE);
        require(answer > 0, "ChainlinkRegistryPricer: price is lower than 0");
        // chainlink's answer is already 1e8
        // no need to safecast since we already check if its > 0
        return ChainlinkLib.scaleToBase(uint256(answer), registry.decimals(base, ChainlinkLib.QUOTE));
    }

    /**
     * @notice get historical chainlink price
     * @param _asset asset that this pricer will get a price for
     * @param _roundId chainlink round id
     * @return round price and timestamp
     */
    function getHistoricalPrice(address _asset, uint80 _roundId) external view override returns (uint256, uint256) {
        address base = ChainlinkLib.getBase(_asset, weth, wbtc);
        (, int256 price, , uint256 roundTimestamp, ) = registry.getRoundData(base, ChainlinkLib.QUOTE, _roundId);
        return (
            ChainlinkLib.scaleToBase(price.toUint256(), registry.decimals(base, ChainlinkLib.QUOTE)),
            roundTimestamp
        );
    }
}
