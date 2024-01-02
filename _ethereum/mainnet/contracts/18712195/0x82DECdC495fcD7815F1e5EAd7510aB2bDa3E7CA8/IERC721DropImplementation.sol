// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./DropStructs.sol";

interface IERC721DropImplementation {
    struct MultiConfig {
        // Max supply
        uint256 maxSupply;

        // Collection base URI
        string baseURI;

        // Royalties
        address royaltiesReceiver;
        uint96 royaltiesFeeNumerator;

        // Payout
        address payoutAddress;

        // Public stage
        PublicMintStage publicMintStage;

        // Allowlist stages
        AllowlistMintStageConfig[] allowlistMintStages;

        // Token gated stages
        TokenGatedMintStageConfig[] tokenGatedMintStages;
    }

    /**
     * @dev Revert if supplied merkle proof is not valid for allowlist mint stage.
     */
    error AllowlistStageInvalidProof();

    /**
     * @dev Revert if minter is not token owner for token gated mint stage.
     */
    error TokenGatedNotTokenOwner();

    /**
     * @dev Revert if token id is already redeemed for token gated mint stage.
     */
    error TokenGatedTokenAlreadyRedeemed();

    /**
     * @dev Revert if NFT contract is zero address when updating token gated mint stage.
     */
    error TokenGatedNftContractCannotBeZeroAddress();

    /**
     * @dev Emit an event when public mint stage configuration is updated.
     */
    event PublicMintStageUpdated(PublicMintStage data);

    /**
     * @dev Emit an event when allowlist mint stage configuration is updated.
     */
    event AllowlistMintStageUpdated(uint256 indexed allowlistStageId, AllowlistMintStage data);

    /**
     * @dev Emit an event when token gated mint stage configuration is updated for NFT contract.
     */
    event TokenGatedMintStageUpdated(
        address indexed nftContract,
        TokenGatedMintStage data
    );

    /**
     * @notice Mint a public stage.
     *
     * @param recipient Recipient of tokens.
     * @param quantity Number of tokens to mint.
     */
    function mintPublic(address recipient, uint256 quantity) external payable;

    /**
     * @notice Mint an allowlist stage.
     *
     * @param allowlistStageId ID of the allowlist stage.
     * @param recipient Recipient of tokens.
     * @param quantity Number of tokens to mint.
     * @param merkleProof Valid Merkle proof.
     */
    function mintAllowlist(
        uint256 allowlistStageId,
        address recipient,
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) external payable;

    /**
     * @notice Mint a token gated stage.
     *
     * @param recipient Recipient of tokens.
     * @param nftContract NFT collection to redeem for.
     * @param tokenIds Token Ids to redeem.
     */
    function mintTokenGated(
        address recipient,
        address nftContract,
        uint256[] calldata tokenIds
    ) external payable;

    /**
     * @notice Returns if token is redeemed for NFT contract.
     *
     * @param nftContract The token gated nft contract.
     * @param tokenId The token gated token ID to check.
     */
    function getTokenGatedIsRedeemed(
        address nftContract,
        uint256 tokenId
    ) external view returns (bool);

    /**
     * @notice Updates configation for all phases.
     * @dev This should be user for initial contract configuration.
     *
     * @param config The new configuration for contract
     */
    function updateConfiguration(
        MultiConfig calldata config
    ) external;

    /**
     * @notice Updates configuration for public mint stage.
     *
     * @param publicMintStageData The new public mint stage data to set.
     */
    function updatePublicMintStage(
        PublicMintStage calldata publicMintStageData
    ) external;

    /**
     * @notice Updates configuration for allowlist mint stage.
     *
     * @param allowlistMintStageConfig The new allowlist mint stage config to set.
     */
    function updateAllowlistMintStage(
        AllowlistMintStageConfig calldata allowlistMintStageConfig
    ) external;

    /**
     * @notice Updates configuration for token gated mint stage.
     *
     * @param tokenGatedMintStageConfig The new token gated mint stage config to set.
     */
    function updateTokenGatedMintStage(
        TokenGatedMintStageConfig calldata tokenGatedMintStageConfig
    ) external;
}
