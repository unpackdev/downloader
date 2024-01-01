// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
// import "./console.sol";

import "./Ownable.sol";
import "./IAuctionFactory.sol";

contract Auction is Ownable {
    address payable public seller;
    uint256 public auctionEndTime;
    uint256 public startingPrice;
    uint256 public deadline;

    address public highestBidder;
    uint256 public highestBid;
    uint256 public bidCount;

    bool public confirmed = false;
    bool public ended = false;
    bool public frozen = false;

    IAuctionFactory public auctionFactory;

    uint256 public sellerTax;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(
        uint256 _duration,
        uint256 _startingPrice,
        address _seller,
        address admin
    ) Ownable(admin) {
        auctionFactory = IAuctionFactory(msg.sender);

        auctionEndTime = block.timestamp + _duration;
        startingPrice = _startingPrice;
        deadline = auctionEndTime + auctionFactory.auctionDeadlineDelay();
        seller = payable(_seller);
    }

    modifier onlyHighestBidder() {
        require(
            msg.sender == highestBidder || msg.sender == owner(),
            "Only the highest bidder can call this function."
        );
        _;
    }

    /**
     * @dev Allows users to bid on the auction.
     */
    function bid() public payable {
        require(block.timestamp <= auctionEndTime, "Auction already ended.");
        require(
            msg.sender != seller,
            "Seller cannot bid on their own auction."
        );

        if (msg.sender == highestBidder) {
            highestBid += msg.value;
        } else {
            require(
                msg.value >= startingPrice,
                "Bid must be greater or equal than starting price."
            );
            require(msg.value > highestBid, "There already is a higher bid.");

            bool tmpSuccess;
            (tmpSuccess, ) = highestBidder.call{value: highestBid, gas: 30000}(
                ""
            );
            require(tmpSuccess, "Transfer failed.");
            highestBidder = msg.sender;
            highestBid = msg.value;
            bidCount++;
        }

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /**
     * @dev Allows auction's winner to confirm the transaction.
     */
    function bidderConfirms() public onlyHighestBidder {
        require(
            block.timestamp >= auctionEndTime,
            "Auction has not ended yet."
        );
        require(!confirmed, "Highest bidder has already confirmed.");

        confirmed = true;

        _auctionEnd(seller);
    }

    /**
     * @dev Allows either the seller or the highest bidder to end the auction, depending on the situation.
     */
    function auctionEnd() public {
        _auctionEnd(msg.sender);
    }

    function _auctionEnd(address sender) internal {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!frozen, "Auction is frozen.");
        require(!ended, "Auction has already ended.");

        // If the auction has ended, highest bidder has not confirmed
        if (!confirmed) {
            require(
                block.timestamp > block.timestamp + deadline,
                "Deadline not yet reached."
            );
            require(
                sender == highestBidder,
                "Only the highest bidder can end the auction."
            );

            bool tmpSuccess;
            (tmpSuccess, ) = highestBidder.call{
                value: highestBid,
                gas: 30000
            }("");
            require(tmpSuccess, "Transfer failed.");
        }
        // If the auction has ended, the highest bidder has paid and confirmed
        else if (confirmed) {
            require(sender == seller, "Only the seller can end the auction.");

            sellerTax = auctionFactory.auctionSellerTax();
            uint256 sellerPayment = highestBid -
                ((highestBid * sellerTax) / 100);
            uint256 toTreasury = address(this).balance - sellerPayment;

            bool tmpSuccess;
            (tmpSuccess, ) = seller.call{value: sellerPayment, gas: 30000}("");
            require(tmpSuccess, "Transfer failed.");

            _toTreasury(toTreasury);
        }

        ended = true;

        emit AuctionEnded(highestBidder, highestBid);
    }

    /**
     * @dev Allows the owner to freeze the auction.
     */
    function freeze(bool a) public onlyOwner {
        frozen = a;
    }

    /**
     * @dev Allows the owner to withdraw the funds from the contract.
     * @param recipient The address to send the funds to.
     * @notice This function is only callable by the owner, IT SHOULD NOT BE USED OTHERWISE.
     */
    function emergencyWithdraw(address recipient) public onlyOwner {
        _emergencyWithdraw(recipient);
    }

    function _emergencyWithdraw(address recipient) internal {
        bool tmpSuccess;
        (tmpSuccess, ) = recipient.call{
            value: address(this).balance,
            gas: 30000
        }("");
        require(tmpSuccess, "Transfer failed.");
    }

    function _toTreasury(uint256 amount) internal {
        bool tmpSuccess;
        (tmpSuccess, ) = auctionFactory.treasury().call{
            value: amount,
            gas: 30000
        }("");
        require(tmpSuccess, "Transfer failed.");
    }
}
