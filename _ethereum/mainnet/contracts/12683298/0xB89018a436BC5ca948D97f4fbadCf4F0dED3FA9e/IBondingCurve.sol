// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICurve.sol";

interface IBondingCurve is ICurve {
    function getFixedPrice() external view returns (uint256);
}
