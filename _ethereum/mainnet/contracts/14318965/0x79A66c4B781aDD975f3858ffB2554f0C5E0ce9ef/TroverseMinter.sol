// SPDX-License-Identifier: MIT

// ████████╗██████╗  ██████╗ ██╗   ██╗███████╗██████╗ ███████╗███████╗    
// ╚══██╔══╝██╔══██╗██╔═══██╗██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    
//    ██║   ██████╔╝██║   ██║██║   ██║█████╗  ██████╔╝███████╗█████╗      
//    ██║   ██╔══██╗██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      
//    ██║   ██║  ██║╚██████╔╝ ╚████╔╝ ███████╗██║  ██║███████║███████╗    
//    ╚═╝   ╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";


interface INFTContract {
    function Mint(address _to, uint256 _quantity) external payable;
    function numberMinted(address owner) external view returns (uint256);
    function totalSupplyExternal() external view returns (uint256);
}


contract TroverseMinter is Ownable, ReentrancyGuard {

    INFTContract public NFTContract;

    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant TOTAL_PLANETS = 10000;
    uint256 public constant MAX_MINT_PER_ADDRESS = 5;
    uint256 public constant RESERVED_PLANETS = 300;
    uint256 public constant RESERVED_OR_AUCTION_PLANETS = 7300;

    uint256 public constant AUCTION_START_PRICE = 1 ether;
    uint256 public constant AUCTION_END_PRICE = 0.1 ether;
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 180 minutes;
    uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
    uint256 public constant AUCTION_DROP_PER_STEP = 0.1 ether;

    uint256 public auctionSaleStartTime;
    uint256 public publicSaleStartTime;
    uint256 public whitelistPrice;
    uint256 public publicSalePrice;
    uint256 private publicSaleKey;

    mapping(address => uint256) public whitelist;

    uint256 public lastAuctionSalePrice = AUCTION_START_PRICE;
    mapping(address => uint256) public credits;
    mapping(address => uint256) public creditCount;
    EnumerableSet.AddressSet private _creditOwners;
    uint256 private _totalCredits;
    uint256 private _totalCreditCount;

    event CreditRefunded(address indexed owner, uint256 value);
    
    

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor() { }

    /**
    * Sets the NFT contract address
    */
    function setNFTContract(address _NFTContract) external onlyOwner {
        NFTContract = INFTContract(_NFTContract);
    }

    /**
    * Tries to mint NFTs during the Trove Auction Phase (Equalized Dutch Auction)
    * Based on the price of last mint, extra credits should be refunded when the auction is over
    * Any extra funds will be transferred back to the sender's address
    */
    function auctionMint(uint256 quantity) external payable callerIsUser {
        require(auctionSaleStartTime != 0 && block.timestamp >= auctionSaleStartTime, "Sale has not started yet");
        require(totalSupply() + quantity <= RESERVED_OR_AUCTION_PLANETS, "Not enough remaining reserved for auction to support desired mint amount");
        require(numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDRESS, "Can not mint this many");

        lastAuctionSalePrice = getAuctionPrice();
        uint256 totalCost = lastAuctionSalePrice * quantity;

        if (lastAuctionSalePrice > AUCTION_END_PRICE) {
            _creditOwners.add(msg.sender);

            credits[msg.sender] += totalCost;
            creditCount[msg.sender] += quantity;

            _totalCredits += totalCost;
            _totalCreditCount += quantity;
        }

        NFTContract.Mint(msg.sender, quantity);
        refundIfOver(totalCost);
    }
    
    /**
    * Tries to mint NFTs during the whitelist phase
    * Any extra funds will be transferred back to the sender's address
    */
    function whitelistMint(uint256 quantity) external payable callerIsUser {
        require(whitelistPrice != 0, "Whitelist sale has not begun yet");
        require(whitelist[msg.sender] > 0, "Not eligible for whitelist mint");
        require(whitelist[msg.sender] >= quantity, "Can not mint this many");
        require(totalSupply() + quantity <= TOTAL_PLANETS, "Reached max supply");

        whitelist[msg.sender] -= quantity;
        NFTContract.Mint(msg.sender, quantity);
        refundIfOver(whitelistPrice * quantity);
    }

    /**
    * Tries to mint NFTs during the public sale
    * Any extra funds will be transferred back to the sender's address
    */
    function publicSaleMint(uint256 quantity, uint256 key) external payable callerIsUser {
        require(publicSaleKey == key, "Called with incorrect public sale key");

        require(isPublicSaleOn(), "Public sale has not begun yet");
        require(totalSupply() + quantity <= TOTAL_PLANETS, "Reached max supply");
        require(numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDRESS, "Can not mint this many");

        NFTContract.Mint(msg.sender, quantity);
        refundIfOver(publicSalePrice * quantity);
    }

    /**
    * Tries to transfer back the extra funds, if the paying amount is more than the cost
    */
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Insufficient funds");

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
    * Checks if the public sale is active
    */
    function isPublicSaleOn() public view returns (bool) {
        return publicSalePrice != 0 && block.timestamp >= publicSaleStartTime && publicSaleStartTime != 0;
    }

    /**
    * Calculates the auction price 
    */
    function getAuctionPrice() public view returns (uint256) {
        if (block.timestamp < auctionSaleStartTime) {
            return AUCTION_START_PRICE;
        }
        
        if (block.timestamp - auctionSaleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - auctionSaleStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    /**
    * Sets the auction start time
    */
    function setAuctionSaleStartTime(uint256 timestamp) external onlyOwner {
        auctionSaleStartTime = timestamp;
    }

    /**
    * Sets the price for the whitlist phase
    * Whitelist sale will be active if the price is not 0
    */
    function setWhitelistPrice(uint256 price) external onlyOwner {
        whitelistPrice = price;
    }

    /**
    * Sets the price for the public phase
    */
    function setPublicSalePrice(uint256 price) external onlyOwner {
        publicSalePrice = price;
    }

    /**
    * Sets the public phase start time
    */
    function setPublicSaleStartTime(uint256 timestamp) external onlyOwner {
        publicSaleStartTime = timestamp;
    }

    /**
    * Sets the key for accessing the public phase
    */
    function setPublicSaleKey(uint256 key) external onlyOwner {
        publicSaleKey = key;
    }

    /**
    * Adds or updates new whitelisted wallets
    */
    function addWhitelist(address[] memory addresses, uint256 limit) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = limit;
        }
    }

    /**
    * Mints reserved planets, which will be used for promotions, marketing, strategic partnerships, giveaways, airdrops and also for Troverse team allocation
    */
    function reserveMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= RESERVED_PLANETS, "Too many already minted before dev mint");
        NFTContract.Mint(msg.sender, quantity);
    }

    /**
    * Checks if the auction refund price is determined
    */
    function isAuctionPriceFinalized() public view returns(bool) {
        return totalSupply() >= RESERVED_OR_AUCTION_PLANETS || lastAuctionSalePrice == AUCTION_END_PRICE;
    }

    /**
    * Gets the remaining credits to refund after the auction phase
    */
    function getRemainingCredits(address owner) external view returns(uint256) {
        if (credits[owner] > 0) {
            return credits[owner] - lastAuctionSalePrice * creditCount[owner];
        }
        return 0;
    }
    
    /**
    * Gets total remaining credits to refund after the auction phase
    */
    function getTotalRemainingCredits() public view returns(uint256) {
        return _totalCredits - lastAuctionSalePrice * _totalCreditCount;
    }
    
    /**
    * Gets the maximum possible credits to refund after the auction phase
    */
    function getMaxPossibleCredits() public view returns(uint256) {
        if (isAuctionPriceFinalized()) {
            return getTotalRemainingCredits();
        }

        return _totalCredits - AUCTION_END_PRICE * _totalCreditCount;
    }

    /**
    * @notice Refunds the remaining credits after the auction phase
    */
    function refundRemainingCredits() external nonReentrant {
        require(isAuctionPriceFinalized(), "Auction price is not finalized yet!");
        require(_creditOwners.contains(msg.sender), "Not a credit owner!");
        
        uint256 remainingCredits = credits[msg.sender];
        uint256 remainingCreditCount = creditCount[msg.sender];
        uint256 toSendCredits = remainingCredits - lastAuctionSalePrice * remainingCreditCount;

        require(toSendCredits > 0, "No credits to refund!");

        delete credits[msg.sender];
        delete creditCount[msg.sender];

        _creditOwners.remove(msg.sender);

        _totalCredits -= remainingCredits;
        _totalCreditCount -= remainingCreditCount;

        emit CreditRefunded(msg.sender, toSendCredits);

        require(payable(msg.sender).send(toSendCredits));
    }

    /**
    * Refunds the remaining credits for not yet refunded addresses
    */
    function refundAllRemainingCreditsByCount(uint256 count) external onlyOwner {
        require(isAuctionPriceFinalized(), "Auction price is not finalized yet!");
        
        address toSendWallet;
        uint256 toSendCredits;
        uint256 remainingCredits;
        uint256 remainingCreditCount;
        
        uint256 j = 0;
        while (_creditOwners.length() > 0 && j < count) {
            toSendWallet = _creditOwners.at(0);
            
            remainingCredits = credits[toSendWallet];
            remainingCreditCount = creditCount[toSendWallet];
            toSendCredits = remainingCredits - lastAuctionSalePrice * remainingCreditCount;
            
            delete credits[toSendWallet];
            delete creditCount[toSendWallet];
            _creditOwners.remove(toSendWallet);

            if (toSendCredits > 0) {
                require(payable(toSendWallet).send(toSendCredits));
                emit CreditRefunded(toSendWallet, toSendCredits);

                _totalCredits -= toSendCredits;
                _totalCreditCount -= remainingCreditCount;
            }
            j++;
        }
    }
    
    /**
     * Withdraws the collected funds excluding the remaining credits
     */
    function withdrawAll(address to) external onlyOwner {
        uint256 maxPossibleCredits = getMaxPossibleCredits();
        require(address(this).balance > maxPossibleCredits, "No funds to withdraw");

        uint256 toWithdrawFunds = address(this).balance - maxPossibleCredits;
        require(payable(to).send(toWithdrawFunds), "Transfer failed");
    }
    
    /**
     * Gets the total mints by an address
     */
    function numberMinted(address owner) public view returns (uint256) {
        return NFTContract.numberMinted(owner);
    }

    /**
     * Gets the total supply from the NFT contract
     */
    function totalSupply() public view returns (uint256) {
        return NFTContract.totalSupplyExternal();
    }
}
