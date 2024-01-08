// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./PullPayment.sol";
import "./Governed.sol";
import "./OwnerBalanceContributor.sol";
import "./Macabris.sol";
import "./Bank.sol";

/**
 * @title Macabris market contract, tracks bids and asking prices
 */
contract Market is Governed, OwnerBalanceContributor, PullPayment {

    // Macabris NFT contract
    Macabris public macabris;

    // Bank contract
    Bank public bank;

    // Mapping from token IDs to asking prices
    mapping(uint256 => uint) private asks;

    // Mapping of bidder addresses to bid amounts indexed by token IDs
    mapping(address => mapping(uint256 => uint)) private bids;

    // Mappings of prev/next bidder address in line for each token ID
    // Next bid is the smaller one, prev bid is the bigger one
    mapping(uint256 => mapping(address => address)) private nextBidders;
    mapping(uint256 => mapping(address => address)) private prevBidders;

    // Mapping of token IDs to the highest bidder address
    mapping(uint256 => address) private highestBidders;

    // Owner and bank fees for market operations in bps
    uint16 public ownerFee;
    uint16 public bankFee;

    /**
     * @dev Emitted when a bid is placed on a token
     * @param tokenId Token ID
     * @param bidder Bidder address
     * @param amount Bid amount in wei
     */
    event Bid(uint256 indexed tokenId, address indexed bidder, uint amount);

    /**
     * @dev Emitted when a bid is canceled
     * @param tokenId Token ID
     * @param bidder Bidder address
     * @param amount Canceled bid amount in wei
     */
    event BidCancellation(uint256 indexed tokenId, address indexed bidder, uint amount);

    /**
     * @dev Emitted when an asking price is set
     * @param tokenId Token ID
     * @param seller Token owner address
     * @param price Price in wei
     */
    event Ask(uint256 indexed tokenId, address indexed seller, uint price);

    /**
     * @dev Emitted when the asking price is reset marking the token as no longer for sale
     * @param tokenId Token ID
     * @param seller Token owner address
     * @param price Canceled asking price in wei
     */
    event AskCancellation(uint256 indexed tokenId, address indexed seller, uint price);

    /**
     * @dev Emitted when a token is sold via `sellForHighestBid` or `buyForAskingPrice` methods
     * @param tokenId Token ID
     * @param seller Seller address
     * @param buyer Buyer addres
     * @param price Price in wei
     */
    event Sale(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint price);

    /**
     * @param governanceAddress Address of the Governance contract
     * @param ownerBalanceAddress Address of the OwnerBalance contract
     *
     * Requirements:
     * - Governance contract must be deployed at the given address
     * - OwnerBalance contract must be deployed at the given address
     */
    constructor(
        address governanceAddress,
        address ownerBalanceAddress
    ) Governed(governanceAddress) OwnerBalanceContributor(ownerBalanceAddress) {}

    /**
     * @dev Sets Macabris NFT contract address
     * @param macabrisAddress Address of Macabris NFT contract
     *
     * Requirements:
     * - the caller must have the boostrap permission
     * - Macabris contract must be deployed at the given address
     */
    function setMacabrisAddress(address macabrisAddress) external canBootstrap(msg.sender) {
        macabris = Macabris(macabrisAddress);
    }

    /**
     * @dev Sets Bank contract address
     * @param bankAddress Address of Macabris NFT contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     * - Bank contract must be deployed at the given address
     */
    function setBankAddress(address bankAddress) external canBootstrap(msg.sender) {
        bank = Bank(bankAddress);
    }

    /**
     * @dev Sets owner's fee on market operations
     * @param _ownerFee Fee in bps
     *
     * Requirements:
     * - The caller must have canConfigure permission
     * - Owner fee should divide 10000 without a remainder
     * - Owner and bank fees should not add up to more than 10000 bps (100%)
     */
    function setOwnerFee(uint16 _ownerFee) external canConfigure(msg.sender) {
        require(_ownerFee + bankFee < 10000, "The sum of owner and bank fees should be less than 10000 bps");

        if (_ownerFee > 0) {
            require(10000 % _ownerFee == 0, "Owner fee amount must divide 10000 without a remainder");
        }

        ownerFee = _ownerFee;
    }

    /**
     * @dev Sets bank's fee on market operations, that goes to the payouts pool
     * @param _bankFee Fee in bps
     *
     * Requirements:
     * - The caller must have canConfigure permission
     * - Bank fee should divide 10000 without a remainder
     * - Owner and bank fees should not add up to more than 10000 bps (100%)
     */
    function setBankFee(uint16 _bankFee) external canConfigure(msg.sender) {
        require(ownerFee + _bankFee < 10000, "The sum of owner and bank fees should be less than 10000 bps");

        if (_bankFee > 0) {
            require(10000 % _bankFee == 0, "Bank fee amount must divide 10000 without a remainder");
        }

        bankFee = _bankFee;
    }

    /**
     * @dev Creates a new bid for a token
     * @param tokenId Token ID
     *
     * Requirements:
     * - `tokenId` must exist
     * - Bid amount (`msg.value`) must be bigger than 0
     * - Bid amount (`msg.value`) must be bigger than the current highest bid
     * - Bid amount (`msg.value`) must be lower than the current asking price
     * - Sender must not be the token owner
     * - Sender must not have an active bid for the token (use `cancelBid` before bidding again)
     *
     * Emits {Bid} event
     */
    function bid(uint256 tokenId) external payable {
        require(msg.value > 0, "Bid amount invalid");
        require(macabris.exists(tokenId), "Token does not exist");
        require(macabris.ownerOf(tokenId) != msg.sender, "Can't bid on owned tokens");
        require(bids[msg.sender][tokenId] == 0, "Bid already exists, cancel it before bidding again");
        (, uint highestBidAmount) = getHighestBid(tokenId);
        require(msg.value > highestBidAmount, "Bid must be larger than the current highest bid");
        uint askingPrice = getAskingPrice(tokenId);
        require(askingPrice == 0 || msg.value < askingPrice, "Bid must be smaller then the asking price");

        bids[msg.sender][tokenId] = msg.value;
        nextBidders[tokenId][msg.sender] = highestBidders[tokenId];
        prevBidders[tokenId][highestBidders[tokenId]] = msg.sender;
        highestBidders[tokenId] = msg.sender;

        emit Bid(tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Cancels sender's currently active bid for the given token and returns the Ether
     * @param tokenId Token ID
     *
     * Requirements:
     * - `tokenId` must exist
     * - Sender must have an active bid for the token
     *
     * Emits {BidCancellation} event
     */
    function cancelBid(uint256 tokenId) public {
        require(macabris.exists(tokenId), "Token does not exist");
        require(bids[msg.sender][tokenId] > 0, "Bid does not exist");

        uint amount = bids[msg.sender][tokenId];
        _removeBid(tokenId, msg.sender);
        _asyncTransfer(msg.sender, amount);

        emit BidCancellation(tokenId, msg.sender, amount);
    }

    /**
     * @dev Removes bid and does required houskeeping to maintain the bid queue
     * @param tokenId Token ID
     * @param bidder Bidder address
     */
    function _removeBid(uint256 tokenId, address bidder) private {
        address prevBidder = prevBidders[tokenId][bidder];
        address nextBidder = nextBidders[tokenId][bidder];

        // If this bid was the highest one, the next one will become the highest
        if (prevBidder == address(0)) {
            highestBidders[tokenId] = nextBidder;
        }

        // If there are bigger bids than this, remove the link to this one as the next bid
        if (prevBidder != address(0)) {
            nextBidders[tokenId][prevBidder] = nextBidder;
        }

        // If there are smaller bids than this, remove the link to this one as the prev bid
        if (nextBidder != address(0)) {
            prevBidders[tokenId][nextBidder] = prevBidder;
        }

        delete bids[bidder][tokenId];
    }

    /**
     * @dev Sets the asking price for the token (enabling instant buy ability)
     * @param tokenId Token ID
     * @param amount Asking price in wei
     *
     * Requirements:
     * - `tokenId` must exist
     * - Sender must be the owner of the token
     * - `amount` must be bigger than 0
     * - `amount` must be bigger than the highest bid
     *
     * Emits {Ask} event
     */
    function ask(uint256 tokenId, uint amount) external {
        // Also checks if the token exists
        require(macabris.ownerOf(tokenId) == msg.sender, "Token does not belong to the sender");
        require(amount > 0, "Ask amount invalid");
        (, uint highestBidAmount) = getHighestBid(tokenId);
        require(amount > highestBidAmount, "Ask amount must be larger than the highest bid");

        asks[tokenId] = amount;

        emit Ask(tokenId, msg.sender, amount);
    }

    /**
     * @dev Removes asking price for the token (disabling instant buy ability)
     * @param tokenId Token ID
     *
     * Requirements:
     * - `tokenId` must exist
     * - Sender must be the owner of the token
     *
     * Emits {AskCancellation} event
     */
    function cancelAsk(uint256 tokenId) external {
        // Also checks if the token exists
        require(macabris.ownerOf(tokenId) == msg.sender, "Token does not belong to the sender");

        uint askingPrice = asks[tokenId];
        delete asks[tokenId];

        emit AskCancellation(tokenId, msg.sender, askingPrice);
    }

    /**
     * @dev Sells token to the highest bidder
     * @param tokenId Token ID
     * @param amount Expected highest bid amount, fails if the actual bid amount does not match it
     *
     * Requirements:
     * - `tokenId` must exist
     * - Sender must be the owner of the token
     * - There must be at least a single bid for the token
     *
     * Emits {Sale} event
     */
    function sellForHighestBid(uint256 tokenId, uint amount) external {
        // Also checks if the token exists
        require(macabris.ownerOf(tokenId) == msg.sender, "Token does not belong to the sender");
        (address highestBidAddress, uint highestBidAmount) = getHighestBid(tokenId);
        require(highestBidAmount > 0, "There are no bids for the token");
        require(amount == highestBidAmount, "Highest bid amount does not match given amount value");

        delete asks[tokenId];
        _removeBid(tokenId, highestBidAddress);

        _onSale(tokenId, msg.sender, highestBidAddress, highestBidAmount);
    }

    /**
     * @dev Buys token for the asking price
     * @param tokenId Token ID
     *
     * Requirements:
     * - `tokenId` must exist
     * - Sender must not be the owner of the token
     * - Asking price must be set for the token
     * - `msg.value` must match the asking price
     *
     * Emits {Sale} event
     */
    function buyForAskingPrice(uint256 tokenId) external payable {
        // Implicitly checks if the token exists
        address seller = macabris.ownerOf(tokenId);
        require(msg.sender != seller, "Can't buy owned tokens");
        uint askingPrice = getAskingPrice(tokenId);
        require(askingPrice > 0, "Token is not for sale");
        require(msg.value == askingPrice, "Transaction value does not match the asking price");

        delete asks[tokenId];

        // Cancel any bid to prevent a situation where an owner has a bid on own token
        if (getBidAmount(tokenId, msg.sender) > 0) {
            cancelBid(tokenId);
        }

        _onSale(tokenId, seller, msg.sender, askingPrice);
    }

    /**
     * @dev Notifes Macabris about the sale, transfers money to the seller and emits a Sale event
     * @param tokenId Token ID
     * @param seller Seller address
     * @param buyer Buyer address
     * @param price Sale price
     *
     * Emits {Sale} event
     */
    function _onSale(uint256 tokenId, address seller, address buyer, uint price) private {

        uint ownerFeeAmount = _calculateFeeAmount(price, ownerFee);
        uint bankFeeAmount = _calculateFeeAmount(price, bankFee);
        uint priceAfterFees = price - ownerFeeAmount - bankFeeAmount;

        macabris.onMarketSale(tokenId, seller, buyer);
        bank.deposit{value: bankFeeAmount}();
        _transferToOwnerBalance(ownerFeeAmount);
        _asyncTransfer(seller, priceAfterFees);

        emit Sale(tokenId, seller, buyer, price);
    }

    /**
     * @dev Calculates fee amount based on given price and fee in bps
     * @param price Price base for calculation
     * @param fee Fee in basis points
     * @return Fee amount in wei
     */
    function _calculateFeeAmount(uint price, uint fee) private pure returns (uint) {

        // Fee might be zero, avoiding division by zero
        if (fee == 0) {
            return 0;
        }

        // Only using division to make sure there is no overflow of the return value.
        // This is the reason why fee must divide 10000 without a remainder, otherwise
        // because of integer division fee won't be accurate.
        return price / (10000 / fee);
    }

    /**
     * @dev Returns current asking price for which the token can be bought immediately
     * @param tokenId Token ID
     * @return Amount in wei, 0 if the token is currently not for sale
     */
    function getAskingPrice(uint256 tokenId) public view returns (uint) {
        return asks[tokenId];
    }

    /**
     * @dev Returns the highest bidder address and the bid amount for the given token
     * @param tokenId Token ID
     * @return Highest bidder address, 0 if not bid exists
     * @return Amount in wei, 0 if no bid exists
     */
    function getHighestBid(uint256 tokenId) public view returns (address, uint) {
        address highestBidder = highestBidders[tokenId];
        return (highestBidder, bids[highestBidder][tokenId]);
    }

    /**
     * @dev Returns bid amount for the given token and bidder address
     * @param tokenId Token ID
     * @param bidder Bidder address
     * @return Amount in wei, 0 if no bid exists
     *
     * Requirements:
     * - `tokenId` must exist
     */
    function getBidAmount(uint256 tokenId, address bidder) public view returns (uint) {
        require(macabris.exists(tokenId), "Token does not exist");

        return bids[bidder][tokenId];
    }
}
