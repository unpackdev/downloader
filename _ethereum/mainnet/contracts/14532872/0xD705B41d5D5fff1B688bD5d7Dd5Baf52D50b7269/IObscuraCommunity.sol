// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IObscuraCommunity {
    function mintTo(
        address to,
        uint256 projectId,
        uint256 tokenId
    ) external;

    function mintBatch( // passes burden to the minter to allocate the tokenIds
        address to,
        uint256 projectId,
        uint32[] memory  tokenIDs
    ) external;

    function setProjectCID(uint256 projectId, string calldata cid) external;

    function setTokenCID(uint256 tokenId, string calldata cid) external;

    function setDefaultPendingCID(string calldata defaultPendingCID) external;

    function createProject(
        string memory artist,
        uint16 photosPerArtist,
        string memory cid
    ) external;
}
