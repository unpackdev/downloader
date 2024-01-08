// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ICryptoPunks {
    function punkIndexToAddress(uint256 tokenId) external view returns (address);
}