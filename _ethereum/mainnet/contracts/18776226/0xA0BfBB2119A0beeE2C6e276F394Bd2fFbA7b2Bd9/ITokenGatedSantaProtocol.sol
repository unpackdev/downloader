// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Prohibition / VenturePunk,LLC
// Written By: Thomas Lipari (thom.eth)
pragma solidity ^0.8.23;

/**
 * @title The TokenGatedSantaProtocol contract
 * @author Thomas Lipari (thom.eth)
 * @notice An extension of the SantaProtocol contract that adds token gating
 */
interface ITokenGatedSantaProtocol {
    //========//
    // Errors //
    //========//

    error NotTokenGatedCollectionHolder();
    error NotTokenGatedTokenHolder();
    error NotTokenGateCollection();
    error TokenGateLimitReached();
    error PoolIsNotTokenGated();
    error TokenGated();

    //=========================//
    // Gift Exchange Functions //
    //=========================//

    /**
     * @notice Disabled because token gate requires more values
     * @param nft - the address of the NFT being added
     * @param tokenId - the token id of the NFT being added
     * @param tokenGateNft - the address of the NFT being used to gate access to the protocol
     * @param tokenGateTokenId - the token id of the NFT being used to gate access to the protocol
     * @param sig - a message signed by the signer address verifying the NFT is eligible
     */
    function addGift(address nft, uint256 tokenId, address tokenGateNft, uint256 tokenGateTokenId, bytes calldata sig)
        external
        returns (address giftAddress, uint256 giftTokenId);

    //================//
    // View Functions //
    //================//

    /**
     * @notice Get the the address of the TokenGate NFT
     */
    function getTokenGateContract() external view returns (address);

    /**
     * @notice Function that checks if an NFT is eligible to be used to gate access to the protocol
     * @param account - the account that is using the NFT
     * @param tokenGateNft - the address of the NFT being used to gate access to the protocol
     * @param tokenGateTokenId - the token id of the NFT being used to gate access to the protocol
     */
    function getTokenGateEligibility(address account, address tokenGateNft, uint256 tokenGateTokenId)
        external
        view
        returns (bool eligible);

    /**
     * @notice Function that checks if the token gate support delegates
     */
    function getSupportsDelegates() external view returns (bool);

    //=================//
    // Admin Functions //
    //=================//

    /**
     * @notice Function that allows the owners to update the address of the Token Gate NFT
     * @param newTokenGateNft - new address of the Token Gate NFT
     */
    function setTokenGateContract(address newTokenGateNft) external;

    /**
     * @notice Function that allows the owners to update the address of the Token Gate NFT
     * @param newTokenGateLimit - new address of the Token Gate NFT
     */
    function setTokenGateLimit(uint32 newTokenGateLimit) external;

    /**
     * @notice Function that allows the owners to toggle whether or not delegated wallets are supported
     */
    function toggleSupportsDelegates() external;

    //===================//
    // Signing/Verifying //
    //===================//

    /**
     * @notice Function used to hash a gift along with tokengate information
     * @param gifter - address of the gifter
     * @param nft - the address of the NFT being gifted
     * @param tokenId - the id of the NFT being gifted
     * @param tokenGateNft - the address of the NFT being used to gate access to the protocol
     * @param tokenGateTokenId - the token id of the NFT being used to gate access to the protocol
     */
    function hashTokenGateGift(
        address gifter,
        address nft,
        uint256 tokenId,
        address tokenGateNft,
        uint256 tokenGateTokenId
    ) external view returns (bytes32);

    /**
     * @notice Function that validates that the gift hash signature was signed by the designated signer authority
     * @param gifter - address of the gifter
     * @param nft - the address of the NFT being gifted
     * @param tokenId - the id of the NFT being gifted
     * @param tokenGateNft - the address of the NFT being used to gate access to the protocol
     * @param tokenGateTokenId - the token id of the NFT being used to gate access to the protocol
     * @param sig - the signature of the gift hash
     */
    function validateTokenGateSignature(
        address gifter,
        address nft,
        uint256 tokenId,
        address tokenGateNft,
        uint256 tokenGateTokenId,
        bytes calldata sig
    ) external view returns (bool);
}
