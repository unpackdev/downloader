// contracts/F3K721.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface F3K721 {
    function mintTokens(address to, uint256 count) external;

    function setBaseURI(string calldata newbaseURI) external;

    function nextTokenId() external view returns (uint256);
}