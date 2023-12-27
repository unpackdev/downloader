// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IJokerClub {
    function mint(uint256 quantity, bytes32[] calldata merkleProof, address recipient) external payable;

    function balanceOf(address owner) external view returns (uint256);

    function price() external view returns (uint256);
}
