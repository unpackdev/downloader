// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./ICToken.sol";

interface IPriceOracle {
    function getUnderlyingPrice(ICToken cToken) external view returns (uint256);
}
