// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract TheWonderBag is ERC721A, ReentrancyGuard, Ownable {
    uint8 public constant MAX_PUBLIC_MINT = 10;
    uint8 public constant MAX_WHITELIST_MINT = 5;
    uint16 public constant MAX_SUPPLY = 8888;
    uint128 public constant PUBLIC_MINT_PRICE = 0.1 ether;

    uint128 public whitelistMintPrice = 0.075 ether;
    bool public isPublicMintActive = false;
    bool public isWhitelistMintActive = false;

    bytes32 private _merkleRoot;
    string private _currentBaseURI = "ipfs://QmdNqPB6HKV4afbfnUCcDvvxAA4m5JxhAxCmWnqxZ4ugPA/";
    mapping(address => uint8) private _whitelistMintCount;

    constructor() ERC721A("The WonderBag", "WB") {}

    function numAvailableToMintWhitelist(address addr) external view returns (uint8) {
        return MAX_WHITELIST_MINT - _whitelistMintCount[addr];
    }

    function mint(uint8 numberOfTokens) external payable nonReentrant {
        _mintChecks(numberOfTokens, isPublicMintActive, MAX_PUBLIC_MINT, PUBLIC_MINT_PRICE);
        _safeMint(msg.sender, numberOfTokens);
    }

    function mintWhitelist(bytes32[] calldata merkleProof, uint8 numberOfTokens) external payable nonReentrant {
        _mintChecks(numberOfTokens, isWhitelistMintActive, MAX_WHITELIST_MINT - _whitelistMintCount[msg.sender], whitelistMintPrice);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _merkleRoot, leaf), "Invalid proof");

        _safeMint(msg.sender, _numberOfTokensToMintWhitelist(numberOfTokens));
        _whitelistMintCount[msg.sender] += numberOfTokens;
    }

    function _numberOfTokensToMintWhitelist(uint8 numberOfTokens) private view returns (uint8) {
        uint8 totalToMint = numberOfTokens;
        uint8 numberOfBonusTokens = 0;

        if (numberOfTokens == 3) numberOfBonusTokens = 1;
        else if (numberOfTokens == 4) numberOfBonusTokens = 2;
        else if (numberOfTokens == 5) numberOfBonusTokens = 3;

        uint8 newNumberOfTokens = numberOfTokens + numberOfBonusTokens;
        if (totalSupply() + newNumberOfTokens <= MAX_SUPPLY) {
            totalToMint = newNumberOfTokens;
        } else {
            totalToMint = uint8(MAX_SUPPLY - totalSupply());
        }

        return totalToMint;
    }

    function _mintChecks(uint8 numberOfTokens, bool isMintActive, uint8 tokensLimit, uint128 price) private view {
        // Block zero tokens mint
        require(numberOfTokens > 0, "Has to be positive");

        // Block mint if not active
        require(isMintActive, "Not active");

        // Block mint if sender has exceeded his max value to purchase
        require(numberOfTokens <= tokensLimit, "Exceeded max token purchase");

        // Block transactions that would exceed the maxSupply
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Supply is exhausted");

        // Block transactions that don't provide enough ether
        require(msg.value >= price * numberOfTokens, "Insufficient ether value");
    }

    function reserve(uint256 numberOfTokens) external onlyOwner {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Supply is exhausted");
        _safeMint(msg.sender, numberOfTokens);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _currentBaseURI = baseURI_;
    }

    function setIsMintActive(bool isPublicMintActive_, bool isWhitelistMintActive_) external onlyOwner {
        isPublicMintActive = isPublicMintActive_;
        isWhitelistMintActive = isWhitelistMintActive_;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setWhitelistMintPrice(uint128 _whitelistMintPrice) external onlyOwner {
        whitelistMintPrice = _whitelistMintPrice;
    }

    function withdrawEth() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = payable(msg.sender).call{value : balance}("");
        require(success, "Withdraw failed");
    }
}
