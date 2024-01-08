// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "./IAggregator.sol";

interface IAggregatorsFactory {
    function aggregatorsById(uint256 id) external view returns (address);
}
