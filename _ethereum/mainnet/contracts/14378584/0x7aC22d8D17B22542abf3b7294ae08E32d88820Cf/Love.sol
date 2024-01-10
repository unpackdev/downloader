// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author Nathan G

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Love is ERC721Enumerable, Ownable, ReentrancyGuard {

    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public merkleRoot;

    Counters.Counter private _nftIdCounter;

    uint public constant MAX_SUPPLY = 2611;

    string public baseURI;
    string public notRevealedURI;
    string public baseExtension = ".json";

    bool public isRevealed = false;
    bool public isMintOpen = false;
    bool public isPublicSaleOpen = false;
    mapping(address => uint) public remainingToken;
    mapping(address => bool) public isRemainingSet;
    mapping(address => bool) public isGenesisRemainingSet;

    address private _owner;

    constructor() ERC721("Love by Milan Quadens", "LOVE") {
        transferOwnership(msg.sender);
    }

    function openMint(bool _isMintOpen) external onlyOwner {
        isMintOpen = _isMintOpen;
    }

    function openPublicSale(bool _isPublicSaleOpen) external onlyOwner {
        isPublicSaleOpen = _isPublicSaleOpen;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }


    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function reveal() external onlyOwner {
        isRevealed = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint numberOfTokens, bytes32[] calldata _merkleProof, uint balance) external nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'This address is not a holder.');
        require(isMintOpen, 'The mint is not open.');
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens.');
        if (!isGenesisRemainingSet[msg.sender] && !isPublicSaleOpen) {
            isGenesisRemainingSet[msg.sender] = true;
            remainingToken[msg.sender] = balance;
        } else if (!isRemainingSet[msg.sender] && isPublicSaleOpen) {
            isRemainingSet[msg.sender] = true;
            remainingToken[msg.sender] = balance;
        }
        require(numberOfTokens <= remainingToken[msg.sender], 'Exceeded max token purchase.');
        for (uint i = 0; i < numberOfTokens; i++) {
            _nftIdCounter.increment();
            _safeMint(msg.sender, _nftIdCounter.current());
        }
        remainingToken[msg.sender] -= numberOfTokens;
    }

    function tokenURI(uint _nftId) public view override(ERC721) returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");
        if (isRevealed == false) {
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _nftId.toString(), baseExtension))
            : "";
    }

    function reserve(uint n) external onlyOwner {
        require(totalSupply() + n <= MAX_SUPPLY, 'Purchase would exceed max tokens.');
        for (uint i = 0; i < n; i++) {
            _nftIdCounter.increment();
            _safeMint(msg.sender, _nftIdCounter.current());
        }
    }
}
