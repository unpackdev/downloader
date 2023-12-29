// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IPart {
    function mintPart(address to, uint256 quantity) external returns(uint256, uint256);
}