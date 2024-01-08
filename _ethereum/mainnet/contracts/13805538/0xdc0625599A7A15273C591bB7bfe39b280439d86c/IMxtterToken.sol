// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMxtterToken {
    function mintToken(address to, string memory uri)
        external
        returns (uint256);

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external;

    function getTokenHash(uint256 tokenId) external view returns (bytes32);

    function setApprovalForAll(address operator, bool _approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
