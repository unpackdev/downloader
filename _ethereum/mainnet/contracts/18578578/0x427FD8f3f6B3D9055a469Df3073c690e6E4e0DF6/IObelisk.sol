// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IObelisk {
    function getMultiplierOf(
        address account
    ) external view returns (uint256 multiplier, uint256 precision);
}
