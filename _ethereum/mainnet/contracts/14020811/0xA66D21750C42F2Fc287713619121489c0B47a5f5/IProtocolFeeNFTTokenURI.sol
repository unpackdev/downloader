// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

interface IProtocolFeeNFTTokenURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
