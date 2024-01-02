// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Prohibition / VenturePunk,LLC
// Written By: Thomas Lipari (thom.eth)
pragma solidity ^0.8.23;

import "./ECDSA.sol";
import "./IERC721.sol";
import "./IDelegateRegistry.sol";

import "./ITokenGatedSantaProtocol.sol";
import "./SantaProtocol.sol";

/**
 * @title The TokenGatedSantaProtocol contract
 * @author Thomas Lipari (thom.eth)
 * @notice An extension of the SantaProtocol contract that adds token gating
 */
contract TokenGatedSantaProtocol is SantaProtocol, ITokenGatedSantaProtocol {
    using ECDSA for bytes32;

    //=========//
    // Storage //
    //=========//

    /* Delegate */

    IDelegateRegistry public constant DELEGATE_REGISTRY = IDelegateRegistry(0x00000000000000447e69651d841bD8D104Bed493);

    /* Token Gating */

    // An optional ERC721 that can be used to gate access to the protocol
    IERC721 public TOKEN_GATE_CONTRACT;
    // The maximum number of times an account can participate per owned token ID
    uint32 public TOKEN_GATE_LIMIT;
    // Whether or not delegated wallets are supported
    bool public SUPPORTS_DELEGATES = true;
    // Mapping of token gate NFTs to token IDs to number of times they've been used
    mapping(address tokenGateNft => mapping(uint256 tokenId => uint32 usedCount)) public _tokenGateNftUsed;

    //=============//
    // Constructor //
    //=============//

    /**
     * @notice Constructor inherits SantaProtocol and RandomNumberConsumerV2
     * @param subscriptionId - the subscription ID that this contract uses for funding Chainlink VFR requests
     * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
     * @param keyHash - the Chainlink gas lane to use, which specifies the maximum gas price to bump to
     * @param registrationEnd - the time that registration/adding gifts ends
     * @param redemptionStart - the time that participants can begin redeeming their gifts
     * @param signer - the address of the signer that signs the gift hashes
     * @param presentNft - the address of the NFT that represents the gifts in the pool
     * @param tokenGateNft - the address of the NFT being used to gate access to the protocol
     * @param tokenGateLimit - the maximum number of times an account can participate per owned token ID
     */
    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 registrationEnd,
        uint256 redemptionStart,
        address signer,
        address presentNft,
        address tokenGateNft,
        uint32 tokenGateLimit
    ) SantaProtocol(subscriptionId, vrfCoordinator, keyHash, registrationEnd, redemptionStart, signer, presentNft) {
        if (tokenGateNft != address(0)) {
            TOKEN_GATE_CONTRACT = IERC721(tokenGateNft);
            TOKEN_GATE_LIMIT = tokenGateLimit;
        }
    }

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
        public
        virtual
        isNotPaused
        returns (address giftAddress, uint256 giftTokenId)
    {
        // If the pool isn't token gated, revert
        if (address(TOKEN_GATE_CONTRACT) == address(0)) revert PoolIsNotTokenGated();
        // Run validity check
        _addGiftChecks(nft, tokenId);
        // If the NFT doesn't pass token gating
        _tokenGate(msg.sender, tokenGateNft, tokenGateTokenId);
        // If the signature isn't valid, revert
        if (!_validateTokenGateSignatureIfRequired(msg.sender, nft, tokenId, tokenGateNft, tokenGateTokenId, sig)) {
            revert InvalidSignature();
        }

        // Add the gift to the pool and mint a PresentNft to the user that added the gift
        (giftAddress, giftTokenId) = _addGiftTransfers(nft, tokenId);
    }

    /**
     * @notice Disabled because token gate requires more values
     * @param nft - the address of the NFT being added
     * @param tokenId - the token id of the NFT being added
     * @param sig - a message signed by the signer address verifying the NFT is eligible
     */
    function addGift(address nft, uint256 tokenId, bytes calldata sig)
        public
        virtual
        override(SantaProtocol)
        isNotPaused
        returns (address giftAddress, uint256 giftTokenId)
    {
        if (address(TOKEN_GATE_CONTRACT) != address(0)) revert TokenGated();
        return super.addGift(nft, tokenId, sig);
    }

    //================//
    // View Functions //
    //================//

    /**
     * @notice Get the the address of the TokenGate NFT
     */
    function getTokenGateContract() public view returns (address) {
        return address(TOKEN_GATE_CONTRACT);
    }

    /**
     * @notice Function that checks if an NFT is eligible to be used to gate access to the protocol
     * @param account - the account that is using the NFT
     * @param tokenGateNft - the address of the NFT being used to gate access to the protocol
     * @param tokenGateTokenId - the token id of the NFT being used to gate access to the protocol
     */
    function getTokenGateEligibility(address account, address tokenGateNft, uint256 tokenGateTokenId)
        public
        view
        virtual
        returns (bool eligible)
    {
        if (address(TOKEN_GATE_CONTRACT) == address(0)) return true;
        if (tokenGateNft != address(TOKEN_GATE_CONTRACT)) return false;
        if (!_validateOwnershipOrDelegation(account, tokenGateNft, tokenGateTokenId)) return false;
        if (TOKEN_GATE_LIMIT == 0) return true;
        if (_tokenGateNftUsed[tokenGateNft][tokenGateTokenId] >= TOKEN_GATE_LIMIT) return false;
        return true;
    }

    /**
     * @notice Function that checks if the token gate support delegates
     */
    function getSupportsDelegates() public view returns (bool) {
        return SUPPORTS_DELEGATES;
    }

    //=================//
    // Admin Functions //
    //=================//

    /**
     * @notice Function that allows the owners to update the address of the Token Gate NFT
     * @param newTokenGateNft - new address of the Token Gate NFT
     */
    function setTokenGateContract(address newTokenGateNft) public onlyOwner {
        TOKEN_GATE_CONTRACT = IERC721(newTokenGateNft);
    }

    /**
     * @notice Function that allows the owners to update the address of the Token Gate NFT
     * @param newTokenGateLimit - new address of the Token Gate NFT
     */
    function setTokenGateLimit(uint32 newTokenGateLimit) public onlyOwner {
        TOKEN_GATE_LIMIT = newTokenGateLimit;
    }

    /**
     * @notice Function that allows the owners to toggle whether or not delegated wallets are supported
     */
    function toggleSupportsDelegates() public onlyOwner {
        SUPPORTS_DELEGATES = !SUPPORTS_DELEGATES;
    }

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
    ) public view override returns (bytes32) {
        bytes32 tokenGateHash = keccak256(abi.encode(tokenGateNft, tokenGateTokenId));
        return keccak256(abi.encode(getContractHash(), hashGift(gifter, nft, tokenId), tokenGateHash));
    }

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
    ) public view override returns (bool) {
        bytes32 tokenGateHash = hashTokenGateGift(gifter, nft, tokenId, tokenGateNft, tokenGateTokenId);
        bytes32 ethSignedMessageHash = tokenGateHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(sig);
        return signer == s_signer;
    }

    //==========//
    // Internal //
    //==========//

    /**
     * @notice Checks if an NFT being used by an account passes token gating.
     * @param account - the account that is using the NFT
     * @param nft - the address of the NFT being used
     * @param tokenId - the token id of the NFT being used
     * @dev Only used if token gating is enabled and updates the tally of times an NFT has been used.
     */
    function _tokenGate(address account, address nft, uint256 tokenId) internal virtual {
        // If the nft isn't the token gate nft...
        if (nft != address(TOKEN_GATE_CONTRACT)) {
            revert NotTokenGateCollection();
        }

        // If there's a limit on each token's use and the token has been used too many times...
        if (TOKEN_GATE_LIMIT != 0 && _tokenGateNftUsed[nft][tokenId] >= TOKEN_GATE_LIMIT) {
            revert TokenGateLimitReached();
        }

        // If the account doesn't own the token nor has been delegated use of it...
        if (!_validateOwnershipOrDelegation(account, nft, tokenId)) {
            revert NotTokenGatedTokenHolder();
        }

        _tokenGateNftUsed[nft][tokenId]++;
    }

    /**
     * @notice Checks if an NFT is either owned by or delegated to an account
     * @param account - the account that is using the NFT
     * @param nft - the address of the NFT being used
     * @param tokenId - the token id of the NFT being used
     */
    function _validateOwnershipOrDelegation(address account, address nft, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        if (IERC721(nft).ownerOf(tokenId) == account) return true;
        if (!SUPPORTS_DELEGATES) return false;
        return DELEGATE_REGISTRY.checkDelegateForERC721(account, IERC721(nft).ownerOf(tokenId), nft, tokenId, 0);
    }

    /**
     * @notice Function that validates that the gift hash signature was signed by the designated signer authority
     * @param gifter - address of the gifter
     * @param nft - the address of the NFT being gifted
     * @param tokenId - the id of the NFT being gifted
     * @param tokenGateNft - the address of the NFT being used to gate access to the protocol
     * @param tokenGateTokenId - the token id of the NFT being used to gate access to the protocol
     * @param sig - the signature of the gift hash
     * @dev Bypasses if signature isn't required
     */
    function _validateTokenGateSignatureIfRequired(
        address gifter,
        address nft,
        uint256 tokenId,
        address tokenGateNft,
        uint256 tokenGateTokenId,
        bytes calldata sig
    ) internal view virtual returns (bool) {
        if (!REQUIRES_SIGNATURE) return true;
        return validateTokenGateSignature(gifter, nft, tokenId, tokenGateNft, tokenGateTokenId, sig);
    }
}
