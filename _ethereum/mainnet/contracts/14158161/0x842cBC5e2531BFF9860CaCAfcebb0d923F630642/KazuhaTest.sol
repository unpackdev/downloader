// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

contract KazuhaContract is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using MerkleProof for bytes32[];
    using SafeMath for uint256;
    using Strings for uint256;

    // ===== Variables =====
    string public baseTokenURI;
    uint256 public mintPrice = 0.08 ether;
    uint256 public collectionSize = 7777;
    uint256 public whitelistMintMaxSupply = 5500;
    uint256 public reservedSize = 77;
    uint256 public maxItemsPerWallet = 2;
    uint256 public maxItemsPerTx = 2;
    uint256 public devMintedAmount;

    bool public whitelistMintPaused = true;
    bool public raffleMintPaused = true;
    bool public publicMintPaused = true;

    bytes32 whitelistMerkleRoot;
    bytes32 rafflelistMerkleRoot;

    mapping(address => uint256) public whitelistMintedAmount;
    mapping(address => uint256) public raffleMintedAmount;


    
    constructor() ERC721A("KazuhaNFT", "Kazuha") {}

    modifier onlySender {
        require(msg.sender == tx.origin);
        _;
    }

    // Dev Mit
    function devMint(uint256 amount) external onlySender onlyOwner {
        devMintedAmount += amount;
        require(devMintedAmount <= reservedSize, "Minting amount exceeds reserved size");
        require(totalSupply() + amount <= collectionSize, "Sold out!");

        _safeMint(msg.sender, amount);

    }

    // Whitelist Mint
    function whitelistMint(uint256 amount, bytes32[] memory proof) external payable onlySender nonReentrant {
        address _msgSender =  msg.sender;
    
        require(!whitelistMintPaused, "Whitelist mint is paused");
        require(amount > 0 && amount <= maxItemsPerTx, "Amount to mint is 0");
        require(totalSupply() + amount <= collectionSize, "Sold out!");
        require(msg.value == mintPrice.mul(amount), "Must provide exact required ETH");
        require(isAddressWhitelisted(proof, _msgSender), "You are not eligible for a whitelist mint");
        require(whitelistMintedAmount[_msgSender] + amount <= maxItemsPerWallet,"Minting amount exceeds allowance per wallet");
        require(whitelistMintMaxSupply >= amount, "Whitelist mint is sold out");

        whitelistMintMaxSupply = whitelistMintMaxSupply - amount;
        whitelistMintedAmount[_msgSender] += amount;
        _safeMint(_msgSender, amount);
    }

    // Raffle Mint
    function raffleMint(uint256 amount, bytes32[] memory proof) external payable onlySender nonReentrant {
        address _msgSender =  msg.sender;

        require(!raffleMintPaused, "Raffle mint is paused");
        require(amount > 0 && amount <= maxItemsPerTx, "Amount to mint is 0");
        require(totalSupply() + amount <= collectionSize, "Sold out!");
        require(msg.value == mintPrice.mul(amount), "Must provide exact required ETH");
        require(isAddressOnRafflelist(proof, _msgSender),"You are not eligible for a raffle mint");
        require(raffleMintedAmount[_msgSender] + amount <= maxItemsPerWallet, "Minting amount exceeds allowance per wallet");

        raffleMintedAmount[_msgSender] += amount;

        _safeMint(_msgSender, amount);
    }

    // Public Mint
    function publicMint(uint256 amount) external payable onlySender nonReentrant {

        require(!publicMintPaused, "Public mint is paused");
        require(amount > 0 && amount <= maxItemsPerTx, "Amount to mint is 0");
        require(totalSupply()+ amount <= collectionSize, "Sold out!");
        require(msg.value == mintPrice.mul(amount), "Must provide exact required ETH");

        _safeMint(msg.sender, amount);
    }

    // Merkle Root Helpers

    function isAddressWhitelisted(bytes32[] memory proof, address _address) public view returns (bool) {
        return isAddressInMerkleRoot(whitelistMerkleRoot, proof, _address);
    }

    function isAddressOnRafflelist(bytes32[] memory proof, address _address) public view returns (bool){
        return isAddressInMerkleRoot(rafflelistMerkleRoot, proof, _address);
    }

    function isAddressInMerkleRoot(bytes32 merkleRoot, bytes32[] memory proof, address _address) internal pure returns (bool) {
        return proof.verify(merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    // Admin Functions
    function setReservedSize(uint256 _reservedSize) external onlyOwner {
        reservedSize = _reservedSize;
    }

    function setPublicMintPaused(bool _publicMintPaused) external onlyOwner {
        publicMintPaused = _publicMintPaused;
    }

    function setRaffleMintPaused(bool _raffleMintPaused) external onlyOwner {
        raffleMintPaused = _raffleMintPaused;
    }

    function setWhitelistMintPaused(bool _whitelistMintPaused) external onlyOwner {
        whitelistMintPaused = _whitelistMintPaused;
    }

    function setWhitelistMintMaxSupply(uint256 _whitelistMintMaxSupply) external onlyOwner {
        whitelistMintMaxSupply = _whitelistMintMaxSupply;
    }

    function setWhitelistMintMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setRaffleMintMerkleRoot(bytes32 _rafflelistMerkleRoot) external onlyOwner {
        rafflelistMerkleRoot = _rafflelistMerkleRoot;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxItemsPerTx(uint256 _maxItemsPerTx) external onlyOwner {
        maxItemsPerTx = _maxItemsPerTx;
    }

    function setMaxItemsPerWallet(uint256 _maxItemsPerWallet) external onlyOwner {
        maxItemsPerWallet = _maxItemsPerWallet;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdrawAll() external onlyOwner onlySender nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ether");
    }

    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
    return bytes(baseTokenURI).length != 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString())) : '';
    }
}