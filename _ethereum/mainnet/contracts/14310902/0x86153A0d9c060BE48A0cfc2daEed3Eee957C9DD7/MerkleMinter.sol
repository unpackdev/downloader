// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./Pausable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IKaijuNFT.sol";

/// @title Merkle tree driven minting of Kaiju NFTs
contract MerkleMinter is Pausable, Ownable {
    event MerkleTreeUpdated(TreeType indexed treeType);
    event Purchased(bytes32 indexed nfcId, TreeType indexed treeType, address indexed recipient);

    enum TreeType { OPEN, GATED }

    struct KaijuDNA { bytes32 nfcId; uint256 birthday; string tokenUri; }
    struct MerkleTreeMetadata { bytes32 root; string dataIPFSHash; }

    MerkleTreeMetadata public gatedMerkleTreeMetadata; // single claim to a Kaiju by a specific address
    MerkleTreeMetadata public openMerkleTreeMetadata; // first come first serve Kaiju NFT

    IKaijuNFT public nft;
    uint256 public pricePerNFTInETH;
    uint256 public gatedMintPricePerNFTInETH;
    mapping(bytes32 => bool) public proofUsed;

    constructor(IKaijuNFT _nft, uint256 _pricePerNFTInETH, uint256 _gatedMintPricePerNFTInETH, address _owner) {
        require(address(_nft) != address(0), "Invalid nft");
        require(_owner != address(0) && _owner != address(_nft) && _owner != address(this), "Invalid owner");

        nft = _nft;
        pricePerNFTInETH = _pricePerNFTInETH;
        gatedMintPricePerNFTInETH = _gatedMintPricePerNFTInETH;

        _transferOwnership(_owner);
        _pause();
    }

    function canOpenMint(KaijuDNA calldata _dna, bytes32[] calldata _merkleProof) external view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_dna.nfcId, _dna.tokenUri, _dna.birthday));
        return MerkleProof.verify(_merkleProof, openMerkleTreeMetadata.root, node) && !proofUsed[node];
    }

    function openMint(address _recipient, KaijuDNA calldata _dna, bytes32[] calldata _merkleProof)
    public whenNotPaused payable {
        require(msg.value >= pricePerNFTInETH, "ETH pls");
        require(_recipient != address(0) && _recipient != address(this), "Blocked");

        bytes32 node = keccak256(abi.encodePacked(_dna.nfcId, _dna.tokenUri, _dna.birthday));
        require(!proofUsed[node], "Proof used");
        require(MerkleProof.verify(_merkleProof, openMerkleTreeMetadata.root, node), "Proof invalid");
        proofUsed[node] = true;

        require(nft.mintTo(_recipient, _dna.nfcId, _dna.tokenUri, _dna.birthday), "Failed");

        emit Purchased(_dna.nfcId, TreeType.OPEN, _recipient);
    }

    function multiOpenMint(address _recipient, KaijuDNA[] calldata _dnas, bytes32[][] calldata _merkleProofs)
    external payable {
        uint256 numItemsToMint = _dnas.length;
        require(numItemsToMint > 0 && msg.value == (pricePerNFTInETH * numItemsToMint), "ETH pls");
        unchecked {
            for (uint256 i; i < numItemsToMint; ++i) {
                openMint(_recipient, _dnas[i], _merkleProofs[i]);
            }
        }
    }

    function canGatedMint(address _recipient, KaijuDNA calldata _dna, bytes32[] calldata _merkleProof) external view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_recipient, _dna.nfcId, _dna.tokenUri, _dna.birthday));
        return MerkleProof.verify(_merkleProof, gatedMerkleTreeMetadata.root, node) && !proofUsed[node];
    }

    function gatedMint(address _recipient, KaijuDNA calldata _dna, bytes32[] calldata _merkleProof)
    public whenNotPaused payable {
        require(msg.value >= gatedMintPricePerNFTInETH, "ETH pls");
        require(_recipient != address(0) && _recipient != address(this), "Blocked");

        bytes32 node = keccak256(abi.encodePacked(_recipient, _dna.nfcId, _dna.tokenUri, _dna.birthday));
        require(!proofUsed[node], "Proof used");
        require(MerkleProof.verify(_merkleProof, gatedMerkleTreeMetadata.root, node), "Proof invalid");
        proofUsed[node] = true;

        require(nft.mintTo(_recipient, _dna.nfcId, _dna.tokenUri, _dna.birthday), "Failed");

        emit Purchased(_dna.nfcId, TreeType.GATED, _recipient);
    }

    function multiGatedMint(address _recipient, KaijuDNA[] calldata _dnas, bytes32[][] calldata _merkleProofs)
    external payable {
        uint256 numItemsToMint = _dnas.length;
        require(numItemsToMint > 0 && msg.value == (gatedMintPricePerNFTInETH * numItemsToMint), "ETH pls");
        unchecked {
            for (uint256 i; i < numItemsToMint; ++i) {
                gatedMint(_recipient, _dnas[i], _merkleProofs[i]);
            }
        }
    }

    function pause() onlyOwner whenNotPaused external { _pause(); }

    function unpause() onlyOwner whenPaused external { _unpause(); }

    function withdrawSaleProceeds(address payable _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient");
        _recipient.transfer(_amount);
    }

    function updateMerkleTree(MerkleTreeMetadata calldata _metadata, TreeType _treeType) external onlyOwner whenPaused {
        _updateMerkleTree(_metadata, _treeType);
    }

    function updatePrice(uint256 _newPrice) external onlyOwner {
        pricePerNFTInETH = _newPrice;
    }

    function updateGatedPrice(uint256 _newPrice) external onlyOwner {
        gatedMintPricePerNFTInETH = _newPrice;
    }

    function updateNFT(IKaijuNFT _nft) external onlyOwner {
        require(address(_nft) != address(0), "Invalid nft");
        nft = _nft;
    }

    function _updateMerkleTree(MerkleTreeMetadata calldata _metadata, TreeType _treeType) private {
        require(bytes(_metadata.dataIPFSHash).length == 46, "Invalid hash");
        require(_metadata.root != bytes32(0), "Invalid root");

        if (_treeType == TreeType.GATED) {
            gatedMerkleTreeMetadata = _metadata;
        } else {
            openMerkleTreeMetadata = _metadata;
        }

        emit MerkleTreeUpdated(_treeType);
    }
}
