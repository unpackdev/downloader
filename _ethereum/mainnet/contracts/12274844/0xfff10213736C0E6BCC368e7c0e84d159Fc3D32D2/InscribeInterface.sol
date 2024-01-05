pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

interface InscribeInterface {
    /**
     * @dev Emitted when an 'owner' gives an 'inscriber' one time approval to add or remove an inscription for
     * the 'tokenId' at 'nftAddress'.
     */
    event Approval(address indexed owner, address indexed inscriber, address indexed nftAddress, uint256 tokenId);
    
    // Emitted when an 'owner' gives or removes an 'operator' approval to add or remove inscriptions to all of their NFTs.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Emitted when an inscription is added to an NFT at 'nftAddress' with 'tokenId'
    event InscriptionAdded(uint256 indexed inscriptionId, 
                            address indexed nftAddress,
                            uint256 tokenId, 
                            address indexed inscriber, 
                            bytes32 contentHash);

    // Emitted when an inscription is removed from an NFT at 'nftAddress' with 'tokenId'
    event InscriptionRemoved(uint256 indexed inscriptionId, 
                            address indexed nftAddress, 
                            uint256 tokenId, 
                            address indexed inscriber);

    /**
     * @dev Fetches the inscriber for the inscription at `inscriptionId`
     */
    function getInscriber(uint256 inscriptionId) external view returns (address);

    /**
     * @dev Verifies that `inscriptionId` is inscribed to the NFT at `nftAddress`, `tokenId`
     */
    function verifyInscription(uint256 inscriptionId, address nftAddress, uint256 tokenId) external view returns (bool);

    /**
     * @dev Fetches the nonce used while signing a signature.
     * Note: If a user signs multiple times on the same NFT, only one sig will go through.
     */
    function getNonce(address inscriber, address nftAddress, uint256 tokenId) external view returns (uint256);

     /**
     * @dev Fetches the inscriptionURI at inscriptionId
     * 
     * Requirements:
     *
     * - `inscriptionId` inscriptionId must exist
     * 
     */  
    function getInscriptionURI(uint256 inscriptionId) external view returns (string memory inscriptionURI);

    /**
     * @dev Gives `inscriber` a one time approval to add or remove an inscription for `tokenId` at `nftAddress`
     */
    function approve(address to, address nftAddress, uint256 tokenId) external;

    /*
    * @dev Returns the `address` approved for the `tokenId` at `nftAddress`
    */
    function getApproved(address nftAddress, uint256 tokenId) external view returns (address);
    
    /**
     * @dev Similar to the ERC721 implementation, Approve or remove `operator` as an operator for the caller.
     * Operators can modify any inscription for any NFT owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;
    
    /**
     * @dev Returns if the `operator` is allowed to inscribe or remove inscriptions for all NFTs owned by `owner`
     *
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Adds an inscription on-chain to the specified NFT. This is mainly used to sign your own NFTs or for 
     *      other smart contracts to add inscription functionality.
     * @param nftAddress            The NFT contract address
     * @param tokenId               The tokenId of the NFT that is being signed
     * @param contentHash           A hash of the content. This hash will not change and will be used to verify the contents in the frontend. 
     *                              This hash must be hosted by inscription operators at the baseURI in order to be considered a valid inscription.
     * @param baseUriId             The id of the inscription operator
     * 
     * Requirements:
     *
     * - `tokenId` The user calling this method must own the `tokenId` at `nftAddress` or has been approved
     * 
     */
    function addInscriptionWithNoSig(
        address nftAddress,
        uint256 tokenId,
        bytes32 contentHash,
        uint256 baseUriId
    ) external;
    
    /**
     * @dev Adds an inscription on-chain to the specified NFT. Call this method if you are using an inscription operator.
     * @param nftAddress            The NFT contract address
     * @param tokenId               The tokenId of the NFT that is being signed
     * @param inscriber             The address of the inscriber
     * @param contentHash           A hash of the content. This hash will not change and will be used to verify the contents in the frontend.
     *                              This hash must be hosted by inscription operators at the baseURI in order to be considered a valid inscription.
     * @param baseUriId             The id of the inscription operator
     * @param nonce                 A unique value to ensure every sig is different. Get this value by calling the function `getNonce`
     * @param sig                   Signature of the hash, signed by the inscriber
     * 
     * Requirements:
     *
     * - `tokenId` The user calling this method must own the `tokenId` at `nftAddress` or has been approved
     * 
     */
    function addInscriptionWithBaseUriId(
        address nftAddress,
        uint256 tokenId,
        address inscriber,
        bytes32 contentHash,
        uint256 baseUriId,
        uint256 nonce,
        bytes calldata sig
    ) external;

    
    /**
     * @dev Adds an inscription on-chain to the specified nft. Call this method if you have a specified inscription URI.
     * @param nftAddress            The nft contract address
     * @param tokenId               The tokenId of the NFT that is being signed
     * @param inscriber             The address of the inscriber
     * @param contentHash           A hash of the content. This hash will not change and will be used to verify the contents in the frontent
     * @param inscriptionURI        URI of where the hash is stored
     * @param nonce                 A unique value to ensure every sig is different
     * @param sig                   Signature of the hash, signed by the inscriber
     * 
     * Requirements:
     *
     * - `tokenId` The user calling this method must own the `tokenId` at `nftAddress` or has been approved
     * 
     */
    function addInscriptionWithInscriptionUri(
        address nftAddress,
        uint256 tokenId,
        address inscriber,
        bytes32 contentHash,
        string calldata inscriptionURI,
        uint256 nonce,
        bytes calldata sig
    ) external;

    /**
     * @dev Removes inscription on-chain.
     * 
     * Requirements:
     * 
     * - `inscriptionId` The user calling this method must own the `tokenId` at `nftAddress` of the inscription at `inscriptionId` or has been approved
     */
    function removeInscription(uint256 inscriptionId, address nftAddress, uint256 tokenId) external;

    // -- Migrating URIs

    /**
     * @dev  Migrations are necessary if you would like an inscription operator to host your content hash
    *        or if you would like to swap to a new inscription operator.
     */
    function migrateURI(uint256 inscriptionId, uint256 baseUriId, address nftAddress, uint256 tokenId) external;

    /**
     * @dev Migrates the URI to inscription URI. This is mainly to migrate to an ipfs link. The content hash must
            be stored at inscriptionURI in order to be considered valid by frontend.
     */
    function migrateURI(uint256 inscriptionId, string calldata inscriptionURI, address nftAddress, uint256 tokenId) external;

}
