// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "Admin.sol";

import "IChainlinkOracleProvider.sol";
import "ChainlinkAggregator.sol";

import "Errors.sol";
import "DecimalScale.sol";

contract ChainlinkOracleProvider is IChainlinkOracleProvider, Admin {
    using DecimalScale for uint256;

    uint256 public stalePriceDelay;

    mapping(address => address) public feeds;

    event FeedUpdated(address indexed asset, address indexed previousFeed, address indexed newFeed);

    constructor(address ethFeed) Admin(msg.sender) {
        feeds[address(0)] = ethFeed;
        stalePriceDelay = 2 hours;
    }

    /// @notice Allows to set Chainlink feeds
    /// @dev All feeds should be set relative to USD.
    /// This can only be called by governance
    function setFeed(address asset, address feed) external override onlyAdmin {
        address previousFeed = feeds[asset];
        require(feed != previousFeed, Error.INVALID_ARGUMENT);
        feeds[asset] = feed;
        emit FeedUpdated(asset, previousFeed, feed);
    }

    /**
     * @notice Sets the stake price delay value.
     * @param stalePriceDelay_ The new stale price delay to set.
     */
    function setStalePriceDelay(uint256 stalePriceDelay_) external override onlyAdmin {
        require(stalePriceDelay_ >= 1 hours, Error.INVALID_ARGUMENT);
        stalePriceDelay = stalePriceDelay_;
    }

    /// @inheritdoc IOracleProvider
    function getPriceETH(address asset) external view override returns (uint256) {
        return (getPriceUSD(asset) * 1e18) / getPriceUSD(address(0));
    }

    /// @inheritdoc IOracleProvider
    function getPriceUSD(address asset) public view override returns (uint256) {
        address feed = feeds[asset];
        require(feed != address(0), Error.ASSET_NOT_SUPPORTED);

        (, int256 answer, , uint256 updatedAt, ) = AggregatorV2V3Interface(feed).latestRoundData();

        require(block.timestamp <= updatedAt + stalePriceDelay, Error.STALE_PRICE);
        require(answer >= 0, Error.NEGATIVE_PRICE);

        uint256 price = uint256(answer);
        uint8 decimals = AggregatorV2V3Interface(feed).decimals();
        return price.scaleFrom(decimals);
    }
}
