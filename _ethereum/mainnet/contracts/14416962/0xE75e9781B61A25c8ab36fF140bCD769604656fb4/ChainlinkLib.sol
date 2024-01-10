/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

import "./AggregatorV2V3Interface.sol";
import "./AggregatorV3Interface.sol";
import "./SafeMath.sol";

/**
 * @title ChainlinkLib
 * @author 10 Delta
 * @notice Library for interacting with Chainlink feeds
 */
library ChainlinkLib {
    using SafeMath for uint256;

    /// @dev base decimals
    uint256 internal constant BASE = 8;
    /// @dev offset for chainlink aggregator phases
    uint256 internal constant PHASE_OFFSET = 64;
    /// @dev eth address on the chainlink registry
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev btc address on the chainlink registry
    address internal constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    /// @dev usd address on the chainlink registry
    address internal constant USD = address(840);
    /// @dev quote asset address
    address internal constant QUOTE = USD;

    /**
     * @notice validates that a roundId matches a timestamp, reverts if invalid
     * @dev invalid if _roundId isn't the first roundId after _timestamp
     * @param _aggregator chainlink aggregator
     * @param _timestamp timestamp
     * @param _roundId the first roundId after timestamp
     * @return answer, the price at that roundId
     */
    function validateRoundId(
        AggregatorV2V3Interface _aggregator,
        uint256 _timestamp,
        uint80 _roundId
    ) internal view returns (uint256) {
        (, int256 answer, , uint256 updatedAt, ) = _aggregator.getRoundData(_roundId);
        // Validate round data
        require(answer >= 0 && updatedAt > 0, "ChainlinkLib: round not complete");
        // Check if the timestamp at _roundId is >= _timestamp
        require(_timestamp <= updatedAt, "ChainlinkLib: roundId too low");
        // If _roundId is greater than the lowest roundId for the current phase
        if (_roundId > uint80((uint256(_roundId >> PHASE_OFFSET) << PHASE_OFFSET) | 1)) {
            // Check if the timestamp at the previous roundId is <= _timestamp
            (bool success, bytes memory data) = address(_aggregator).staticcall(
                abi.encodeWithSelector(AggregatorV3Interface.getRoundData.selector, _roundId - 1)
            );
            // Skip checking the timestamp if getRoundData reverts
            if (success) {
                (, int256 lastAnswer, , uint256 lastUpdatedAt, ) = abi.decode(
                    data,
                    (uint80, int256, uint256, uint256, uint80)
                );
                // Skip checking the timestamp if the previous answer is invalid
                require(lastAnswer < 0 || _timestamp >= lastUpdatedAt, "ChainlinkLib: roundId too high");
            }
        }
        return uint256(answer);
    }

    /**
     * @notice gets the closest roundId to a timestamp
     * @dev the returned roundId is the first roundId after _timestamp
     * @param _aggregator chainlink aggregator
     * @param _timestamp timestamp
     * @return roundId, the roundId for the timestamp (its timestamp will be >= _timestamp)
     * @return answer, the price at that roundId
     */
    function getRoundData(AggregatorV2V3Interface _aggregator, uint256 _timestamp)
        internal
        view
        returns (uint80, uint256)
    {
        (uint80 maxRoundId, int256 answer, , uint256 maxUpdatedAt, ) = _aggregator.latestRoundData();
        // Check if the latest timestamp is >= _timestamp
        require(_timestamp <= maxUpdatedAt, "ChainlinkLib: timestamp too high");
        // Get the lowest roundId for the current phase
        uint80 minRoundId = uint80((uint256(maxRoundId >> PHASE_OFFSET) << PHASE_OFFSET) | 1);
        // Return if the latest roundId equals the lowest roundId
        if (minRoundId == maxRoundId) {
            require(answer >= 0, "ChainlinkLib: max round not complete");
            return (maxRoundId, uint256(answer));
        }
        uint256 minUpdatedAt;
        (, answer, , minUpdatedAt, ) = _aggregator.getRoundData(minRoundId);
        (uint80 midRoundId, uint256 midUpdatedAt) = (minRoundId, minUpdatedAt);
        uint256 _maxRoundId = maxRoundId; // Save maxRoundId for later use
        // Return the lowest roundId if the timestamp at the lowest roundId is >= _timestamp
        if (minUpdatedAt >= _timestamp && answer >= 0 && minUpdatedAt > 0) {
            return (minRoundId, uint256(answer));
        } else if (minUpdatedAt < _timestamp) {
            // Binary search to find the closest roundId to _timestamp
            while (minRoundId <= maxRoundId) {
                midRoundId = uint80((uint256(minRoundId) + uint256(maxRoundId)) / 2);
                (, answer, , midUpdatedAt, ) = _aggregator.getRoundData(midRoundId);
                if (midUpdatedAt < _timestamp) {
                    minRoundId = midRoundId + 1;
                } else if (midUpdatedAt > _timestamp) {
                    maxRoundId = midRoundId - 1;
                } else if (answer < 0 || midUpdatedAt == 0) {
                    // Break if closest roundId is invalid
                    break;
                } else {
                    // Return if the closest roundId timestamp equals _timestamp
                    return (midRoundId, uint256(answer));
                }
            }
        }
        // If the timestamp at the closest roundId is less than _timestamp or if the closest roundId is invalid
        while (midUpdatedAt < _timestamp || answer < 0 || midUpdatedAt == 0) {
            require(midRoundId < _maxRoundId, "ChainlinkLib: exceeded max roundId");
            // Increment the closest roundId by 1 to ensure that the roundId timestamp > _timestamp
            midRoundId++;
            (, answer, , midUpdatedAt, ) = _aggregator.getRoundData(midRoundId);
        }
        return (midRoundId, uint256(answer));
    }

    /**
     * @notice scale aggregator response to base decimals (1e8)
     * @param _price aggregator price
     * @return price scaled to 1e8
     */
    function scaleToBase(uint256 _price, uint8 _aggregatorDecimals) internal pure returns (uint256) {
        if (_aggregatorDecimals > BASE) {
            _price = _price.div(10**(uint256(_aggregatorDecimals).sub(BASE)));
        } else if (_aggregatorDecimals < BASE) {
            _price = _price.mul(10**(BASE.sub(_aggregatorDecimals)));
        }

        return _price;
    }

    /**
     * @notice gets the base asset on the chainlink registry
     * @param _asset asset address
     * @param weth weth address
     * @param wbtc wbtc address
     * @return base asset address
     */
    function getBase(
        address _asset,
        address weth,
        address wbtc
    ) internal pure returns (address) {
        if (_asset == address(0)) {
            return _asset;
        } else if (_asset == weth) {
            return ETH;
        } else if (_asset == wbtc) {
            return BTC;
        } else {
            return _asset;
        }
    }
}
