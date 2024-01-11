// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract Onliners is ERC721A, Ownable, ReentrancyGuard {

    // Merkle root for pre-sale
    bytes32 public merkleRoot;

    // Max mint amount per wallet
    uint256 public MAX_MINT_PER_WALLET_PRESALE = 4;

    // Sale status
    bool public enablePresale = false;
    bool public enableSale = false;

    // Price
    uint256 public PRICE_PRESALE = 0.099 ether;
    uint256 public PRICE_SALE = 0.11 ether;

    uint256 public maxSupply = 8_000;

    string public baseTokenURI;

    // Track the number of NFT minted for each sale round
    struct User {
        uint256 countPresale;
        uint256 countSale;
    }

    mapping(address => User) public users;

    constructor() ERC721A("Onliners", "Onliners") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        require(_maxSupply != maxSupply, 'Invalid supply');
        maxSupply = _maxSupply;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPricePresale(uint256 _price) external onlyOwner {
        require(PRICE_PRESALE != _price, "Invalid price");
        PRICE_PRESALE = _price;
    }

    function setPriceSale(uint256 _price) external onlyOwner {
        require(PRICE_SALE != _price, "Invalid price");
        PRICE_SALE = _price;
    }

    function setEnablePresale(bool _enable) external onlyOwner {
        require(enablePresale != _enable, "Invalid status");
        enablePresale = _enable;
    }

    function setEnableSale(bool _enable) external onlyOwner {
        require(enableSale != _enable, "Invalid status");
        enableSale = _enable;
    }

    function setMaxMintPerWalletPresale(uint256 _limit) external onlyOwner {
        require(MAX_MINT_PER_WALLET_PRESALE != _limit, "New limit is the same as the existing one");
        MAX_MINT_PER_WALLET_PRESALE = _limit;
    }

    function getMints(address _wallet) external view returns (uint) {
        return _numberMinted(_wallet);
    }

    function mintPresale(bytes32[] calldata _merkleProof, uint256 _amount) external nonReentrant payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(enablePresale, "Pre-sale is not enabled");
        require(totalSupply() + _amount <= maxSupply, "Exceeds maximum supply");
        require(tx.origin == msg.sender, "Contract denied");
        require(
            users[msg.sender].countPresale + _amount <= MAX_MINT_PER_WALLET_PRESALE,
            "Exceeds max mint limit per wallet");
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Proof Invalid");
        require(msg.value >= PRICE_PRESALE * _amount, "Value below price");

        _safeMint(msg.sender, _amount);
        users[msg.sender].countPresale = users[msg.sender].countPresale + _amount;
    }

    function mintSale(uint256 _amount) external nonReentrant payable {
        require(enableSale, "Sale is not enabled");
        require(tx.origin == msg.sender, "Contract denied");
        require(totalSupply() + _amount <= maxSupply, "Exceeds maximum supply");
        require(msg.value >= PRICE_SALE * _amount, "Value below price");

        _safeMint(msg.sender, _amount);
        users[msg.sender].countSale = users[msg.sender].countSale + _amount;
    }

    function ownerMint(uint _amount) external nonReentrant onlyOwner {
        require(tx.origin == msg.sender, 'Contract Denied');
        require(totalSupply() + _amount <= maxSupply, "Exceeds maximum supply");

        _safeMint(msg.sender, _amount);
    }

    function withdraw() external nonReentrant onlyOwner {
        require(tx.origin == msg.sender, 'Contract denied');
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is 0");
        payable(msg.sender).transfer(balance);
    }
}
