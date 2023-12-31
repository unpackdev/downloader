// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

interface IDelegateRegistry {
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);
}

interface IRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC4906 {
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

contract Logos is ERC721, IERC4906, Ownable, ReentrancyGuard {
    IDelegateRegistry private constant DELEGATE_REGISTRY = IDelegateRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);
    address private constant BLITMAP_CONTRACT = 0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63;
    address private constant BLITNAUTS_CONTRACT = 0x448f3219CF2A23b0527A7a0158e7264B87f635Db; 

    bool public isOpen;
    bool public lockedClaims;
    bool public lockedRenderer;
    bytes32 public MERKLE_ROOT = 0x0;
    IRenderer public renderer;

    error Unauthorized();

    constructor(
        IRenderer initialRenderer,
        bytes32 merkleRoot
    ) ERC721("Logos", "LOGOS") Ownable() {
        renderer = initialRenderer;
        MERKLE_ROOT = merkleRoot;
    }

    // public

    function claim(
        uint256[] calldata tokenIds,
        bytes32[] calldata merkleProof,
        address _vault
    ) external nonReentrant {
        require(!lockedClaims, "Locked");
        require(isOpen, "Closed");

        address requester = msg.sender;

        if (_vault != address(0)) {
            bool isDelegateValid = 
                DELEGATE_REGISTRY.checkDelegateForContract(msg.sender, _vault, BLITMAP_CONTRACT) ||
                DELEGATE_REGISTRY.checkDelegateForContract(msg.sender, _vault, BLITNAUTS_CONTRACT);

            require(isDelegateValid, "Invalid delegate-vault pair");
            requester = _vault;
        }

        if (
            !MerkleProof.verify(
                merkleProof,
                MERKLE_ROOT,
                keccak256(
                    bytes.concat(keccak256(abi.encode(requester, tokenIds)))
                )
            )
        ) revert Unauthorized();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(msg.sender, tokenIds[i]); // even if using a vault, go to the sender
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return renderer.tokenURI(tokenId);
    }

    // privileged

    function setIsOpen(bool open) external onlyOwner {
        isOpen = open;
    }

    function lockClaims(string memory ack) external onlyOwner {
        require(keccak256(abi.encodePacked(ack)) == keccak256(abi.encodePacked("This action is permanent")), "Incorrect ack");
        lockedClaims = true;
    }

    function lockRenderer(string memory ack) external onlyOwner {
        require(keccak256(abi.encodePacked(ack)) == keccak256(abi.encodePacked("This action is permanent")), "Incorrect ack");
        lockedRenderer = true;
    }

    function setRenderer(IRenderer newRenderer) external onlyOwner {
        require(!lockedRenderer, "Locked");
        renderer = newRenderer;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        MERKLE_ROOT = newMerkleRoot;
    }

    function refreshMetadata(
        uint256 _fromTokenId,
        uint256 _toTokenId
    ) external onlyOwner {
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
    }
}