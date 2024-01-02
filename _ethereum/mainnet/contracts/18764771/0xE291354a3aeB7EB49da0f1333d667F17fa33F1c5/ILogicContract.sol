// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ILogicContract {
    event EditionCreated(
        address indexed contractAddress,
        uint256 editionId,
        uint24 maxSupply,
        string baseURI,
        uint24 contractMintPrice,
        bool editionned
    );
    event EditionUpdated(
        address indexed contractAddress,
        uint256 editionId,
        uint256 maxSupply,
        string baseURI
    );
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function editionedTokenId(
        uint256 editionId,
        uint256 tokenNumber
    ) external view returns (uint256 tokenId);

    function createEdition(
        string calldata _baseURI,
        uint24 _maxSupply,
        uint24 _publicMintPriceInFinney,
        uint32 _publicMintStartTS,
        uint32 _publicMintEndTS,
        uint8 _maxMintPerWallet,
        bool _perTokenMetadata,
        uint8 _burnableEditionId,
        uint8 _amountToBurn
    ) external returns (uint256);

    function updateEditionBaseURI(
        uint256 editionId,
        string calldata _baseURI
    ) external;

    function updateEdition(
        uint256 editionId,
        uint24 _publicMintPriceInFinney,
        uint32 _publicMintStartTS,
        uint32 _publicMintEndTS,
        uint8 _maxMintPerWallet,
        uint24 _maxSupply,
        bool _perTokenMetadata
    ) external;
}
