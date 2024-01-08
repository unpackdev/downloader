// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IGallery.sol";
import "./PRBMathUD60x18Typed.sol";

contract GalleryAuction {
    using PRBMathUD60x18Typed for PRBMath.UD60x18;

    uint256 MINIMUM_AUCTION_PRICE = (1e15);
    uint256 constant ORIGINAL_SALE_PRICE = (1 ether) / 8;
    CurrentAuction auction;
    uint256[5]  lastSalePrices = [ORIGINAL_SALE_PRICE, ORIGINAL_SALE_PRICE, ORIGINAL_SALE_PRICE, ORIGINAL_SALE_PRICE, ORIGINAL_SALE_PRICE];
    uint256 currentSaleIndex = 0;
    address galleryAddress;
    address owner;
    bool finished;

    constructor(address newgalleryAddress, address newOwner)  {
        owner = newOwner;
        galleryAddress = newgalleryAddress;
        finished = false;
    }

    struct CurrentAuction {
        uint256 tokenid;
        uint256 auctionStartTime;
        uint256 startPrice;
    }



    function updateMinimumAuctionPrice(uint256 newPrice)
    external
    {
        require(msg.sender == owner);
        MINIMUM_AUCTION_PRICE = newPrice;
    }

    function withdraw()
    external {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }

    function getCurrentAuctionDetails() external view returns (uint256, uint256){
        return (auction.tokenid, getCurrentAuctionPrice());
    }

    function kickOff() external {
        require(auction.tokenid == 0);
        startAuction();
    }

    function startAuction() private {
        require(!finished);

        IGallery gallery = IGallery(galleryAddress);

        auction.tokenid = gallery.mintNFT(address(this));
        uint256 totalPrices = lastSalePrices[0];
        for (uint256 i = 1; i < 5; i++) {
            totalPrices += lastSalePrices[i];
        }
        auction.startPrice = PRBMath.mulDiv(totalPrices, 3, 10);
        auction.auctionStartTime = block.timestamp;
    }


    function buyAuction(uint256 tokenId) payable external {
        require(!finished && tokenId == auction.tokenid && auction.auctionStartTime <= block.timestamp && auction.startPrice > 0);

        uint256 currentPrice = getCurrentAuctionPrice();
        require(msg.value >= currentPrice);
        IGallery gallery = IGallery(galleryAddress);
        uint256 currentAuctionToken = auction.tokenid;

        lastSalePrices[currentSaleIndex] = currentPrice;
        currentSaleIndex = (currentSaleIndex + 1) % 5;
        finished = gallery.totalSupply() >= 10000;

        if (!finished)
            startAuction();

        gallery.safeTransferFrom(address(this), msg.sender, currentAuctionToken);

    }

    function getCurrentAuctionPrice() public view returns (uint256)
    {
        require(!finished && auction.auctionStartTime <= block.timestamp && auction.startPrice > 0);



        //Time in seconds
        uint256 timeDiff = block.timestamp - auction.auctionStartTime;

        //Time in mins
        uint256 timeDiffInCounts = timeDiff / (60 minutes);
        if (timeDiffInCounts == 0) {
            return auction.startPrice;
        }
        //Amount of price reductions
        PRBMath.UD60x18 memory fixedPrice = PRBMath.UD60x18({value : auction.startPrice * 1e18});
        PRBMath.UD60x18 memory decrease = PRBMath.UD60x18({value : 98 * 1e16});
        decrease = decrease.powu(timeDiffInCounts);

        uint256 price = decrease.mul(fixedPrice).value / 1e18;

        if (price < MINIMUM_AUCTION_PRICE)
        {
            price = MINIMUM_AUCTION_PRICE;
        }

        return price;
    }
    function getFinished() external view returns (bool) {
        return finished;
    }
}
