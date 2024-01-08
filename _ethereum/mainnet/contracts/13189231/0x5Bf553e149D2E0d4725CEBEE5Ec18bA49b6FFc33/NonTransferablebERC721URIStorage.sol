// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";


abstract contract NonTransferablebERC721URIStorage is ERC721URIStorage {

    /**
     * @dev ERC721 transferFrom method override. This is a non-transferable NFT.
     * @param from Override
     * @param to Override
     * @param tokenId Override
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Non-transferable
        require(false);
    }

    /**
     * @dev ERC721 safeTransferFrom method override. This is a non-transferable NFT.
     * @param from Override
     * @param to Override
     * @param tokenId Override
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        // Non-transferable
        require(false);
    }

    /**
     * @dev ERC721 safeTransferFrom method override. This is a non-transferable NFT.
     * @param from Override
     * @param to Override
     * @param tokenId Override
     * @param _data Override
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        // Non-transferable
        require(false);
    }

    /**
     * @dev ERC721 setApprovalForAll method override. This is a non-transferable NFT.
     * @param operator Override
     * @param approved Override
     */
    function setApprovalForAll(address operator, bool approved) public override {
        // Non-transferable
        require(false);
    }
}
