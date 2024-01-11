// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract FuggleVille is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 333;
    uint256 public maxPerWallet = 1;
    bool public initialSaleStarted = false;
    bool public publicSaleStarted = false;
    bool public revealed = false;
    mapping(address => uint256) private _walletMints;

    string public baseURI = "";
    bytes32 public merkleRoot = 0x4ac3b5faddceb9ff0e177f15529d410f43a6e56b4527eb55c4c0ff1288d4232c;

    constructor() ERC721A("FuggleVille", "FUGGLE") {
        _safeMint(_msgSender(), 20);
    }

    function toggleInitialSale() external onlyOwner {
        initialSaleStarted = !initialSaleStarted;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        if (!revealed) {
            return "https://www.fuggleville.com/prereveal.json";
        }
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    function setMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
        maxPerWallet = _newMaxPerWallet;
    }

    function mint(uint256 tokens, bytes32[] calldata merkleProof) external {
        require(initialSaleStarted, "Mint has not started");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not eligible to mint");
        require(tx.origin == msg.sender, "Can't mint from a smart contract");
        require(tokens <= maxPerWallet, "Cannot purchase this many tokens in a transaction");
        require(_walletMints[_msgSender()] + tokens <= maxPerWallet, "Limit for this wallet reached");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    function publicMint(uint256 tokens) external {
        require(publicSaleStarted, "Public sale has not started");
        require(tx.origin == msg.sender, "Can't mint from a smart contract");
        require(tokens <= maxPerWallet, "Cannot purchase this many tokens in a transaction");
        require(_walletMints[_msgSender()] + tokens <= maxPerWallet, "Limit for this wallet reached");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }
}