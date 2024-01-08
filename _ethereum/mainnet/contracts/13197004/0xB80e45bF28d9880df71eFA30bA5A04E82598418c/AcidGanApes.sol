// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract AcidGanApes is ERC721Enumerable, Ownable {
    uint256 public constant maxApes = 10000;
    uint256 private constant RESERVED_SUPPLY = 32;
    uint256 public constant maxBatch = 20;
    string public baseUri;
    uint256 public price = 4 * 1e7 gwei; // 0.04 ETH

    // Sale stuff
    uint256 public saleStart = 1632146400; // Mon Sep 20 2021 14:00:00 GMT+0000

    // Presale stuff
    uint256 public presaleStart = 1632144600; // Mon Sep 20 2021 13:30:00 GMT+0000
    mapping(address => uint256) public presaleAllowance;

    constructor() ERC721('Acid GAN Apes', 'AGANA') {
        baseUri = 'https://acidganapes.club/metadata/';

        for (uint256 i = 0; i < RESERVED_SUPPLY; i++) {
            uint256 mintIndex = i + 1;
            _mint(owner(), mintIndex);
        }
    }

    modifier canPresaleMint() {
        require(block.timestamp >= presaleStart, 'Presale not started');
        _;
    }

    modifier canMint() {
        require(block.timestamp >= saleStart, 'Sale not started');
        _;
    }

    function presaleMint(uint256 quantity) external payable canPresaleMint {
        require(quantity > 0 && quantity <= presaleAllowance[_msgSender()], 'Quantity must be x > 0 and x <= senderAllowance');
        require((totalSupply() + quantity) <= maxApes, 'Not enough apes');

        uint256 totalCost = quantity * price;
        require(msg.value >= totalCost, 'Insufficient ETH');

        presaleAllowance[_msgSender()] -= quantity;
        payable(owner()).transfer(msg.value);

        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _mint(_msgSender(), mintIndex);
        }
    }

    function mint(uint256 quantity) external payable canMint {
        require(quantity > 0 && quantity <= maxBatch, 'Quantity must be 0 < x <= maxBatch');
        require((totalSupply() + quantity) <= maxApes, 'Not enough apes');

        uint256 totalCost = quantity * price;
        require(msg.value >= totalCost, 'Insufficient ETH');
        payable(owner()).transfer(msg.value);

        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _mint(_msgSender(), mintIndex);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    // Admin functions
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseUri = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setSaleStart(uint256 saleStart_) external onlyOwner {
        saleStart = saleStart_;
    }

    function setPresaleStart(uint256 presaleStart_) external onlyOwner {
        presaleStart = presaleStart_;
    }

    function setPresaleAllowance(address addr, uint256 quantity) external onlyOwner {
        presaleAllowance[addr] = quantity;
    }

    function setPresaleAllowanceBulk(address[] memory addrs, uint256 [] memory quantities) external onlyOwner {
        for(uint256 i = 0; i < addrs.length; i++){
            presaleAllowance[addrs[i]] = quantities[i];
        }
    }
}