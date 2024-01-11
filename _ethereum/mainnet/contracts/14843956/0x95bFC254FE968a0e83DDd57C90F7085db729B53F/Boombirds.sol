// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Boombirds is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public freeAddress;
    string public baseURI;  
    uint public price = 7000000000000000; //0.007 ETH
    uint public minWallet = 100000000000000000; //0.1 ETH
    uint public maxPerTx = 30; 
    uint public maxPerWallet = 90;
    uint public totalFree = 2000;
    uint public maxSupply = 10000;
    uint public freeMint = 1;
    bool public mintEnabled;
    constructor() ERC721A("Boombirds", "Boombirds",90,10000){}

    function mint(uint256 amount) external payable
    {
        require(mintEnabled, "Minting Pause");
        uint cost = price;
        if(msg.value == 0 && totalSupply() + amount <= totalFree) {
           require(address(msg.sender).balance >= minWallet,"Insufficient Funds");
           require(freeAddress[msg.sender] + amount <= freeMint,"Limit");
           cost = 0;
           freeAddress[msg.sender] += amount;
        }
        require(msg.value == amount * cost,"Insufficient Funds");
        require(totalSupply() + amount <= maxSupply,"Soldout");
        require(numberMinted(msg.sender) + amount <= maxPerWallet,"Max Per Wallet");
        require(amount <= maxPerTx, "Limit Per Transaction");
        _safeMint(msg.sender, amount);
    }

    function airdrop(address to ,uint256 amount) external onlyOwner
    {
        _safeMint(to, amount);
    }
    function ownerBatchMint(uint256 amount) external onlyOwner
    {
        require(totalSupply() + amount <= maxSupply,"too many!");

        _safeMint(msg.sender, amount);
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setMinWallet(uint256 minWallet_)  external onlyOwner {
        minWallet = minWallet_;
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
    function setFreeMint(uint256 freeMint_) external onlyOwner {
        freeMint = freeMint_;
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