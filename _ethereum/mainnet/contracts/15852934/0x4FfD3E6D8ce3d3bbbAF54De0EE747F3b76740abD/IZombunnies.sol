// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IZombunnies {
    function mintTokens(address _mintTo, uint256 quantity)
        external
        returns (bool);

    function cap() external view returns (uint256);

    function getMintedZombunnies() external view returns (uint256);
}
