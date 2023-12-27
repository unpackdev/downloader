// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenUriProvider {
    function maxSupply() external view returns (uint256);

    function startId() external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
