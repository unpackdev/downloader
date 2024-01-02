// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC2981.sol";
import "./MessageHashUtils.sol";
import "./ECDSA.sol";

import "./JoeRian.sol";

contract JoeRianClaimMinter is Ownable, Pausable {
    struct MintData {
        bool canUseWildcards;
        address receiver;
        uint256 tokenId;
        uint256 setsCount;
        // ECDSA signature
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct OperatorData {
        address operator;
        bool isBlacklisted;
    }

    event OperatorBlacklistUpdate(address indexed operator, bool indexed isBlacklisted);

    error InvalidMintDataSigner();
    error SignatureHasAlreadyBeenUsed();
    error InvalidMintDataSignature();
    error InvalidWildcardTokenOwnership();
    error InvalidWildcardToken();

    ERC721 public immutable ogCollection;
    JoeRian public immutable newCollection;
    address public mintDataSigner;

    mapping(bytes32 => address) public signatureToMinterAddress;

    constructor(ERC721 _ogCollection, JoeRian _newCollection, address _mintDataSigner) Ownable(msg.sender) Pausable() {
        mintDataSigner = _mintDataSigner;
        ogCollection = _ogCollection;
        newCollection = _newCollection;

        _pause();
    }

    function claim(MintData memory _data, uint256 _wildcardId) external whenNotPaused {
        // Check card signature
        bytes32 hash = keccak256(abi.encodePacked(_data.canUseWildcards, _data.receiver, _data.tokenId, _data.setsCount));
        bytes32 message = MessageHashUtils.toEthSignedMessageHash(hash);

        if (signatureToMinterAddress[hash] != address(0)) {
            revert SignatureHasAlreadyBeenUsed();
        }

        signatureToMinterAddress[hash] = _data.receiver;

        if (ECDSA.recover(message, _data.v, _data.r, _data.s) != mintDataSigner) {
            revert InvalidMintDataSignature();
        }

        if (_data.canUseWildcards == true && _wildcardId != 0) {
            if (ogCollection.ownerOf(_wildcardId) != _data.receiver) {
                revert InvalidWildcardTokenOwnership();
            }

            if (
                // Jim Hat
                _wildcardId != 153 &&
                // Jim Hat Rebar
                _wildcardId != 248 &&
                // Jim Rebar
                _wildcardId != 294 &&
                // Jim Bald
                _wildcardId != 538 &&
                // Midwest Boy
                _wildcardId != 794 &&
                // Daddy's Head Hurts (1:1)
                _wildcardId != 959 &&
                // Midwest Boy
                _wildcardId != 963
            ) {
                revert InvalidWildcardToken();
            }

            _data.setsCount++;
        }

        // Mint NFTs
        newCollection.mint(_data.receiver, _data.tokenId, _data.setsCount * 3, '');
    }

    function getWildcardId(address _holder) external view returns (uint256 tokenId) {
        // Jim Hat
        if (ogCollection.ownerOf(153) == _holder) {
            return 153;
        }

        // Jim Hat Rebar
        if (ogCollection.ownerOf(248) == _holder) {
            return 248;
        }

        // Jim Rebar
        if (ogCollection.ownerOf(294) == _holder) {
            return 294;
        }

        // Jim Bald
        if (ogCollection.ownerOf(538) == _holder) {
            return 538;
        }

        // Midwest Boy
        if (ogCollection.ownerOf(794) == _holder) {
            return 794;
        }

        // Daddy's Head Hurts (1:1)
        if (ogCollection.ownerOf(959) == _holder) {
            return 959;
        }

        // Midwest Boy
        if (ogCollection.ownerOf(963) == _holder) {
            return 963;
        }

        return 0;
    }

    // =============================================================
    // Maintenance Operations
    // =============================================================

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        if (mintDataSigner == address(0)) {
            revert InvalidMintDataSigner();
        }

        _unpause();
    }

    function setMintDataSigner(address _mintDataSigner) public onlyOwner {
        mintDataSigner = _mintDataSigner;
    }
}
