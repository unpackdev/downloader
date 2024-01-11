// SPDX-License-Identifier: MIT

/**
 *@title Avvenire ERC721 Contract
 */
pragma solidity ^0.8.4;

import "AvvenireCitizensInterface.sol";
import "Ownable.sol";
import "Strings.sol";
import "ReentrancyGuard.sol";

contract AvvenireAuction is Ownable, ReentrancyGuard {
    // mint information
    uint256 public maxPerAddressDuringWhiteList;

    uint256 public amountForTeam; // Amount of NFTs for team
    uint256 public amountForAuctionAndTeam; // Amount of NFTs for the team and auction
    uint256 public collectionSize; // Total collection size

    // AvvenireCitizensERC721 contract
    AvvenireCitizensInterface avvenireCitizens;

    struct SaleConfig {
        uint32 auctionSaleStartTime; 
        uint32 publicSaleStartTime; 
        uint64 mintlistPrice; 
        uint64 publicPrice; 
        uint32 publicSaleKey; 
    }

    SaleConfig public saleConfig; 

    // whitelist mapping (address => amount they can mint)
    mapping(address => uint256) public allowlist;

    // Mappings used to calculate the amount to refund a user from the dutch auctin
    mapping(address => uint256) public totalPaidDuringAuction;
    mapping(address => uint256) public numberMintedDuringAuction;

    /**
     * @notice Constructor calls on ERC721A constructor and sets the previously defined global variables
     * @param maxPerAddressDuringWhiteList_ the number for the max batch size and max # of NFTs per address during the whiteList
     * @param collectionSize_ the number of NFTs in the collection
     * @param amountForTeam_ the number of NFTs for the team
     * @param amountForAuctionAndTeam_ specifies total amount to auction + the total amount for the team
     * @param avvenireCitizensContractAddress_ address for AvvenireCitizensERC721 contract 
     */
    constructor(
        uint256 maxPerAddressDuringWhiteList_,
        uint256 collectionSize_,
        uint256 amountForAuctionAndTeam_,
        uint256 amountForTeam_,
        address avvenireCitizensContractAddress_
    ) {
        maxPerAddressDuringWhiteList = maxPerAddressDuringWhiteList_;

        amountForAuctionAndTeam = amountForAuctionAndTeam_;
        amountForTeam = amountForTeam_;
        collectionSize = collectionSize_;

        // set avvenire citizens address
        avvenireCitizens = AvvenireCitizensInterface(
            avvenireCitizensContractAddress_
        );

        require(
            amountForAuctionAndTeam_ <= collectionSize_, 
            "larger collection size needed"
        );
    }

    /**
      Modifier to make sure that the caller is a user and not another contract
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract."); 
        _;
    }

    /**
     * @notice function used to mint during the auction
     * @param quantity is the quantity to mint
     */
    function auctionMint(uint256 quantity) external payable callerIsUser {
        uint256 _saleStartTime = uint256(saleConfig.auctionSaleStartTime);

        // Require that the current time is past the designated start time 
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "sale has not started yet"
        );

        // Require that quantity does not exceed designated amount 
        require(
            avvenireCitizens.getTotalSupply() + quantity <=
                amountForAuctionAndTeam,
            "not enough remaining reserved for auction to support desired mint amount"
        );

        uint256 totalCost = getAuctionPrice() * quantity; // total amount of ETH needed for the transaction
        avvenireCitizens.safeMint(msg.sender, quantity); 

        //Add to numberMinted mapping 
        numberMintedDuringAuction[msg.sender] =
            numberMintedDuringAuction[msg.sender] +
            quantity;

        //Add to totalPaid mapping
        totalPaidDuringAuction[msg.sender] =
            totalPaidDuringAuction[msg.sender] +
            totalCost;

        refundIfOver(totalCost); // make sure to refund the excess

    }

    /**
     * @notice function to mint for allow list
     * @param quantity amount to mint for whitelisted users
     */
    function whiteListMint(uint256 quantity) external payable callerIsUser {
        // Sets the price var to the mintlistPrice, which was set by endAuctionAndSetupNonAuctionSaleInfo(...)
        // mintlistPrice will be set to 30% below the publicSalePrice
        uint256 price = uint256(saleConfig.mintlistPrice);

        require(price != 0, "Allowlist sale has not begun yet");

        require(allowlist[msg.sender] > 0, "not eligible for allowlist mint"); 

        require(
            avvenireCitizens.getTotalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(quantity <= allowlist[msg.sender], "Can not mint this many");

        allowlist[msg.sender] = allowlist[msg.sender] - quantity;

        avvenireCitizens.safeMint(msg.sender, quantity);

        uint256 totalCost = quantity * price;

        refundIfOver(totalCost);
    }

    /**
     * @notice mint function for the public sale
     * @param quantity quantity to mint
     * @param callerPublicSaleKey the key for the public sale
     */
    function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey)
        external
        payable
        callerIsUser
    {
        SaleConfig memory config = saleConfig; 

        uint256 publicSaleKey = uint256(config.publicSaleKey); // log the key
        uint256 publicPrice = uint256(config.publicPrice); // get the price 
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime); 

        require(
            publicSaleKey == callerPublicSaleKey,
            "called with incorrect public sale key"
        );

        require(
            isPublicSaleOn(publicPrice, publicSaleKey, publicSaleStartTime),
            "public sale has not begun yet"
        );
        require(
            avvenireCitizens.getTotalSupply() + quantity <= collectionSize,
            "reached max supply"
        );

        avvenireCitizens.safeMint(msg.sender, quantity);

        uint256 totalCost = publicPrice * quantity;
        refundIfOver(totalCost);
    }

    /**
     * @notice private function that refunds a user if msg.value > totalCost
     * @param price current price
     */
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH"); 

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
     * @notice function that user can call to be refunded
     */
    function refundMe() external callerIsUser nonReentrant {
        uint256 endingPrice = saleConfig.publicPrice;
        require(endingPrice > 0, "public price not set yet");

        uint256 actualCost = endingPrice *
            numberMintedDuringAuction[msg.sender];

        int256 reimbursement = int256(totalPaidDuringAuction[msg.sender]) -
            int256(actualCost);

        require(reimbursement > 0, "You are not eligible for a refund");

        totalPaidDuringAuction[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: uint256(reimbursement)}("");
        require(success, "Refund failed");
    }

    /**
     * @notice function to refund user on the price they paid
     * @param toRefund the address to refund
     */
    function refund(address toRefund) external onlyOwner nonReentrant {
        uint256 endingPrice = saleConfig.publicPrice;
        require(endingPrice > 0, "public price not set yet");

        uint256 actualCost = endingPrice * numberMintedDuringAuction[toRefund];

        int256 reimbursement = int256(totalPaidDuringAuction[toRefund]) -
            int256(actualCost);
        require(reimbursement > 0, "Not eligible for a refund");

        totalPaidDuringAuction[toRefund] = 0;

        (bool success, ) = toRefund.call{value: uint256(reimbursement)}("");
        require(success, "Refund failed");
    }

    /**
     * @notice function that returns a boolean indicating whtether the public sale is enabled
     * @param publicPriceWei must sell for more than 0
     * @param publicSaleKey must have a key that is non-zero
     * @param publicSaleStartTime  must be past the public start time
     */
    function isPublicSaleOn(
        // check if the public sale is on
        uint256 publicPriceWei,
        uint256 publicSaleKey,
        uint256 publicSaleStartTime
    ) public view returns (bool) {
        return
            publicPriceWei != 0 && 
            publicSaleKey != 0 && 
            block.timestamp >= publicSaleStartTime; 
    }

    uint256 public constant AUCTION_START_PRICE = .3 ether; // start price
    uint256 public constant AUCTION_END_PRICE = 0.1 ether; // floor price
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 80 minutes; // total time of the auction
    uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;

    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) /
            (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL); // how much the auction price will drop the price per unit of time

    /**
     * @notice Returns the current auction price. Uses block.timestamp to properly calculate price
     */
    function getAuctionPrice() public view returns (uint256) {
        uint256 _saleStartTime = uint256(saleConfig.auctionSaleStartTime);
        require(_saleStartTime != 0, "auction has not started");
        if (block.timestamp < _saleStartTime) {
            return AUCTION_START_PRICE; // if the timestamp is less than the start of the sale, no discount
        }
        if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
            return AUCTION_END_PRICE; // lower limit of the auction
        } else {
            uint256 steps = (block.timestamp - _saleStartTime) /
                AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP); // calculate the price based on how far away from the start we are
        }
    }

    /**
     * @notice function to set up the saleConfig variable; sets auctionSaleStartTime to 0
     * @param mintlistPriceWei the mintlist price in wei
     * @param publicPriceWei the public sale price in wei
     * @param publicSaleStartTime the start time of the sale
     */
    function endAuctionAndSetupNonAuctionSaleInfo(
        uint64 mintlistPriceWei,
        uint64 publicPriceWei,
        uint32 publicSaleStartTime
    ) external onlyOwner {
        saleConfig = SaleConfig(
            0,
            publicSaleStartTime,
            mintlistPriceWei,
            publicPriceWei,
            saleConfig.publicSaleKey
        );
    }

    /**
     * @notice Sets the auction's starting time
     * @param timestamp the starting time
     */
    function setAuctionSaleStartTime(uint32 timestamp) external onlyOwner {
        // set the start time
        saleConfig.auctionSaleStartTime = timestamp;
    }

    /**
     * @notice sets the public sale key
     */
    function setPublicSaleKey(uint32 key) external onlyOwner {
        // set the special key (not viewable to the public)
        saleConfig.publicSaleKey = key;
    }

    /**
     * @notice sets the whitelist w/ the respective amount of number of NFTs that each address can mint
     * Requires that the addresses[] and numSlots[] are the same length
     * @param addresses the whitelist addresses
     */
    function seedWhitelist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = maxPerAddressDuringWhiteList;
        }
    }

    /**
     * @notice Removes a user from the whitelist
     * @param toRemove the public address of the user
     */
    function removeFromWhitelist(address toRemove) external onlyOwner {
        require(allowlist[toRemove] > 0, "allowlist at 0 already");
        allowlist[toRemove] = 0;
    }

    /**
     * @notice function to mint for the team
     */
    function teamMint(uint256 quantity) external onlyOwner {
        require(avvenireCitizens.getTotalSupply() + quantity <= amountForTeam, "NFTs already minted");
        avvenireCitizens.safeMint(msg.sender, quantity);  
    }

    /**
     * @notice function to withdraw the money from the contract. Only callable by the owner
     */
    function withdrawQuantity(uint256 toWithdraw) external onlyOwner nonReentrant {
        require (toWithdraw <= address(this).balance, "quantity to withdraw > balance");

        (bool success, ) = msg.sender.call{value: toWithdraw}("");
        require(success, "withdraw failed.");
    }

    /**
     * @notice function to withdraw the money from the contract. Only callable by the owner
     */
    function withdrawAll() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "withdraw failed.");
    }

}
