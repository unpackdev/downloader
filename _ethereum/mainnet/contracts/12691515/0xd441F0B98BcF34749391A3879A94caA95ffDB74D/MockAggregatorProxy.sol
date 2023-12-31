// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./AggregatorProxy.sol";

contract MockAggregatorProxy is AggregatorProxy {
    constructor(
        address aggregatorAddress
    ) AggregatorProxy(aggregatorAddress) {} // solhint-disable-line
}
