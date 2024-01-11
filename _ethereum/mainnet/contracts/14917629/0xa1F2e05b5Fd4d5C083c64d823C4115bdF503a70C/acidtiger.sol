// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract AcidTiger is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;  
    uint public price = 5000000000000000; //0.005 ETH
    uint public maxPerTx = 20; 
    uint public maxPerWallet = 60;
    uint public totalFree = 1500;
    uint public maxSupply = 4444;
    uint public freeMint = 5;
    bool public mintEnabled = true;
    mapping (address => uint256) public addressMint;

    constructor() ERC721A("Acid Tiger", "AT"){}

    function mint(uint256 amount) external payable
    {
        uint cost = price;
        if(msg.value == 0 && totalSupply() + amount <= totalFree) {
           require(addressMint[msg.sender] + amount <= freeMint,"Claimed");
           cost = 0;
           addressMint[msg.sender] += amount;
        }
        require(msg.value == amount * cost,"Insufficient Funds");
        require(totalSupply() + amount <= maxSupply,"Soldout");
        require(mintEnabled, "Minting Pause");
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
}