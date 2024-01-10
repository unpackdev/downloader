// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChonkySet {
    function getSetId(uint256 _genome) external pure returns (uint256);

    function getSetFromGenome(uint256 _genome)
        external
        pure
        returns (string memory);

    function getSetFromId(uint256 _setId) external pure returns (string memory);
}
