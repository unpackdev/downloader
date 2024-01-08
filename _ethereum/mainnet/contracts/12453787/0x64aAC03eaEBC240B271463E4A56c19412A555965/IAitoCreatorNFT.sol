// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IAitoCreatorNFT {
    struct FeeData {
        address feeRecipient;
        uint16 feeBps;
    }

    struct EIP712Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * @notice Emitted when an NFT is minted.
     *
     * @param tokenId The token ID mapped to the newly minted NFT.
     * @param creator The creator of the newly minted NFT.
     * @param to The receiver of the newly minted NFT.
     * @param feeRecipient The fee recipient mapped to the newly minted NFT.
     * @param feeBps The fee BPS mapped to the newly minted NFT.
     * @param uri The URI mapped to the newly minted NFT.
     */
    event TokenMinted(
        uint256 indexed tokenId,
        address indexed creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string uri
    );

    /**
     * @notice Emitted when a fee recipient is changed.
     *
     * @param tokenId The token ID mapped to the NFT.
     * @param newFeeRecipient The new fee recipient address mapped to the NFT.
     */
    event FeeRecipientChanged(uint256 indexed tokenId, address newFeeRecipient);

    /**
     * @notice Emitted when the fee BPS is changed for a given NFT.
     *
     * @param tokenId The token ID mapped to the NFT.
     * @param newFeeBps The new fee BPS mapped to the NFT.
     */
    event FeeBpsChanged(uint256 indexed tokenId, uint16 newFeeBps);

    /**
     * @notice Emitted when an NFT creator is changed.
     *
     * @param tokenId The token ID mapped to the NFT.
     * @param newCreator The new creator address mapped to the NFT.
     */
    event CreatorChanged(uint256 indexed tokenId, address newCreator);

    /**
     * @notice Emitted when a given NFT's URI is changed.
     *
     * @param tokenId The token ID mapped to the NFT.
     * @param newUri The new token URI mapped to the NFT.
     */
    event URIChanged(uint256 indexed tokenId, string newUri);

    /**
     * @notice Mints an NFT with the given parameters.
     *
     * @param creator The creator address to map to the NFT.
     * @param to The address to send the NFT to.
     * @param feeRecipient the fee receiving address to map to the NFT.
     * @param feeBps the fee BPS to map to the NFT.
     * @param uri The URI to map to the NFT.
     */
    function mint(
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string calldata uri
    ) external;

    /**
     * @notice Batch mints multiple NFTs with potentially separate URIs.
     *
     * @param amount The amount of NFTs to mint.
     * @param creator The creator address to map to the NFTs.
     * @param to The address to send the NFTs to.
     * @param feeRecipient the fee receiving address to map to the NFTs.
     * @param feeBps the fee BPS to map to the NFTs.
     * @param uris The URI string array to map to the NFTs.
     */
    function batchMint(
        uint256 amount,
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string[] calldata uris
    ) external;

    /**
     * @notice Similar to `batchMint()`, but this function batch mints multiple NFTs with the
     * same URI only.
     *
     * @param amount The amount of NFTs to mint.
     * @param creator The creator address to map to the NFTs.
     * @param to The address to send the NFTs to.
     * @param feeRecipient the fee receiving address to map to the NFTs.
     * @param feeBps the fee BPS to map to the NFTs.
     * @param uri The URI to map to the NFTs.
     */
    function batchMintCopies(
        uint256 amount,
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string calldata uri
    ) external;

    /**
     * @notice Allows token owners to burn their NFTs.
     *
     * @param tokenId The ID of the NFT to burn.
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Allows token creators to update their token's URI in case of an IPFS gateway failure or similar.
     *
     * @param tokenId The token ID to change the URI for.
     * @param newUri The new URI to map to the NFT.
     */
    function changeURI(uint256 tokenId, string calldata newUri) external;

    /**
     * @notice Allows token creators to change the fee BPS associated with one of their tokens.
     *
     * @param tokenId The token ID to change the fee BPS for.
     * @param newFeeBps The new fee BPS to map to the NFT.
     */
    function changeFeeBps(uint256 tokenId, uint16 newFeeBps) external;

    /**
     * @notice Allows token creators to change the fee recipient address associated with one of their tokens.
     *
     * @param tokenId The token ID to change the fee recipient for.
     * @param newFeeRecipient The new fee recipient to map to the NFT.
     */
    function changeFeeRecipient(uint256 tokenId, address newFeeRecipient) external;

    /**
     * @notice Allows token creators to change the creator address associated with one of their tokens.
     *
     * @param tokenId The token ID to change the creator address for.
     * @param newCreator The new creator to map to the NFT.
     */
    function changeCreator(uint256 tokenId, address newCreator) external;

    /**
     * @notice EIP-712 permit method. Sets a spender's approval to transfer an NFT.
     * Forked from Zora.
     *
     * We don't need to check if the tokenId exists, since the function calls ownerOf(tokenId), which reverts if
     * the tokenId does not exist.
     */
    function permit(
        address spender,
        uint256 tokenId,
        EIP712Signature calldata sig
    ) external;

    /**
     * @notice EIP-712 permitForAll method. Approves an address for all of a user's NFTs.
     */
    function permitForAll(
        address owner,
        address operator,
        EIP712Signature calldata sig
    ) external;

    /**
     * @notice Returns the creator address mapped to the NFT with the given token ID.
     *
     * @param tokenId The token ID of the NFT to query.
     */
    function creator(uint256 tokenId) external view returns (address);

    /**
     * @notice Returns the fee data mapped to the NFT with the given token ID.
     *
     * @param tokenId The token ID of the NFT to query.
     */
    function feeData(uint256 tokenId) external view returns (FeeData memory);

    /**
     * @notice Returns the fee BPS mapped to the NFT with the given token ID.
     *
     * @param tokenId The token ID of the NFT to query.
     */
    function feeBps(uint256 tokenId) external view returns (uint16);

    /**
     * @notice Returns the fee recipient address mapped to the NFT with the given token ID.
     *
     * @param tokenId The token ID of the NFT to query.
     */
    function feeRecipient(uint256 tokenId) external view returns (address);

    /**
     * @notice Returns the domain separator for this NFT contract.
     */
    function domainSeparator() external view returns (bytes32);
}
