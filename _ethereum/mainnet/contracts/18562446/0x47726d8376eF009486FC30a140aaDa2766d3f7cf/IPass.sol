// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPass {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}