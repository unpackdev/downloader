// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./SignUtil.sol";

/**
 * Auction interface
 * NOTE: The auction contract is used to bid through virtual currency to ensure fairness and fairness in the auction.
 */
interface BaseAuction {
    //publish auction. msg.value is a reserve price and deposit.
    function publish(
        address guarantee,
        bytes calldata signHex,
        uint256 endTime,
        uint256 startPrice,
        uint256 range,
        uint256 feeRate
    ) external returns (uint256 id);

    //bidding
    function bidding(uint256 id) external payable;

    //auction end
    function endAuction(uint256 id) external returns (address winner, uint256 price);

    //loser refund
    function refund(uint256 id) external;

    //withdraw deposit. sign must be one of winner or guarantee
    function withdraw(
        uint256 id,
        bytes calldata sign1,
        bytes calldata sign2,
        uint256 couponRate,
        bytes memory couponId
    ) external;

    function info(uint256 id, address user)
        external
        view
        returns (
            uint256 sysTime,
            uint256 timestamp,
            uint256 topPrice,
            uint256 myPrice
        );

    event Transfer(address indexed from, address indexed to, uint256 value);
    event VivReturnId(uint256 id);
}

/**
 * Auction implements
 */
contract VivAuction is BaseAuction {
    using SafeMath for uint256;

    struct BidInfo {
        address guarantee;
        address publisher;
        address bidder;
        bytes signKey;
        uint256 price;
        uint256 startPrice;
        uint256 range;
        uint256 timestamp;
        uint256 feeRate;
    }

    //bidId
    uint256 _bidCount;
    //bid address list
    mapping(uint256 => address[]) _losers;
    mapping(uint256 => mapping(address => uint256)) _loserBids;
    //top info
    mapping(uint256 => BidInfo) _curBid;

    mapping(bytes => bool) _couponIds;

    function getLosers(uint256 id) external view returns (address[] memory) {
        return _losers[id];
    }

    //publish auction. msg.value is a reserve price and deposit.
    //When deal finished,  is certificate for withdraw deposit
    function publish(
        address guarantee,
        bytes calldata signHex,
        uint256 endTime,
        uint256 startPrice,
        uint256 range,
        uint256 feeRate
    ) external override returns (uint256 id) {
        require(guarantee != address(0), "VIV0045");
        require(endTime > block.timestamp, "VIV0046");
        require(range > 0, "VIV0047");

        _bidCount += 1;

        //set info
        _curBid[_bidCount].publisher = msg.sender;
        _curBid[_bidCount].guarantee = guarantee;
        _curBid[_bidCount].bidder = msg.sender;
        _curBid[_bidCount].startPrice = startPrice;
        _curBid[_bidCount].range = range;
        _curBid[_bidCount].signKey = signHex;
        _curBid[_bidCount].timestamp = endTime;
        _curBid[_bidCount].feeRate = feeRate;

        emit VivReturnId(_bidCount);

        return _bidCount;
    }

    //bidding
    function bidding(uint256 id) external payable override {
        _bidding(id, block.timestamp);
    }

    function _bidding(uint256 id, uint256 currentTime) internal {
        require(_curBid[id].timestamp > currentTime, "VIV0048");
        uint256 oldPrice = _loserBids[id][msg.sender];
        if (oldPrice == 0) {
            //first bidding
            require(msg.value >= _curBid[id].startPrice, "VIV0050");
            require((msg.value - _curBid[id].startPrice) % _curBid[id].range == 0, "VIV0049");
        } else {
            require(msg.value % _curBid[id].range == 0, "VIV0049");
        }
        uint256 newPrice = oldPrice.add(msg.value);
        require(newPrice > _curBid[id].price, "VIV0051");

        //set top price
        _loserBids[id][msg.sender] = newPrice;
        _curBid[id].bidder = msg.sender;
        _curBid[id].price = newPrice;
        _losers[id].push(msg.sender);
    }

    //auction end
    function endAuction(uint256 id) external override returns (address winner, uint256 price) {
        return _endAuction(id, block.timestamp);
    }

    function _endAuction(uint256 id, uint256 currentTime) internal returns (address winner, uint256 price) {
        require(_curBid[id].timestamp <= currentTime, "VIV0052");

        //send back for loser
        for (uint256 i = 0; i < _losers[id].length; i++) {
            address loser = _losers[id][i];
            uint256 _price = _loserBids[id][loser];
            if (loser == _curBid[id].bidder) {
                //winner, continue
                continue;
            }
            if (_price > 0) {
                payable(loser).transfer(_price);
                delete _loserBids[id][loser];
                emit Transfer(address(this), loser, _price);
            }
        }

        return (_curBid[id].bidder, _curBid[id].price);
    }

    //loser refund
    function refund(uint256 id) external override {
        //not winner anytime can withdraw deposit
        require(msg.sender != _curBid[id].bidder, "VIV0053");

        //withdraw deposit
        uint256 price = _loserBids[id][msg.sender];
        require(price > 0, "VIV0054");

        payable(msg.sender).transfer(price);
        delete _loserBids[id][msg.sender];
        emit Transfer(address(this), msg.sender, price);
    }

    //withdraw deposit. sign must be one of winner or guarantee
    function withdraw(
        uint256 id,
        bytes calldata sign1,
        bytes calldata sign2,
        uint256 couponRate,
        bytes memory couponId
    ) external override {
        _withdraw(id, sign1, sign2, couponRate, couponId, block.timestamp);
    }

    function _withdraw(
        uint256 id,
        bytes calldata sign1,
        bytes calldata sign2,
        uint256 couponRate,
        bytes memory couponId,
        uint256 currentTime
    ) internal {
        BidInfo storage bid = _curBid[id];
        require(_curBid[id].timestamp <= currentTime, "VIV0052");
        require(msg.sender == bid.publisher, "VIV0055");

        //deal end
        bytes32 hashValue = ECDSA.toEthSignedMessageHash(abi.encode(bid.signKey));
        address signAddr = ECDSA.recover(hashValue, sign1);
        require(signAddr == bid.bidder || signAddr == bid.guarantee, "VIV0056");
        //service fee
        uint256 fee = bid.price.rate(bid.feeRate);
        // Calculate the discounted price when couponRate more than 0
        if (couponRate > 0) {
            // Coupon cannot be reused
            require(!_couponIds[couponId], "VIV0006");
            // Check if platform signed
            bytes32 h = ECDSA.toEthSignedMessageHash(abi.encode(couponRate, couponId, bid.signKey));
            require(SignUtil.checkSign(h, sign2, bid.guarantee), "VIV0007");
            // Use a coupon
            fee = fee.sub(fee.rate(couponRate));
            _couponIds[couponId] = true;
        }

        if (fee > 0) {
            if (bid.price < fee) {
                fee = bid.price;
            }
            payable(bid.guarantee).transfer(fee);
            emit Transfer(address(this), bid.guarantee, fee);
        }
        uint256 amount = bid.price.sub(fee);
        if (amount > 0) {
            payable(msg.sender).transfer(amount);
            emit Transfer(address(this), msg.sender, amount);
        }
        delete _curBid[id];
        delete _loserBids[id][msg.sender];
    }

    function info(uint256 id, address user)
        external
        view
        override
        returns (
            uint256 sysTime,
            uint256 endTime,
            uint256 topPrice,
            uint256 myPrice
        )
    {
        return _info(id, user, block.timestamp);
    }

    function _info(
        uint256 id,
        address user,
        uint256 currentTime
    )
        internal
        view
        returns (
            uint256 sysTime,
            uint256 endTime,
            uint256 topPrice,
            uint256 myPrice
        )
    {
        BidInfo storage bid = _curBid[id];
        return (currentTime, bid.timestamp, bid.price, _loserBids[id][user]);
    }
}
