// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Prohibition / VenturePunk,LLC
// Written By: Thomas Lipari (thom.eth)
pragma solidity ^0.8.23;

import "./IERC721Receiver.sol";
import "./ECDSA.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";
import "./IERC165.sol";
import "./Ownable.sol";

import "./RandomNumberConsumerV2.sol";
import "./WrappedPresent.sol";
import "./ISantaProtocol.sol";

/**
 * @title The SantaProtocol contract
 * @author Thomas Lipari (thom.eth)
 * @notice A contract that lets people deposit an NFT into a pool and then later lets them randomly redeem another one using Chainlink VRF2
 */
contract SantaProtocol is Ownable, IERC721Receiver, ISantaProtocol, RandomNumberConsumerV2 {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using SafeCast for uint256;

    //=========//
    // Storage //
    //=========//

    /* Constants */

    // The Present NFT that's minted to users when they add to the pool
    WrappedPresent public immutable PRESENT_NFT;

    /* Private values */

    // Address that signs verification messages when adding gifts
    address internal s_signer;
    // Blocktime that adding gifts to the pool ends
    uint32 internal s_registrationEnd;
    // Blocktime that redemptions start
    uint32 internal s_redemptionStart;
    // The Gift Pool
    Gift[] internal s_giftPool;
    // The array to map Present Token IDs to gifts in the Gift Pool
    uint32[] internal s_giftPoolIndices;
    // Mapping of gifts chosen by each user
    mapping(address user => Gift[] unwrappedGifts) internal s_chosenGifts;

    /* Config */

    // The state that pauses the contract's functionality
    bool public PAUSED = false;
    // The state that says that the gift pool has been shuffled
    bool public SHUFFLED = false;
    // Maximum allowed gifts in the pool
    uint32 public MAX_GIFTS = 50000;
    // The state that dictates whether adding a gift requires a signature
    bool public REQUIRES_SIGNATURE = true;

    /* Chainlink VRF */

    // The random word returned by VRF used as a seed for the randomness
    uint256 public SEED;
    // The request ID for the SEED
    uint256 public SEED_REQUEST_ID;

    //=============//
    // Constructor //
    //=============//

    /**
     * @notice Constructor inherits RandomNumberConsumerV2
     * @param subscriptionId - the subscription ID that this contract uses for funding Chainlink VFR requests
     * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
     * @param keyHash - the Chainlink gas lane to use, which specifies the maximum gas price to bump to
     * @param registrationEnd - the time that registration/adding gifts ends
     * @param redemptionStart - the time that participants can begin redeeming their gifts
     */
    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 registrationEnd,
        uint256 redemptionStart,
        address signer,
        address presentNft
    ) RandomNumberConsumerV2(subscriptionId, vrfCoordinator, keyHash) {
        s_registrationEnd = registrationEnd.toUint32();
        s_redemptionStart = redemptionStart.toUint32();
        s_signer = signer;
        PRESENT_NFT = WrappedPresent(presentNft);
    }

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
        public
        virtual
        isNotPaused
        returns (address giftAddress, uint256 giftTokenId)
    {
        // Run validity check
        _addGiftChecks(nft, tokenId);
        // If the signature isn't valid
        if (!_validateGiftHashSignatureIfRequired(msg.sender, nft, tokenId, sig)) revert InvalidSignature();
        // Add the gift to the pool and mint a PresentNft to the user that added the gift
        (giftAddress, giftTokenId) = _addGiftTransfers(nft, tokenId);
    }

    /**
     * @notice Function used to burn a Present NFT and redeem the gift in the pool it's been tied to
     * @param tokenId - the token id of the Present NFT being burned
     */
    function openGift(uint256 tokenId)
        public
        virtual
        isNotPaused
        returns (address chosenGiftAddress, uint256 chosenGiftTokenId)
    {
        // Run validity check
        _openGiftChecks(tokenId);
        // Open the gift and transfer it to the user
        (chosenGiftAddress, chosenGiftTokenId) = _openGiftTransfers(tokenId);
    }

    //================//
    // View Functions //
    //================//

    /**
     * @notice Get the number of NFTs in the gift pool
     */
    function getSigner() public view returns (address) {
        return s_signer;
    }

    /**
     * @notice Get the end of the deposit window
     */
    function getRegistrationEnd() public view returns (uint256) {
        return uint256(s_registrationEnd);
    }

    /**
     * @notice Get start of the redemption window
     */
    function getRedemptionStart() public view returns (uint256) {
        return uint256(s_redemptionStart);
    }

    /**
     * @notice Get the number of NFTs in the gift pool
     */
    function getGiftPoolSize() public view returns (uint256) {
        return s_giftPool.length;
    }

    /**
     * @notice Get the whole gift pool
     * @dev intended for offchain use only
     */
    function getGiftPool() public view returns (Gift[] memory) {
        return s_giftPool;
    }

    /**
     * @notice Get the number of gifts that a user has randomly chosen
     * @param account - the wallet address of the user
     */
    function getNumberOfChosenGifts(address account) public view returns (uint256) {
        return s_chosenGifts[account].length;
    }

    /**
     * @notice Get the array of gifts that a user has randomly chosen
     * @param account - the wallet address of the user
     * @dev intended for offchain use only
     */
    function getChosenGifts(address account) public view returns (Gift[] memory) {
        return s_chosenGifts[account];
    }

    //=================//
    // Admin Functions //
    //=================//

    /**
     * @notice Set signer to new account
     * @param newSigner - the addres of the new owner
     */
    function setSigner(address newSigner) public onlyOwner {
        s_signer = newSigner;
    }

    /**
     * @notice Toggle whether adding a gift requires a signature
     */
    function toggleSignatureRequired() public onlyOwner {
        REQUIRES_SIGNATURE = !REQUIRES_SIGNATURE;
    }

    /**
     * @notice Set the time that adding gifts ends
     * @param newRegistrationEnd - the new s_registerationEnd time
     */
    function setRegistrationEnd(uint256 newRegistrationEnd) public onlyOwner {
        if (s_redemptionStart != 0 && newRegistrationEnd >= s_redemptionStart) {
            revert RedemptionMustHappenAfterRegistration();
        }
        s_registrationEnd = newRegistrationEnd.toUint32();
    }

    /**
     * @notice Set the time that claiming a random gift starts
     * @param newRedemptionStart - the new s_redemptionStart time
     */
    function setRedemptionStart(uint256 newRedemptionStart) public onlyOwner {
        if (newRedemptionStart <= s_registrationEnd) revert RedemptionMustHappenAfterRegistration();
        s_redemptionStart = newRedemptionStart.toUint32();
    }

    /**
     * @notice Function used to update the subscription ID
     * @param newSubscriptionId - the chainlink vrf subscription id
     */
    function setSubscriptionId(uint64 newSubscriptionId) public onlyOwner {
        s_subscriptionId = newSubscriptionId;
    }

    /**
     * @notice Function used to update the gas lane used by VRF
     * @param newKeyHash - the keyhash of the gaslane that VRF uses
     */
    function setKeyHash(bytes32 newKeyHash) public onlyOwner {
        s_keyHash = newKeyHash;
    }

    /**
     * @notice Function used to update the callback gas limit
     * @param newCallbackGasLimit - the gas limit of the fulfillRandomWords callback
     */
    function setCallbackGasLimit(uint32 newCallbackGasLimit) public onlyOwner {
        CALLBACK_GAS_LIMIT = newCallbackGasLimit;
    }

    /**
     * @notice Function that pauses the contract
     * @param isPaused - now what're we turning the pause to!?
     */
    function setPaused(bool isPaused) public onlyOwner {
        PAUSED = isPaused;
    }

    /**
     * @notice Function that allows the owner to update the max size of the pool
     * @param newMaxGifts - new max number of gifts in the pool
     */
    function setMaxGifts(uint32 newMaxGifts) public onlyOwner {
        if (s_giftPool.length > newMaxGifts) revert PoolSizeExceedsAmount();
        MAX_GIFTS = newMaxGifts;
    }

    //================//
    // Pool Shuffling //
    //================//

    /**
     * @notice Function that requests a random seed from VRF
     */
    function requestSeed() public onlyOwner {
        require(block.timestamp > s_registrationEnd, "Registration has not ended yet");
        SEED_REQUEST_ID = requestRandomWords(1);
        SHUFFLED = false;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     * @param requestId - id of the request
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (SEED_REQUEST_ID == requestId) {
            SEED = randomWords[0];
            emit ReturnedRandomness(requestId, randomWords);
        }
    }

    /**
     * @notice Function that uses the SEED to shuffle the index array.
     * Just in case this ends up being a large array (Ho Ho Ho!), we will make it possible
     * to break this operation up into multiple calls
     * @param startPosition - the starting index we're shuffling
     * @param endPosition - the ending index we're shuffling
     */
    function shuffleRandomGiftIndices(uint32 startPosition, uint32 endPosition) public onlyOwner {
        require(SEED != 0, "SEED does not exist");
        require(endPosition >= startPosition, "End position must be after start position");

        // Make sure that we're not going to go out of bounds
        uint32 lastPosition = endPosition > s_giftPool.length - 1 ? uint32(s_giftPool.length - 1) : endPosition;

        // Shuffle the indices in the array
        for (uint32 i = startPosition; i <= lastPosition;) {
            uint32 j = uint32((uint256(keccak256(abi.encode(SEED, i))) % (s_giftPool.length)));
            (s_giftPoolIndices[i], s_giftPoolIndices[j]) = (s_giftPoolIndices[j], s_giftPoolIndices[i]);
            unchecked {
                i++;
            }
        }

        // Once we've shuffled the entire array, set the state to shuffled
        if (lastPosition == s_giftPool.length - 1) {
            SHUFFLED = true;
        }
    }

    //===================//
    // Signing/Verifying //
    //===================//

    /**
     * @notice returns an identifying contract hash to verify this contract
     */
    function getContractHash() public view virtual returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this)));
    }

    /**
     * @notice Function used to hash a gift
     *
     * @param gifter - address of the gifter
     * @param nft - the address of the NFT being gifted
     * @param tokenId - the id of the NFT being gifted
     */
    function hashGift(address gifter, address nft, uint256 tokenId) public view virtual returns (bytes32) {
        bytes32 giftHash = keccak256(abi.encode(Gift(gifter, nft, tokenId)));
        return keccak256(abi.encode(getContractHash(), giftHash));
    }

    /**
     * @notice Function that validates that the gift hash signature was signed by the designated signer authority
     * @param gifter - address of the gifter
     * @param nft - the address of the NFT being gifted
     * @param tokenId - the id of the NFT being gifted
     * @param sig - the signature of the gift hash
     */
    function validateGiftHashSignature(address gifter, address nft, uint256 tokenId, bytes calldata sig)
        public
        view
        virtual
        returns (bool)
    {
        bytes32 giftHash = hashGift(gifter, nft, tokenId);
        bytes32 ethSignedMessageHash = giftHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(sig);
        return signer == s_signer;
    }

    //==========//
    // Internal //
    //==========//

    /**
     * @notice Checks that the gift is eligible to be added
     * @param nft - the address of the NFT being added
     * @param tokenId - the token id of the NFT being added
     * @dev This function leaves out the signature check so that inherited contracts can use custom logic
     */
    function _addGiftChecks(address nft, uint256 tokenId) internal view {
        // If the registration/adding gift end time has passed
        if (block.timestamp > s_registrationEnd) revert RegistrationEnded();
        // If the pool size has already reached its limit
        if (s_giftPool.length >= MAX_GIFTS) revert MaxGiftsReached();
        // If the gift is already a present, ya do-do!
        if (nft == address(PRESENT_NFT)) revert CannotGiftPresent();
        // If the gift doesn't support the ERC721 interface
        if (!giftSupports721(nft)) revert GiftMustSupportERC721Interface();
        // If the user doesn't own the nft they're adding
        if (IERC721(nft).ownerOf(tokenId) != msg.sender) revert MustOwnTokenId();
        // If the user hasn't individually approved this contract
        if (IERC721(nft).getApproved(tokenId) != address(this)) revert MustApproveContract();
    }

    /**
     * @notice Transfers the gift and present NFTs
     * @param nft - the address of the NFT being added
     * @param tokenId - the token id of the NFT being added
     */
    function _addGiftTransfers(address nft, uint256 tokenId)
        internal
        returns (address giftAddress, uint256 giftTokenId)
    {
        // Transfer the NFT from the caller to this contract
        IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId);
        // Mint a present NFT to the caller
        PRESENT_NFT.simpleMint(msg.sender);

        // Add the gift to the pool
        s_giftPool.push(Gift({gifter: msg.sender, nft: nft, tokenId: tokenId}));
        s_giftPoolIndices.push(uint32(s_giftPool.length - 1));

        emit GiftAdded(msg.sender, nft, tokenId);

        giftAddress = address(PRESENT_NFT);
        giftTokenId = s_giftPool.length;
    }

    /**
     * @notice Checks that the present is eligible to be opened
     * @param tokenId - the token id of the Present NFT
     */
    function _openGiftChecks(uint256 tokenId) internal view {
        // If redemptions haven't started yet
        if (block.timestamp < s_redemptionStart) revert RedemptionHasNotStarted();
        // If the pool has not been shuffled
        if (!SHUFFLED) revert HasNotBeenShuffled();
        // Make sure the caller owns the tokenId
        if (PRESENT_NFT.ownerOf(tokenId) != msg.sender) revert DoesNotOwnPresent();
    }

    /**
     * @notice Burns the present and sends the chosen gift to the user
     * @param tokenId - the token id of the Present NFT
     */
    function _openGiftTransfers(uint256 tokenId)
        internal
        returns (address chosenGiftAddress, uint256 chosenGiftTokenId)
    {
        // Select the randomized gift associated with the tokenId
        uint32 index = s_giftPoolIndices[tokenId - 1];
        Gift memory chosenGift = s_giftPool[index];

        // Trade the present for a random number
        PRESENT_NFT.burn(tokenId, msg.sender);
        s_chosenGifts[msg.sender].push(chosenGift);
        IERC721(chosenGift.nft).safeTransferFrom(address(this), msg.sender, chosenGift.tokenId);

        emit GiftChosen(msg.sender, tokenId, chosenGift.nft, chosenGift.tokenId);

        return (chosenGift.nft, chosenGift.tokenId);
    }

    /**
     * @notice Function that validates that the gift hash signature was signed by the designated signer authority
     * @param gifter - address of the gifter
     * @param nft - the address of the NFT being gifted
     * @param tokenId - the id of the NFT being gifted
     * @param sig - the signature of the gift hash
     * @dev Bypasses if signature isn't required
     */
    function _validateGiftHashSignatureIfRequired(address gifter, address nft, uint256 tokenId, bytes calldata sig)
        internal
        view
        virtual
        returns (bool)
    {
        if (!REQUIRES_SIGNATURE) return true;
        return validateGiftHashSignature(gifter, nft, tokenId, sig);
    }

    //======//
    // Misc //
    //======//

    /**
     * @notice OpenZeppelin requires ERC721Received implementation.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        public
        override
        returns (bytes4)
    {
        emit ERC721Received(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

    /**
     * @notice Function used to determine if a contract supports 721 interface
     * @param nft - the address of an NFT
     */
    function giftSupports721(address nft) public view returns (bool) {
        try IERC165(nft).supportsInterface(type(IERC721).interfaceId) returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }

    //===========//
    // Modifiers //
    //===========//

    modifier isNotPaused() {
        require(!PAUSED, "The NFT Exchange is currently paused.");
        _;
    }
}
