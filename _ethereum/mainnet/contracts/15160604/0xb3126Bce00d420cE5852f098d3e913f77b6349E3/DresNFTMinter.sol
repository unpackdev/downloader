//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

import "./IDresNFT.sol";

contract DresNFTMinter is Ownable, Pausable, ReentrancyGuard {
    enum MintRound {
        OG_MINT,
        EARLY_MINT,
        WHITELIST_MINT,
        WAITLIST_MINT,
        VIP_MINT
    }

    bytes32 public OG_ROOT =
        0x41d232ea3dd69cf14be1c3d633ec6dba5254a33503ca54c0c8126413acb39cae;

    bytes32 public EARLY_ROOT =
        0x2939dc8c6621c835ad311e7c7b42a09c52580b600ae5127fd7b09539b97228ff;

    bytes32 public WHITELIST_ROOT =
        0x1c1921a9a62327c5e3e6b4ab951bdde66f57affde6b53cf31b747775d28d131f;

    bytes32 public WAITLIST_ROOT =
        0x8d89f048346ccb9a64ecda2bf90be87d8e4b7203c66884141608e1682fa67c64;

    bytes32 public VIP_ROOT =
        0xc191326e8af922499223db6c5d59ac4e4dcb6ba76fd3e67d94c845424a9c7bf0;

    address public DRES_NFT;

    MintRound public mintRound;

    uint256 public mintingFee;

    bool public isReservedMint;

    mapping(address => bool) public ogParticipants;

    mapping(address => bool) public earlyParticipants;

    mapping(address => bool) public whitelistParticipants;

    mapping(address => bool) public waitlistParticipants;

    mapping(address => bool) public vipParticipants;

    constructor(address _nft) {
        DRES_NFT = _nft;
        _pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setVIPRoot(bytes32 _vipRoot) external onlyOwner {
        VIP_ROOT = _vipRoot;
    }

    function setOGRoot(bytes32 _ogRoot) external onlyOwner {
        OG_ROOT = _ogRoot;
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        WHITELIST_ROOT = _whitelistRoot;
    }

    function setWaitlistRoot(bytes32 _waitlistRoot) external onlyOwner {
        WAITLIST_ROOT = _waitlistRoot;
    }

    function setEarlyRoot(bytes32 _earlyRoot) external onlyOwner {
        EARLY_ROOT = _earlyRoot;
    }

    function toggleRound(
        MintRound _round,
        bool _isReservedMint,
        uint256 _mintingFee
    ) external onlyOwner {
        mintRound = _round;
        isReservedMint = _isReservedMint;
        mintingFee = _mintingFee;
    }

    function _updateParticipants() private {
        if (mintRound == MintRound.OG_MINT) {
            require(!ogParticipants[_msgSender()], "Already participated");
            ogParticipants[_msgSender()] = true;
        }

        if (mintRound == MintRound.EARLY_MINT) {
            require(!earlyParticipants[_msgSender()], "Already participated");
            earlyParticipants[_msgSender()] = true;
        }

        if (mintRound == MintRound.WHITELIST_MINT) {
            require(
                !whitelistParticipants[_msgSender()],
                "Already participated"
            );
            whitelistParticipants[_msgSender()] = true;
        }

        if (mintRound == MintRound.WAITLIST_MINT) {
            require(
                !waitlistParticipants[_msgSender()],
                "Already participated"
            );
            waitlistParticipants[_msgSender()] = true;
        }

        if (mintRound == MintRound.VIP_MINT) {
            require(!vipParticipants[_msgSender()], "Already participated");
            vipParticipants[_msgSender()] = true;
        }
    }

    function mint(bytes32[] calldata _proofs) external payable whenNotPaused {
        bytes32 merkleRoot = getMerkleRoot();

        require(
            MerkleProof.verify(
                _proofs,
                merkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Caller is not whitelisted"
        );
        require(msg.value == mintingFee, "Invalid fee");

        _updateParticipants();

        if (isReservedMint) {
            getDresNFT().mintReservedNFT(_msgSender(), 1);
        } else {
            getDresNFT().mint(_msgSender(), 1);
        }
    }

    function withdrawETH(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    function setDresNFT(address _nft) external onlyOwner {
        DRES_NFT = _nft;
    }

    function getDresNFT() public view returns (IDresNFT) {
        return IDresNFT(DRES_NFT);
    }

    function getMerkleRoot() public view returns (bytes32) {
        if (mintRound == MintRound.OG_MINT) {
            return OG_ROOT;
        }

        if (mintRound == MintRound.EARLY_MINT) {
            return EARLY_ROOT;
        }

        if (mintRound == MintRound.WHITELIST_MINT) {
            return WHITELIST_ROOT;
        }

        if (mintRound == MintRound.WAITLIST_MINT) {
            return WAITLIST_ROOT;
        }

        if (mintRound == MintRound.VIP_MINT) {
            return VIP_ROOT;
        }

        return bytes32(0);
    }
}
