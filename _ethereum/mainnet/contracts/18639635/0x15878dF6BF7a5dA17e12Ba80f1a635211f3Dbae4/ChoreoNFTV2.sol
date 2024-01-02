pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Base64.sol";
import "./ChoreoLibrary.sol";
import "./IChoreoScore.sol";
import "./ChoreoStorage.sol";


interface IArtblocks is IERC721 {
    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32);
}

contract ChoreoNFTV2 is ERC721, Ownable, ChoreoStorage {
    error AlreadyClaimed();
    error TokenDoesNotExist();
    error InvalidProof();
    error NotOwner();
    error NotTransferable();
    error TokenHashMismatch();

    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    /** Claim Storage**/
    bytes32 public root;
    IArtblocks public primaryNFT;

    IChoreoScore public choreoScore;

    constructor(
        string memory name_,
        string memory symbol_,
        bytes32 _root,
        address _primaryNFTAddress,
        IChoreoScore choreoScore_
    ) ERC721(name_, symbol_) {
        choreoScore = choreoScore_;
        primaryNFT = IArtblocks(_primaryNFTAddress);
        root = _root;
    }

    function checkProof(
        bytes32[] memory proof,
        bytes memory choreoEncoded
    ) public view returns (bool) {
        bytes32 leaf = keccak256(choreoEncoded);

        if (!MerkleProof.verify(proof, root, leaf)) revert InvalidProof();

        return true;
    }

    function claim(
        uint256 tokenId,
        bytes32[] memory proof,
        bytes memory choreoEncoded
    ) external {
        // Require token not already claimed
        if (_exists(tokenId)) revert AlreadyClaimed();

        // Require primary token owner matches sender
        if (primaryNFT.ownerOf(tokenId) != msg.sender) revert NotOwner();

        // Get token hash to validate proof
        (bytes32 _tokenHash, bytes memory compressedChoreo) = decodeChoreoProof(choreoEncoded);
        if (primaryNFT.tokenIdToHash(tokenId) != _tokenHash)
            revert TokenHashMismatch();

        // Require valid merkle proof of choreo
        require(checkProof(proof, choreoEncoded));

        // Store choreo for token art generation
        _storeChoreoCompressed(tokenId, compressedChoreo);

        // Send secondary token to owner
        _mint(msg.sender, tokenId);
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setChoreoScore(IChoreoScore _choreoScore) external onlyOwner {
        choreoScore = _choreoScore;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        address owner = primaryNFT.ownerOf(tokenId);
        return owner;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return
            choreoScore.renderTokenURI(
                tokenId,
                decodeCompressedChoreo(tokenId)
            );
    }

    // disallow transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        if (from != address(0)) revert NotTransferable();
    }
}
