// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";

contract AneroV2 is ERC721A, ERC2981, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    bytes32 public merkleRoot;
    string private _baseTokenURI;
    mapping(address => bool) public claimed;

    constructor(
        bytes32 _merkleRoot,
        string memory _baseURIString,
        uint16 maxBatchSize,
        uint16 collectionSize
    ) ERC721A("AneroV2", "AneroV2", maxBatchSize, collectionSize) {
        _baseTokenURI = _baseURIString;
        merkleRoot = _merkleRoot;
        _pause();
    }

    modifier verifyProof(bytes32[] memory _proof, uint256 _amount) {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(MerkleProof.verify(_proof, merkleRoot, _leaf), "invalid proof");
        _;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _mintBatch(address user, uint256 quantity) internal {
        uint256 batchMintAmount = quantity > maxBatchSize
            ? maxBatchSize
            : quantity;
        uint256 numChunks = quantity / batchMintAmount;
        uint256 remainingAmount = quantity % batchMintAmount;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(user, batchMintAmount);
        }
        if (remainingAmount > 0) {
            _safeMint(user, remainingAmount);
        }

    }

    function mint(
        bytes32[] memory _proof,
        uint256 _amount
    ) external verifyProof(_proof, _amount) whenNotPaused {
        require(!claimed[msg.sender], "Already claimed");
        require(_amount > 0, "Amount must be greater than zero");

        _mintBatch(msg.sender, _amount);
        claimed[msg.sender] = true;
    }

    function setPause(bool value) external onlyOwner {
        if (value) {
            _pause();
        } else {
            _unpause();
        }
    }

     /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function deleteRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function mintAdmin(uint256 quantity) external onlyOwner whenPaused {
        _mintBatch(msg.sender, quantity);
    }
}
