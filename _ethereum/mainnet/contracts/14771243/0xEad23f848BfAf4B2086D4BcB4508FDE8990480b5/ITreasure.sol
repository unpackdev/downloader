// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ITreasure {
    function plunder(uint256 numMints) external payable;

    function status() external view returns (bool);

    function contractURI() external view returns (string memory);

    function reserved() external view returns (uint256);

    function price() external pure returns (uint256);
}
