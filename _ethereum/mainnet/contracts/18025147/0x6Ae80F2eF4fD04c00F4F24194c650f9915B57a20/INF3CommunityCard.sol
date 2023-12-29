// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface INF3CommunityCard {
    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    struct TokenIdsForBatch {
        uint128 startingTokenId;
        uint128 endingTokenId;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when base uri is set
    /// @param oldBaseURI Previous base uri
    /// @param newBaseURI Current base uri
    event BaseURISet(string oldBaseURI, string newBaseURI);

    /// @dev Emits when token is minted
    /// @param batchId Id of the batch out of which token is minted
    /// @param tokenId Token id of the minted token
    /// @param user Address of the whitelisted user who minted the token
    event Minted(uint batchId, uint tokenId, address user);

    /// @dev Emits when new batch is added to be minted
    /// @param batchId Id of the new batch
    /// @param tokenIds TokenIds avaialbe in the batch
    /// @param batchWhitelistRoot Merkle root of the new whitelisted batch
    event BatchAdded(
        uint batchId,
        TokenIdsForBatch tokenIds,
        bytes32 batchWhitelistRoot
    );

    /// @dev Emits when an existing batch's whitelist or timeperiod is updated
    /// @param batchId Id of the batch that has updated
    /// @param batchWhitelistRoot Merkle root of the whitelisted addresses
    /// @param timePeriod timestamp when minting ends
    event BatchUpdated(
        uint batchId,
        bytes32 batchWhitelistRoot,
        uint timePeriod
    );

    /// @dev Emits when royalty info is set
    /// @param feeNumerator Fee percentage in basis points
    /// @param receiver Receiver of the royalty
    /// @param tokenId TokenId for which the royalty is set
    /// NOTE : tokenId = uint256.MAX means royalty for entire collection
    event RoyaltySet(uint256 feeNumerator, address receiver, uint256 tokenId);

    /// -----------------------------------------------------------------------
    /// Public functions
    /// -----------------------------------------------------------------------

    /// @dev Mint an nft out of the given batch Id. Only whitelisted users can mint
    ///      Each batch has it's own whitelist
    /// @param batchId Id of the batch out of which nft is to be minted
    /// @param proof merkle proof of the whitelisted user address
    function mint(uint batchId, bytes32[] calldata proof) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Add new batch of community cards availabe for minting
    /// @param sizeOfBatch Number of tokenIds that can be minted
    /// @param batchWhitelist Merkle tree root of the whitelisted addresses that are eligible for minting
    function addNewBatch(
        uint sizeOfBatch,
        bytes32 batchWhitelist,
        uint timePeriodOfBatch
    ) external;

    /// @dev Update the whitelist and timePeriod of mint for a particular batch
    /// @param batchId Id of the batch who's whitelist needs to be updated
    /// @param batchWhitelistRoot Merkle root of the new whitelist addresses
    /// @param timePeriodOfBatch Timestamp when minting ends
    function updateBatch(
        uint batchId,
        bytes32 batchWhitelistRoot,
        uint timePeriodOfBatch
    ) external;

    /// @dev Set base uri for the token Metadata
    /// @param baseURI_ new base uri of the token metadata
    function setBaseURI(string memory baseURI_) external;

    /// @dev Set erc 2981 royalty info for the collection
    /// @param feeNumerator Fee percentage in basis points
    /// @param receiver Receiver of the royalty
    function setDefaultRoyalty(address receiver, uint16 feeNumerator) external;

    /// @dev Set erc 2981 royalty info for a tokenId
    /// @param feeNumerator Fee percentage in basis points
    /// @param receiver Receiver of the royalty
    /// @param tokenId TokenId for which the royalty is set
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external;
}
