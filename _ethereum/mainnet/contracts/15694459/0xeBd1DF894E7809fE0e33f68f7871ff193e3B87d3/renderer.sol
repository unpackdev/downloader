// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface renderer {
    function tokenURI(uint256 id) external view returns (string memory);
}
