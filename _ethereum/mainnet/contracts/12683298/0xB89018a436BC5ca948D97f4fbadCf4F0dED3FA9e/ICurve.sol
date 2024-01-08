// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurve {
    function getY(uint256 x) external view returns (uint256);
}
