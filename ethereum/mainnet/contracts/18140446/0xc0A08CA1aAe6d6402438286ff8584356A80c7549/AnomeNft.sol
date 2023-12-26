// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";

contract AnomeNft is Ownable, ERC721A, ERC721AQueryable, ERC721ABurnable, Pausable {
    using Strings for uint256;

    error SaleNotActive();
    error InvalidMerkle();
    error AlreadyMint();
    error InvalidTokenId();
    error MaxSupplyExceeded();

    uint256 public constant MAX_ID = 2000;

    bytes32 private merkleRoot;
    string private _baseTokenURI;

    uint256 public startsAt;
    mapping(address => uint256) public mintsOf;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory __baseTokenUri,
        uint256 _startsAt
    ) ERC721A(_name, _symbol) {
        _baseTokenURI = __baseTokenUri;
        startsAt = _startsAt;
    }

    // ================ Mint ================

    function mint(bytes32[] calldata _proof) external payable {
        if (block.timestamp < startsAt) revert SaleNotActive();

        bytes32 leaf = keccak256(abi.encodePacked(_msgSenderERC721A()));
        if (!MerkleProof.verify(_proof, merkleRoot, leaf)) revert InvalidMerkle();

        if ((_totalMinted() + 1) > MAX_ID) revert MaxSupplyExceeded();

        if (mintsOf[_msgSenderERC721A()] > 0) revert AlreadyMint();
        mintsOf[_msgSenderERC721A()] += 1;

        _mint(_msgSenderERC721A(), 1);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // ================ Admin ================

    function withdrawAll() external onlyOwner {
        payable(payable(owner())).transfer(address(this).balance);
    }

    function mint(uint256 _mints, address _to) external onlyOwner {
        _mint(_to, _mints);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // ================ Extension ================

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    // ================ EIP-165 ================

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId);
    }
}
