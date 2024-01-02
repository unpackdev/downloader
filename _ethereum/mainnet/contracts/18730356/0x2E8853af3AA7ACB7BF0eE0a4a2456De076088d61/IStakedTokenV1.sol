// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Stats.sol";
import "./ISystemRegistry.sol";

interface IStakedTokenV1 {
    function exchangeRate() external view returns (uint256 _exchangeRate);
}
