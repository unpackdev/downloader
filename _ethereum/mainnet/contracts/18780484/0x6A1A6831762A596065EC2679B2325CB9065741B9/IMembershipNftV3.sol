// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./SafeI.sol";

interface MembershipNftV3I {
    struct TokenEdition {
        // The maximum number of tokens that can be sold. 0 for open edition.
        uint256 tokenId;
        // block.timestamp when the sale end. 0 for no ending time.
        uint256 editionId;
        // current owner of this token
        address owner;
        // block.timestamp when the sale starts. 0 for immediate mint availability.
        uint256 serialNumber;
        // The voting power to be used by another smart contract interactions
        uint256 votingPower;
    }

    function getTokenById(uint256 tokenId) external view returns (TokenEdition memory);

    function getTokenByIndex(uint256 index) external view returns (TokenEdition memory);

    function version() external pure returns (string memory);

    struct Edition {
        // The maximum number of tokens that can be sold. 0 for open edition.
        uint256 quantity;
        // block.timestamp when the sale end. 0 for no ending time.
        uint closedAt;
        // block.timestamp when the sale starts. 0 for immediate mint availability.
        uint opensAt;
        // The price at which each token will be sold, in ETH.
        uint256 price;
        // The number of tokens sold so far.
        uint256 numSold;
        // The voting power to be used by another smart contract interactions
        uint256 votingPower;
        // optional root hash of the allowlist merkle tree
        bytes32 allowlistRoot;
        // The maximum number of tokens that can be minted per wallet. 0 for no limit.
        uint256 maxMintPerWallet;
    }

    /// @notice Create a new edition with a tier struct
    struct EditionTier {
        /// The maximum number of tokens that can be sold.
        uint256 quantity;
        /// The price at which each token will be sold, in ETH.
        uint256 price;
        // The voting power to be used by another smart contract interactions
        uint256 votingPower;
        /// block.timestamp when the sale end. 0 for no ending time.
        uint closedAt;
        /// block.timestamp when the sale starts. 0 for no starting time.
        uint opensAt;
        // optional root hash of the allowlist merkle tree
        bytes32 allowlistRoot;
        // The maximum number of tokens that can be minted per wallet. 0 for no limit.
        uint256 maxMintPerWallet;
    }

    /// @notice Create one or more editions. Only vault signers can call this
    /// @param tiers The tiers to create
    /// @param minter The address that will be able to mint tokens
    function createEditions(
        EditionTier[] memory tiers,
        address minter
    ) external;

    /// @notice Mint tokens from an edition.
    function buyEdition(uint256 editionId, address recipient, uint256 amount)
    external
    returns (uint256 tokenId);

    // @notice The owning vault of this contract
    function vault() external view returns (SafeI);

    /// @notice initialize the contract with no tiers
    function initialize(
        address _owner,
        address _vault,
        string memory name,
        string memory symbol,
        string memory baseUrlIn)
    external;

    /// @notice initialize the contract with tiers
    function initializeEditions(
        address _owner,
        address _vault,
        string memory name,
        string memory symbol,
        string memory baseUrlIn,
        EditionTier[] memory tiers,
        address _minter)
    external;

    /// @notice Get edition info about an edition
    function getEdition(uint256 editionId) external view returns (Edition memory);

    /// @notice Get the number of tokens a wallet has minted from an edition.
    function getWalletMintCount(address wallet, uint256 editionId) external view returns (uint256);

    function adminAirdrop(address[] memory wallets, uint256[] memory editionIds, uint256[] memory amounts) external;
}