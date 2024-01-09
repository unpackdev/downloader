// SPDX-License-Identifier: MIT
/*
 ________  ________  ________   ________  ________   ________     
|\   __  \|\   __  \|\   ___  \|\   __  \|\   ___  \|\   __  \    
\ \  \|\ /\ \  \|\  \ \  \\ \  \ \  \|\  \ \  \\ \  \ \  \|\  \   
 \ \   __  \ \   __  \ \  \\ \  \ \   __  \ \  \\ \  \ \   __  \  
  \ \  \|\  \ \  \ \  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \ \  \ 
   \ \_______\ \__\ \__\ \__\\ \__\ \__\ \__\ \__\\ \__\ \__\ \__\
    \|_______|\|__|\|__|\|__| \|__|\|__|\|__|\|__| \|__|\|__|\|__|
                                                                  
                                                                  
                                                                  
 ________  ________  ________  ________   ________                
|\   ____\|\   __  \|\   __  \|\   ___  \|\   ____\               
\ \  \___|\ \  \|\  \ \  \|\  \ \  \\ \  \ \  \___|_              
 \ \  \  __\ \  \\\  \ \  \\\  \ \  \\ \  \ \_____  \             
  \ \  \|\  \ \  \\\  \ \  \\\  \ \  \\ \  \|____|\  \            
   \ \_______\ \_______\ \_______\ \__\\ \__\____\_\  \           
    \|_______|\|_______|\|_______|\|__| \|__|\_________\          
                                            \|_________|          

*/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract BananaGoons is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable amountForDevs;
    uint256 public immutable amountForAuctionAndDev;

    struct SaleConfig {
        uint32 auctionSaleStartTime;
        uint32 publicSaleStartTime;
        uint64 mintlistPrice;
        uint64 publicPrice;
    }

    SaleConfig public saleConfig;

    mapping(address => bool) public allowlist;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForAuctionAndDev_,
        uint256 amountForDevs_
    ) ERC721A("Banana Goons", "BGOONS", maxBatchSize_, collectionSize_) {
        maxPerAddressDuringMint = maxBatchSize_;
        amountForAuctionAndDev = amountForAuctionAndDev_;
        amountForDevs = amountForDevs_;
        require(amountForAuctionAndDev_ <= collectionSize_, "larger collection size needed");
    }

    function auctionMint(uint256 quantity) external payable {
        uint256 _saleStartTime = uint256(saleConfig.auctionSaleStartTime);
        require(_saleStartTime != 0 && block.timestamp >= _saleStartTime, "sale has not started yet");
        require(
            totalSupply() + quantity <= amountForAuctionAndDev,
            "not enough remaining reserved for auction to support desired mint amount"
        );
        require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
        uint256 totalCost = getAuctionPrice(_saleStartTime) * quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(totalCost);
    }

    function allowlistMint(uint256 quantity) external payable {
        uint256 price = uint256(saleConfig.mintlistPrice);
        require(price != 0, "allowlist sale has not begun yet");
        require(allowlist[msg.sender], "You are not on the Allow list");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
        _safeMint(msg.sender, quantity);
        refundIfOver(price * quantity);
    }

    function publicSaleMint(uint256 quantity) external payable {
        SaleConfig memory config = saleConfig;
        uint256 publicPrice = uint256(config.publicPrice);
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);

        require(isPublicSaleOn(publicPrice, publicSaleStartTime), "public sale has not begun yet");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isPublicSaleOn(uint256 publicPriceWei, uint256 publicSaleStartTime) public view returns (bool) {
        return publicPriceWei != 0 && block.timestamp >= publicSaleStartTime;
    }

    uint256 public constant AUCTION_START_PRICE = 1 ether;
    uint256 public constant AUCTION_END_PRICE = 0.15 ether;
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 340 minutes;
    uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);

    function getAuctionPrice(uint256 _saleStartTime) public view returns (uint256) {
        if (block.timestamp < _saleStartTime) {
            return AUCTION_START_PRICE;
        }
        if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - _saleStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    function endAuctionAndSetupNonAuctionSaleInfo(
        uint64 mintlistPriceWei,
        uint64 publicPriceWei,
        uint32 publicSaleStartTime
    ) external onlyOwner {
        saleConfig = SaleConfig(0, publicSaleStartTime, mintlistPriceWei, publicPriceWei);
    }

    function setAuctionSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.auctionSaleStartTime = timestamp;
    }

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add null address");

            allowlist[addresses[i]] = true;
        }
    }

    // For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= amountForDevs, "too many already minted before dev mint");
        require(quantity % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    function devMintOne() external onlyOwner {
        require(totalSupply() <= amountForDevs, "too many already minted before dev mint one");
        _safeMint(msg.sender, 1);
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
}
