// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "EnumerableSet.sol";
import "Governable.sol";

import "IUSDPriceOracle.sol";
import "ChainlinkAggregator.sol";

import "Errors.sol";
import "DecimalScale.sol";

abstract contract BaseChainlinkPriceOracle is IUSDPriceOracle, Governable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using DecimalScale for uint256;

    uint256 public constant MAX_LAG = 86400;

    EnumerableSet.AddressSet internal _supportedAssets;
    mapping(address => address) public feeds;

    constructor(address _governor) Governable(_governor) {}

    function listSupportedAssets() external view returns (address[] memory) {
        return _supportedAssets.values();
    }

    function _getLatestRoundData(address feed)
        internal
        view
        returns (
            uint80 roundId,
            uint256 price,
            uint256 updatedAt
        )
    {
        int256 answer;
        (roundId, answer, , updatedAt, ) = AggregatorV3Interface(feed).latestRoundData();
        require(block.timestamp <= updatedAt + MAX_LAG, Errors.STALE_PRICE);
        require(answer >= 0, Errors.NEGATIVE_PRICE);
        price = uint256(answer);
    }
}
