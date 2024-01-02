// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IMCC {
    function burn(uint256) external;

    function mint(address, uint256) external;
}
