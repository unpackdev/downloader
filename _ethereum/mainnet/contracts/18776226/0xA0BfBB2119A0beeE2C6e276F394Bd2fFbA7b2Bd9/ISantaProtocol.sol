// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Prohibition / VenturePunk,LLC
// Written By: Thomas Lipari (thom.eth)
pragma solidity ^0.8.23;

/**
 * @title The SantaProtocol contract
 * @author Thomas Lipari (thom.eth)
 * @notice A contract that lets people deposit an NFT into a pool and then later lets them randomly redeem another one using Chainlink VRF2
 */
interface ISantaProtocol {
    //=========//
    // Structs //
    //=========//

    // Struct to store gifts in the pool
    struct Gift {
        address gifter;
        address nft;
        uint256 tokenId;
    }

    //========//
    // Errors //
    //========//

    error RedemptionMustHappenAfterRegistration();
    error GiftMustSupportERC721Interface();
    error InvalidSenderMustNotBeContract();
    error RedemptionHasNotStarted();
    error PoolSizeExceedsAmount();
    error MustApproveContract();
    error HasNotBeenShuffled();
    error DoesNotOwnPresent();
    error RegistrationEnded();
    error CannotGiftPresent();
    error InvalidSignature();
    error MaxGiftsReached();
    error MustOwnTokenId();

    //========//
    // Events //
    //========//

    event ERC721Received(address operator, address from, uint256 tokenId, bytes data);
    event GiftAdded(address gifter, address nft, uint256 tokenId);
    event GiftChosen(address account, uint256 presentTokenId, address nft, uint256 tokenId);

    //=========================//
    // Gift Exchange Functions //
    //=========================//

    /**
     * @notice Function used to add an NFT to the pool.
     * @param nft - the address of the NFT being added
     * @param tokenId - the token id of the NFT being added
     * @param sig - a message signed by the signer address verifying the NFT is eligible
     */
    function addGift(address nft, uint256 tokenId, bytes calldata sig)
        external
        returns (address giftAddress, uint256 giftTokenId);

    /**
     * @notice Function used to burn a Present NFT and redeem the gift in the pool it's been tied to
     * @param tokenId - the token id of the Present NFT being burned
     */
    function openGift(uint256 tokenId) external returns (address chosenGiftAddress, uint256 chosenGiftTokenId);

    //================//
    // View Functions //
    //================//

    /**
     * @notice Get the number of NFTs in the gift pool
     */
    function getSigner() external view returns (address);

    /**
     * @notice Get the number of NFTs in the gift pool
     */
    function getRegistrationEnd() external view returns (uint256);

    /**
     * @notice Get the number of NFTs in the gift pool
     */
    function getRedemptionStart() external view returns (uint256);

    /**
     * @notice Get the number of NFTs in the gift pool
     */
    function getGiftPoolSize() external view returns (uint256);

    /**
     * @notice Get the whole gift pool
     * @dev intended for offchain use only
     */
    function getGiftPool() external view returns (Gift[] memory);

    /**
     * @notice Get the number of gifts that a user has randomly chosen
     * @param account - the wallet address of the user
     */
    function getNumberOfChosenGifts(address account) external view returns (uint256);

    /**
     * @notice Get the array of gifts that a user has randomly chosen
     * @param account - the wallet address of the user
     * @dev intended for offchain use only
     */
    function getChosenGifts(address account) external view returns (Gift[] memory);

    //=================//
    // Admin Functions //
    //=================//

    /**
     * @notice Set signer to new account
     * @param newSigner - the addres of the new owner
     */
    function setSigner(address newSigner) external;

    /**
     * @notice Set the time that adding gifts ends
     * @param newRegistrationEnd - the new s_registerationEnd time
     */
    function setRegistrationEnd(uint256 newRegistrationEnd) external;

    /**
     * @notice Set the time that claiming a random gift starts
     * @param newRedemptionStart - the new s_redemptionStart time
     */
    function setRedemptionStart(uint256 newRedemptionStart) external;

    /**
     * @notice Function used to update the subscription ID
     * @param newSubscriptionId - the chainlink vrf subscription id
     */
    function setSubscriptionId(uint64 newSubscriptionId) external;

    /**
     * @notice Function used to update the gas lane used by VRF
     * @param newKeyHash - the keyhash of the gaslane that VRF uses
     */
    function setKeyHash(bytes32 newKeyHash) external;

    /**
     * @notice Function used to update the callback gas limit
     * @param newCallbackGasLimit - the gas limit of the fulfillRandomWords callback
     */
    function setCallbackGasLimit(uint32 newCallbackGasLimit) external;

    /**
     * @notice Function that pauses the contract
     * @param isPaused - now what're we turning the pause to!?
     */
    function setPaused(bool isPaused) external;

    /**
     * @notice Function that allows the owner to update the max size of the pool
     * @param newMaxGifts - new max number of gifts in the pool
     */
    function setMaxGifts(uint32 newMaxGifts) external;

    //================//
    // Pool Shuffling //
    //================//

    /**
     * @notice Function that requests a random seed from VRF
     */
    function requestSeed() external;

    /**
     * @notice Function that uses the SEED to shuffle the index array.
     * Just in case this ends up being a large array (Ho Ho Ho!), we will make it possible
     * to break this operation up into multiple calls
     * @param startPosition - the starting index we're shuffling
     * @param endPosition - the ending index we're shuffling
     */
    function shuffleRandomGiftIndices(uint32 startPosition, uint32 endPosition) external;

    //===================//
    // Signing/Verifying //
    //===================//

    /**
     * @notice Function used to hash a gift
     * @param gifter - address of the gifter
     * @param nft - the address of the NFT being gifted
     * @param tokenId - the id of the NFT being gifted
     */
    function hashGift(address gifter, address nft, uint256 tokenId) external view returns (bytes32);

    /**
     * @notice Function that valifates that the gift hash signature was signed by the designated signer authority
     * @param gifter - address of the gifter
     * @param nft - the address of the NFT being gifted
     * @param tokenId - the id of the NFT being gifted
     * @param sig - the signature of the gift hash
     */
    function validateGiftHashSignature(address gifter, address nft, uint256 tokenId, bytes calldata sig)
        external
        view
        returns (bool);

    //======//
    // Misc //
    //======//

    /**
     * @notice Function used to determine if a contract supports 721 interface
     * @param nft - the address of an NFT
     */
    function giftSupports721(address nft) external view returns (bool);
}
