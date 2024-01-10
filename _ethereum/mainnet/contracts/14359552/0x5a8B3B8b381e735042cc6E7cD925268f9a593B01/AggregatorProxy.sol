// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IAggregator.sol";

contract AggregatorProxy {

    function getAggregatorData(address _asset, IAggregator _aggregator) external returns (uint256, uint8) {
        if ((_aggregator.version()) == uint256(-1))
            return _aggregator.getAssetPrice(_asset);

        (, int256 _answer, , ,) = _aggregator.latestRoundData();
        return (_answer < 0 ? 0 : uint256(_answer), _aggregator.decimals());
    }
}