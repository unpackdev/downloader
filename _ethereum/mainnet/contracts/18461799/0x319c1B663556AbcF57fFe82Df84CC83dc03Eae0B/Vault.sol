// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVault.sol";

error BidTooLow(uint256 currentBid, uint256 newBid);
error NotAMarketplace();
error WrongBid();

error TransferFailed();
error RoyaltyTransferFailed();

contract Vault is Ownable, IVault {
    using SafeERC20 for IERC20;

    struct Bid {
        address bidder;
        uint256 price;
    }

    event BidAccepted(
        uint256 indexed listingId,
        address indexed bidder,
        address currency,
        uint256 price,
        uint256 fee
    );
    event BidRefunded(
        uint256 indexed listingId,
        address indexed bidder,
        address currency,
        uint256 price
    );
    event BidUpdated(
        uint256 indexed listingId,
        address indexed bidder,
        address currency,
        uint256 price
    );

    mapping(address => uint256) private feeAccumulator;
    mapping(uint256 => Bid) public bids;
    address public marketplace;

    modifier onlyMarketplace() {
        if (msg.sender != marketplace) revert NotAMarketplace();
        _;
    }

    function isBidExist(uint256 listingId) external view returns (bool) {
        return bids[listingId].price != 0;
    }

    function isBidder(
        address sender,
        uint256 listingId
    ) external view returns (bool) {
        return sender == bids[listingId].bidder;
    }

    function getBidPrice(uint256 listingId) external view returns (uint256) {
        return bids[listingId].price;
    }

    receive() external payable {}

    function updateBid(
        uint256 listingId,
        address bidder,
        address currency,
        uint256 price
    ) external onlyMarketplace {
        if (bidder == address(0) || price == 0) revert WrongBid();
        if (bids[listingId].price >= price)
            revert BidTooLow(bids[listingId].price, price);

        // Update bid before refunding to protect from reentrancy
        Bid memory bid = bids[listingId];
        bids[listingId].bidder = bidder;
        bids[listingId].price = price;

        if (bid.price != 0) {
            if (currency != address(0)) {
                IERC20(currency).safeTransfer(bid.bidder, bid.price);
            } else {
                _transfer(bid.bidder, bid.price);
            }

            emit BidRefunded(listingId, bid.bidder, currency, bid.price);
        }

        emit BidUpdated(listingId, bidder, currency, price);
    }

    function refundBid(
        uint256 listingId,
        address currency
    ) external onlyMarketplace {
        Bid memory bid = bids[listingId];
        delete bids[listingId];

        if (bid.price == 0) revert WrongBid();

        if (currency != address(0)) {
            IERC20(currency).safeTransfer(bid.bidder, bid.price);
        } else {
            _transfer(bid.bidder, bid.price);
        }

        emit BidRefunded(listingId, bid.bidder, currency, bid.price);
    }

    function acceptBid(
        uint256 listingId,
        address receiver,
        address currency,
        uint256 fee,
        address royaltyReceiver,
        uint256 royalty
    ) external onlyMarketplace {
        Bid memory bid = bids[listingId];
        delete bids[listingId];

        if (bid.price == 0) revert WrongBid();
        if (currency != address(0)) {
            if (royaltyReceiver == address(0) || royaltyReceiver == receiver)
                IERC20(currency).safeTransfer(receiver, bid.price - fee);
            else {
                IERC20(currency).safeTransfer(
                    receiver,
                    bid.price - fee - royalty
                );
                IERC20(currency).safeTransfer(royaltyReceiver, royalty);
            }
        } else {
            if (royaltyReceiver == address(0) || royaltyReceiver == receiver) {
                _transfer(receiver, bid.price - fee);
            } else {
                _transfer(receiver, bid.price - fee - royalty);
                _transfer(royaltyReceiver, royalty);
            }
        }

        updateFeeAccumulator(currency, fee);
        emit BidAccepted(listingId, bid.bidder, currency, bid.price, fee);
    }

    function updateFeeAccumulator(
        address currency,
        uint256 fee
    ) public onlyMarketplace {
        feeAccumulator[currency] += fee;
    }

    function getFeeAccumulator(
        address currency
    ) external view onlyOwner returns (uint256) {
        return feeAccumulator[currency];
    }

    function withdrawFeeAccumulator(
        address currency,
        address receiver
    ) external onlyOwner {
        uint256 fee = feeAccumulator[currency];
        delete feeAccumulator[currency];

        if (currency != address(0)) {
            IERC20(currency).safeTransfer(receiver, fee);
        } else {
            _transfer(receiver, fee);
        }
    }

    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    function _transfer(address receiver, uint256 value) internal {
        (bool status, ) = payable(receiver).call{value: value, gas: 10000}("");
        if (!status) revert TransferFailed();
    }
}
