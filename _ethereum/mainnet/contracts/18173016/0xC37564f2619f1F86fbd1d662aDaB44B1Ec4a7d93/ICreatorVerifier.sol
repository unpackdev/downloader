// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface ICreatorVerifier {
    event ClaimProceedsAndCreateEditions(address indexed originalNftContract, uint256 indexed originalNftTokenId);

    error CallerNotNftCreator(address nftContract, uint256 tokenId);

    function claimProceedsAndCreateEditions(
        address originalNftContract_,
        uint256 originalNftTokenId_,
        uint256 editionNftChainId_,
        string calldata collectionImageUri_,
        string calldata name_,
        string calldata symbol_
    ) external;

    function creatorRegistry() external view returns (address);

    function editionConverter() external view returns (address);
}
