// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract NotDeGods is ERC721A, Ownable, ReentrancyGuard {

    string public        baseURI;
    uint public          price             = 0.005 ether;
    uint public          maxPerTx          = 30; 
    uint public          maxPerWallet      = 90;
    uint public          totalFree         = 999;
    uint public          maxSupply         = 9999;
    bool public          mintEnabled;

    constructor() ERC721A("Not De Gods", "NDG",30,9999)
    {
        baseURI = "ipfs://QmapSo4G8vHsn1Wf6jKYuvCFTfeMy6fzCekdPce3EoLveB/";
        mintEnabled = true;
    }

    function mint(uint256 amount) external payable
    {
        uint cost = price;
        if(totalSupply() + amount <= totalFree) {
            cost = 0;
        }
        require(msg.sender == tx.origin,"Be yourself, DeGods.");
        require(msg.value == amount * cost,"Please send the exact amount.");
        require(totalSupply() + amount <= maxSupply,"No more Not DeGods");
        require(mintEnabled, "Minting is not live yet, hold on Not DeGods.");
        require(numberMinted(msg.sender) + amount <= maxPerWallet,"Too many per wallet!");
        require(amount <= maxPerTx, "Max per TX reached.");
        _safeMint(msg.sender, amount);
    }

    function ownerBatchMint(uint256 amount) external onlyOwner
    {
        require(totalSupply() + amount <= maxSupply,"too many!");

        _safeMint(msg.sender, amount);
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setTotalFree(uint256 totalFree_) external onlyOwner {
        totalFree = totalFree_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }
}