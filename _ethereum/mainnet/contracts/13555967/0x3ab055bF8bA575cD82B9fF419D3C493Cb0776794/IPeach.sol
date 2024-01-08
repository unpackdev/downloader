// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPeach {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}
