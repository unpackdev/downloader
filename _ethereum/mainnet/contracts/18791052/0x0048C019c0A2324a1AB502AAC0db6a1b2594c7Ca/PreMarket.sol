//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSA.sol";
import "./IERC20Metadata.sol";

struct Token {
    address token;
    uint256 settleTime;
    uint256 settleDuration;
    uint256 pledgeRate;
    uint256 status; // Active / Resolving / Ended
}

struct Offer {
    uint8 offerType;
    bytes32 tokenId;
    uint256 totalAmount;
    uint256 price;
    address exToken;
    uint256 collateral;
    uint256 status;
    uint256 filledAmount;
    address offerBy;
    bool fullMatch;
}

struct Order {
    uint256 offerId;
    uint256 amount;
    address seller;
    address buyer;
    uint256 status;
}

contract PreMarket is
    Initializable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint256 constant WEI6 = 10 ** 6;
    uint8 constant OFFER_BUY = 1;
    uint8 constant OFFER_SELL = 2;

    // Status
    uint256 constant STATUS_OPEN = 1;
    uint256 constant STATUS_CLOSED = 2;
    uint256 constant STATUS_CANCELLED = 3;
    uint256 constant STATUS_ACTIVE = 4;
    uint256 constant STATUS_SETTLE = 5;
    uint256 constant STATUS_ENDED = 6;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct PreMarketStorage {
        mapping(address => bool) acceptedTokens;
        mapping(bytes32 => Token) tokens;
        mapping(uint256 => Offer) offers;
        uint256 lastOfferId;
        mapping(uint256 => Order) orders;
        uint256 lastOrderId;
        uint256 feeRefund;
        uint256 feeSettle;
        address feeWallet;
    }

    // keccak256(abi.encode(uint256(keccak256("loot.storage.PreMarket")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PreMarketStorageLocation =
        0xe0eb0c6bc05973c9317c77fe5b658559f9e21630d35f19f70b8603a4f231f900;

    function _getOwnStorage()
        private
        pure
        returns (PreMarketStorage storage $)
    {
        assembly {
            $.slot := PreMarketStorageLocation
        }
    }

    // event
    event NewOffer(
        uint256 id,
        uint8 offerType,
        bytes32 tokenId,
        uint256 amount,
        uint256 price,
        address exToken,
        uint256 value,
        uint256 collateral,
        address offerBy,
        bool fullMatch
    );
    event NewToken(bytes32 tokenId, uint256 settleDuration, uint256 pledgeRate);
    event NewOrder(
        uint256 id,
        uint256 offerId,
        uint256 amount,
        address seller,
        address buyer
    );

    event SettleOrder(uint256 orderId, uint256 collateral, uint256 value);
    event CancelOrder(uint256 orderId, uint256 collateral, uint256 value);
    event UpdateAcceptedTokens(address[] tokens, bool isAccepted);

    event CloseOffer(uint256 offerId, uint256 refundAmount);

    event UpdateTokenAddress(bytes32 tokenId, address tokenAddress);
    event UpdateTokenSettleTime(bytes32 tokenId, uint256 settleTime);
    event UpdateTokenStatus(bytes32 tokenId, uint256 status);

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __AccessControl_init_unchained();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // init value
        PreMarketStorage storage $ = _getOwnStorage();
        $.feeWallet = owner();
        $.feeSettle = WEI6 / 40; // 2.5%
        $.feeRefund = WEI6 / 200; // 0.5%
    }

    ///////////////////////////
    ////// SYSTEM ACTION //////
    ///////////////////////////

    /////////////////////////
    ////// USER ACTION //////
    /////////////////////////

    // make a buy request
    function offerBuy(
        bytes32 tokenId,
        uint256 amount,
        uint256 price,
        address exToken,
        bool fullMatch
    ) external nonReentrant {
        PreMarketStorage storage $ = _getOwnStorage();
        Token storage token = $.tokens[tokenId];
        require(token.status == STATUS_ACTIVE, "Invalid Token");
        require($.acceptedTokens[exToken], "Invalid Offer Token");
        require(price > 0, "Invalid Price");
        IERC20Metadata iexToken = IERC20Metadata(exToken);
        // collateral
        uint256 collateral = (amount * price * token.pledgeRate) / WEI6 / WEI6;
        uint256 value = (amount * price) / WEI6;
        iexToken.transferFrom(msg.sender, address(this), value);

        // create new offer
        _newOffer(
            OFFER_BUY,
            tokenId,
            amount,
            price,
            exToken,
            collateral,
            value,
            fullMatch
        );
    }

    // amount - use standard 6 decimals
    function offerBuyETH(
        bytes32 tokenId,
        uint256 amount,
        uint256 price,
        bool fullMatch
    ) external payable nonReentrant {
        PreMarketStorage storage $ = _getOwnStorage();
        Token storage token = $.tokens[tokenId];
        require(token.status == STATUS_ACTIVE, "Invalid Token");
        require(price > 0, "Invalid Price");
        // collateral
        uint256 collateral = (amount * price * token.pledgeRate) / WEI6 / WEI6;
        uint256 value = (amount * price) / WEI6;
        require(value <= msg.value, "Insufficient Funds");
        // create new offer
        _newOffer(
            OFFER_BUY,
            tokenId,
            amount,
            price,
            address(0),
            collateral,
            value,
            fullMatch
        );
    }

    // make a sell request
    function offerSell(
        bytes32 tokenId,
        uint256 amount,
        uint256 price,
        address exToken,
        bool fullMatch
    ) external nonReentrant {
        PreMarketStorage storage $ = _getOwnStorage();
        Token storage token = $.tokens[tokenId];
        require(token.status == STATUS_ACTIVE, "Invalid Token");
        require($.acceptedTokens[exToken], "Invalid Offer Token");
        require(price > 0, "Invalid Price");
        // collateral
        uint256 collateral = (amount * price * token.pledgeRate) / WEI6 / WEI6;
        uint256 value = (amount * price) / WEI6;

        IERC20Metadata iexToken = IERC20Metadata(exToken);
        iexToken.transferFrom(msg.sender, address(this), collateral);

        // create new offer
        _newOffer(
            OFFER_SELL,
            tokenId,
            amount,
            price,
            exToken,
            collateral,
            value,
            fullMatch
        );
    }

    // amount - use standard 6 decimals
    function offerSellETH(
        bytes32 tokenId,
        uint256 amount,
        uint256 price,
        bool fullMatch
    ) external payable nonReentrant {
        PreMarketStorage storage $ = _getOwnStorage();
        Token storage token = $.tokens[tokenId];
        require(price > 0, "Invalid Price");
        require(token.status == STATUS_ACTIVE, "Invalid Token");
        // collateral
        uint256 collateral = (amount * price * token.pledgeRate) / WEI6 / WEI6;
        uint256 value = (amount * price) / WEI6;
        require(collateral <= msg.value, "Insufficient Collateral Fund");

        // create new offer
        _newOffer(
            OFFER_SELL,
            tokenId,
            amount,
            price,
            address(0),
            collateral,
            value,
            fullMatch
        );
    }

    // take a buy request
    function fillOffer(uint256 offerId, uint256 amount) external nonReentrant {
        PreMarketStorage storage $ = _getOwnStorage();
        Offer storage offer = $.offers[offerId];
        Token storage token = $.tokens[offer.tokenId];

        require(offer.status == STATUS_OPEN, "Invalid Offer Status");
        require(token.status == STATUS_ACTIVE, "Invalid token Status");
        require(amount > 0, "Invalid Amount");
        require(
            offer.totalAmount - offer.filledAmount >= amount,
            "Insufficient Allocations"
        );
        require(
            offer.fullMatch == false || offer.totalAmount == amount,
            "FullMatch required"
        );
        require(
            offer.exToken != address(0) && $.acceptedTokens[offer.exToken],
            "Invalid Offer Token"
        );

        IERC20Metadata iexToken = IERC20Metadata(offer.exToken);

        // transfer exchange token to fill order
        uint256 value;
        address buyer;
        address seller;
        if (offer.offerType == OFFER_BUY) {
            value = (offer.collateral * amount) / offer.totalAmount;
            buyer = offer.offerBy;
            seller = msg.sender;
        } else {
            value = (amount * offer.price) / WEI6;
            buyer = msg.sender;
            seller = offer.offerBy;
        }
        iexToken.transferFrom(msg.sender, address(this), value);

        // new order
        _fillOffer(offerId, amount, buyer, seller);
    }

    function fillOfferETH(
        uint256 offerId,
        uint256 amount
    ) external payable nonReentrant {
        PreMarketStorage storage $ = _getOwnStorage();
        Offer storage offer = $.offers[offerId];
        Token storage token = $.tokens[offer.tokenId];

        require(offer.status == STATUS_OPEN, "Invalid Offer Status");
        require(token.status == STATUS_ACTIVE, "Invalid Token Status");
        require(amount > 0, "Invalid Amount");
        require(
            offer.totalAmount - offer.filledAmount >= amount,
            "Insufficient Allocations"
        );
        require(
            offer.fullMatch == false || offer.totalAmount == amount,
            "FullMatch required"
        );
        require(offer.exToken == address(0), "Invalid Offer Token");

        // transfer exchange token to fill order
        uint256 value;
        address buyer;
        address seller;
        if (offer.offerType == OFFER_BUY) {
            value = (offer.collateral * amount) / offer.totalAmount; // fill collateral to sell
            buyer = offer.offerBy;
            seller = msg.sender;
        } else {
            value = (amount * offer.price) / WEI6;
            buyer = msg.sender;
            seller = offer.offerBy;
        }
        require(msg.value >= value, "Insufficient Funds");

        // new order
        _fillOffer(offerId, amount, buyer, seller);
    }

    // close unfullfilled offer - by Offer owner
    function closeUnfullfilledOffer(uint256 offerId) public nonReentrant {
        PreMarketStorage storage $ = _getOwnStorage();
        Offer storage offer = $.offers[offerId];
        require(offer.offerBy == msg.sender, "Offer Owner Only");
        require(offer.status == STATUS_OPEN, "Invalid Offer Status");
        uint256 refundAmount = offer.totalAmount - offer.filledAmount;
        require(refundAmount > 0, "Insufficient Allocations");

        // calculate refund
        uint256 refundValue;
        if (offer.offerType == OFFER_BUY) {
            refundValue = (refundAmount * offer.price) / WEI6;
        } else {
            refundValue = (refundAmount * offer.collateral) / offer.totalAmount;
        }
        uint256 refundFee = (refundValue * $.feeRefund) / WEI6;
        refundValue -= refundFee;
        // refund
        if (offer.exToken == address(0)) {
            // refund ETH
            (bool success1, ) = offer.offerBy.call{value: refundValue}("");
            (bool success2, ) = $.feeWallet.call{value: refundFee}("");
            require(success1 && success2, "Transfer Funds Fail");
        } else {
            IERC20Metadata iexToken = IERC20Metadata(offer.exToken);
            iexToken.transfer(offer.offerBy, refundValue);
            iexToken.transfer($.feeWallet, refundFee);
        }
        offer.status = STATUS_CLOSED;

        emit CloseOffer(offerId, refundAmount);
    }

    // settle order - deliver token to finillize the order
    function settleOrder(uint256 orderId) public nonReentrant {
        PreMarketStorage storage $ = _getOwnStorage();
        Order storage order = $.orders[orderId];
        Offer storage offer = $.offers[order.offerId];
        Token storage token = $.tokens[offer.tokenId];

        // check condition
        require(token.status == STATUS_SETTLE, "Invalid Status");
        require(
            block.timestamp > token.settleTime,
            "Settling Time Not Started"
        );
        require(order.seller == msg.sender, "Seller Only");
        require(order.status == STATUS_OPEN, "Invalid Order Status");

        uint256 collateral = (order.amount * offer.collateral) /
            offer.totalAmount;
        uint256 value = (order.amount * offer.price) / WEI6;

        // transfer token to buyer
        IERC20Metadata iToken = IERC20Metadata(token.token);
        // calculate token amount base on it's decimals
        uint256 tokenAmount = (order.amount * (10 ** iToken.decimals())) / WEI6;
        iToken.transferFrom(order.seller, order.buyer, tokenAmount);

        // transfer liquid to seller
        uint256 settleFee = (value * $.feeSettle) / WEI6;
        uint256 totalValue = value + collateral - settleFee;
        if (offer.exToken == address(0)) {
            // by ETH
            (bool success1, ) = order.seller.call{value: totalValue}("");
            (bool success2, ) = $.feeWallet.call{value: settleFee}("");
            require(success1 && success2, "Transfer Funds Fail");
        } else {
            // by exToken
            IERC20Metadata iexToken = IERC20Metadata(offer.exToken);
            iexToken.transfer(order.seller, totalValue);
            iexToken.transfer($.feeWallet, settleFee);
        }

        order.status = STATUS_CLOSED;

        emit SettleOrder(orderId, collateral, value);
    }

    // cancel unfilled order by token buyer after fullfill time frame
    // token seller lose collateral to token buyer
    function cancelUnfilledOrder(uint256 orderId) public nonReentrant {
        PreMarketStorage storage $ = _getOwnStorage();
        Order storage order = $.orders[orderId];
        Offer storage offer = $.offers[order.offerId];
        Token storage token = $.tokens[offer.tokenId];

        // check condition
        require(
            token.status == STATUS_SETTLE || token.status == STATUS_ENDED,
            "Invalid Status"
        );
        require(
            block.timestamp > token.settleTime + token.settleDuration,
            "Settling Time Not Ended Yet"
        );
        require(order.buyer == msg.sender, "Buyer Only");
        require(order.status == STATUS_OPEN, "Invalid Order Status");

        uint256 collateral = (order.amount * offer.collateral) /
            offer.totalAmount;
        uint256 value = (order.amount * offer.price) / WEI6;

        // transfer liquid to seller
        uint256 settleFee = (collateral * $.feeSettle) / WEI6;
        uint256 totalValue = value + collateral - settleFee;
        if (offer.exToken == address(0)) {
            // by ETH
            (bool success1, ) = order.buyer.call{value: totalValue}("");
            (bool success2, ) = $.feeWallet.call{value: settleFee}("");
            require(success1 && success2, "Transfer Funds Fail");
        } else {
            // by exToken
            IERC20Metadata iexToken = IERC20Metadata(offer.exToken);
            iexToken.transfer(order.buyer, totalValue);
            iexToken.transfer($.feeWallet, settleFee);
        }

        order.status = STATUS_CANCELLED;

        emit CancelOrder(orderId, collateral, value);
    }

    // Batch actions
    function closeUnfullfilledOffers(uint256[] memory offerIds) external {
        for (uint256 i = 0; i < offerIds.length; i++) {
            closeUnfullfilledOffer(offerIds[i]);
        }
    }

    function settleOrders(uint256[] memory orderIds) public {
        for (uint256 i = 0; i < orderIds.length; i++) {
            settleOrder(orderIds[i]);
        }
    }

    function cancelUnfilledOrders(uint256[] memory orderIds) public {
        for (uint256 i = 0; i < orderIds.length; i++) {
            cancelUnfilledOrder(orderIds[i]);
        }
    }

    ///////////////////////////
    ///////// SETTER //////////
    ///////////////////////////

    function setFeeRefund(uint256 feeRefund_) external onlyRole(OPERATOR_ROLE) {
        PreMarketStorage storage $ = _getOwnStorage();
        require(feeRefund_ <= WEI6 / 100, "Cancel Fee <= 10%");
        $.feeRefund = feeRefund_;
    }

    function setFeeSettle(uint256 feeSettle_) external onlyRole(OPERATOR_ROLE) {
        PreMarketStorage storage $ = _getOwnStorage();
        require(feeSettle_ <= WEI6 / 10, "Settle Fee <= 10%");
        $.feeSettle = feeSettle_;
    }

    function setFeeWallet(address feeWallet_) external onlyRole(OPERATOR_ROLE) {
        PreMarketStorage storage $ = _getOwnStorage();
        require(feeWallet_ != address(0), "Invalid Address");
        $.feeWallet = feeWallet_;
    }

    function setAcceptedTokens(
        address[] memory tokenAddresses,
        bool isAccepted
    ) external onlyRole(OPERATOR_ROLE) {
        PreMarketStorage storage $ = _getOwnStorage();

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            $.acceptedTokens[tokenAddresses[i]] = isAccepted;
        }
        emit UpdateAcceptedTokens(tokenAddresses, isAccepted);
    }

    function createToken(
        bytes32 tokenId,
        uint256 settleDuration,
        uint256 pledgeRate
    ) external onlyRole(OPERATOR_ROLE) {
        PreMarketStorage storage $ = _getOwnStorage();
        require(settleDuration >= 24 * 60 * 60, "Minimum 24h for settling");
        Token storage _token = $.tokens[tokenId];

        _token.settleDuration = settleDuration;
        _token.pledgeRate = pledgeRate;
        _token.status = STATUS_ACTIVE;

        emit NewToken(tokenId, settleDuration, pledgeRate);
    }

    function updateTokenAddress(
        bytes32 tokenId,
        address tokenAddress
    ) external onlyRole(OPERATOR_ROLE) {
        PreMarketStorage storage $ = _getOwnStorage();
        Token storage _token = $.tokens[tokenId];
        require(tokenAddress != address(0), "Invalid Token Address");
        require(_token.status == STATUS_ACTIVE, "Invalid Token Status");
        _token.token = tokenAddress;

        emit UpdateTokenAddress(tokenId, tokenAddress);
    }

    function updateTokenStatus(
        bytes32 tokenId,
        uint256 status
    ) external onlyRole(OPERATOR_ROLE) {
        PreMarketStorage storage $ = _getOwnStorage();
        Token storage _token = $.tokens[tokenId];
        require(_token.status != STATUS_ENDED, "Invalid Token Status");

        if (_token.status == STATUS_ACTIVE) {
            if (status == STATUS_SETTLE) {
                require(_token.token != address(0), "Token Address Not Set");
                _token.settleTime = block.timestamp;
            } else {
                require(status == STATUS_CANCELLED, "Invalid Status");
            }
        }

        _token.status = status;

        emit UpdateTokenStatus(tokenId, status);
    }

    ///////////////////////////
    ///////// GETTER //////////
    ///////////////////////////
    function offerAmount(uint256 offerId) external view returns (uint256) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.offers[offerId].totalAmount;
    }

    function offerAmountAvailable(
        uint256 offerId
    ) external view returns (uint256) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.offers[offerId].totalAmount - $.offers[offerId].filledAmount;
    }

    function offerPrice(uint256 offerId) external view returns (uint256) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.offers[offerId].price;
    }

    function offerExToken(uint256 offerId) external view returns (address) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.offers[offerId].exToken;
    }

    function isBuyOffer(uint256 offerId) external view returns (bool) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.offers[offerId].offerType == OFFER_BUY;
    }

    function isSellOffer(uint256 offerId) external view returns (bool) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.offers[offerId].offerType == OFFER_SELL;
    }

    function offerStatus(uint256 offerId) external view returns (uint256) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.offers[offerId].status;
    }

    function tokens(bytes32 tokenId) external view returns (Token memory) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.tokens[tokenId];
    }

    function offers(uint256 id) external view returns (Offer memory) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.offers[id];
    }

    function orders(uint256 id) external view returns (Order memory) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.orders[id];
    }

    function feeSettle() external view returns (uint256) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.feeSettle;
    }

    function feeRefund() external view returns (uint256) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.feeRefund;
    }

    function feeWallet() external view returns (address) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.feeWallet;
    }

    function isAcceptedToken(address token) external view returns (bool) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.acceptedTokens[token];
    }

    function lastOfferId() external view returns (uint256) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.lastOfferId;
    }

    function lastOrderId() external view returns (uint256) {
        PreMarketStorage storage $ = _getOwnStorage();
        return $.lastOrderId;
    }

    ///////////////////////////
    //////// INTERNAL /////////
    ///////////////////////////

    function _newOffer(
        uint8 offerType,
        bytes32 tokenId,
        uint256 amount,
        uint256 price,
        address exToken,
        uint256 collateral,
        uint256 value,
        bool fullMatch
    ) internal {
        PreMarketStorage storage $ = _getOwnStorage();
        // create new offer
        $.offers[++$.lastOfferId] = Offer(
            offerType,
            tokenId,
            amount,
            price,
            exToken,
            collateral,
            STATUS_OPEN,
            0,
            msg.sender,
            fullMatch
        );

        emit NewOffer(
            $.lastOfferId,
            offerType,
            tokenId,
            amount,
            price,
            exToken,
            value,
            collateral,
            msg.sender,
            fullMatch
        );
    }

    function _fillOffer(
        uint256 offerId,
        uint256 amount,
        address buyer,
        address seller
    ) internal {
        PreMarketStorage storage $ = _getOwnStorage();
        Offer storage offer = $.offers[offerId];
        // new order
        $.orders[++$.lastOrderId] = Order(
            offerId,
            amount,
            seller,
            buyer,
            STATUS_OPEN
        );

        // check if offer is fullfilled
        offer.filledAmount += amount;
        if (offer.filledAmount == offer.totalAmount) {
            offer.status = STATUS_CLOSED;
            emit CloseOffer(offerId, 0);
        }

        emit NewOrder($.lastOrderId, offerId, amount, seller, buyer);
    }
}
