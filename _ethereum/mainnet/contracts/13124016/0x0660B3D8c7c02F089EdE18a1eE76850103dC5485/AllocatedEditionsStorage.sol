// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title AllocatedEditionsStorage
 * @author MirrorXYZ
 */
contract AllocatedEditionsStorage {
    // ============ Structs ============

    /// @notice Contains general data about the NFT.
    struct NFTMetadata {
        string name;
        string symbol;
        bytes32 contentHash;
    }

    /// @notice Contains information pertaining to the edition spec.
    struct EditionData {
        // The number of tokens pre-allocated to the minter.
        uint256 allocation;
        // The maximum number of tokens that can be sold.
        uint256 quantity;
        // The price at which each token will be sold, in ETH.
        uint256 price;
    }

    /// @notice Contains information about funds disbursement.
    struct AdminData {
        // Operator of this contract, receives premint.
        address operator;
        // Address that receive gov tokens via treasury.
        address tributary;
        // The account that will receive sales revenue.
        address payable fundingRecipient;
        // The fee taken when withdrawing funds
        uint256 feePercentage;
    }

    // ============ Storage for Setup ============

    /// @notice NFTMetadata`
    string public baseURI;
    bytes32 contentHash;

    /// @notice EditionData
    uint256 public allocation;
    uint256 public quantity;
    uint256 public price;

    /// @notice EditionConfig
    address public operator;
    address public tributary;
    address payable public fundingRecipient;
    uint256 feePercentage;

    /// @notice Treasury Config, provided at setup, for finding the treasury address.
    address treasuryConfig;

    // ============ Mutable Runtime Storage ============

    /// @notice `nextTokenId` increments with each token purchased, globally across all editions.
    uint256 internal nextTokenId;
    /// @notice The number of tokens that have moved outside of the pre-mint allocation.
    uint256 internal allocationsTransferred = 0;

    /**
     * @notice A special mapping of burned tokens, to take care of burning within
     * the tokenId range of the allocation.
     */
    mapping(uint256 => bool) internal _burned;

    // ============ Mutable Internal NFT Storage ============

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /// @notice Only allow one purchase per account.
    mapping(address => bool) internal purchased;

    // ============ Delegation logic ============
    address public logic;

    // OpenSea's Proxy Registry
    address public proxyRegistry;
}
