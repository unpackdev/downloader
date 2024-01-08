// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./Context.sol";
import "./AddressUpgradeable.sol";
import "./Structs.sol";
import "./IERC755.sol";
import "./Constants.sol";

contract Exchange is Initializable, Context {
    using AddressUpgradeable for address;

    struct TokenByNowDeal {
        uint256 tokenId;
        uint256 price;
        Structs.Policy[] rights;
    }
    struct TokenAuction {
        uint256 id;
        uint256 tokenId;

        uint256 highestBid;
        address highestBidder;

        uint256 initialPrice;
        Structs.Policy[] rights;
        uint256 endTime;
        uint256 maxDuration;
    }

    event TokenRightsListed(
        uint256 tokenId,
        uint256 price,
        Structs.Policy[] rights,
        uint256 timestamp
    );
    event TokenRightsSold(
        uint256 tokenId,
        uint256 price,
        Structs.Policy[] rights,
        address from,
        address to,
        uint256 timestamp
    );
    event TokenAuctionStarted(
        uint256 id,
        uint256 tokenId,
        uint256 initialPrice,
        Structs.Policy[] rights,
        uint256 endTime,
        uint256 timestamp
    );
    event BidPlaced(
        uint256 tokenId,
        uint256 auctionId,
        address bidder,
        uint256 price,
        uint256 timestamp
    );

    IERC755 private _tokenContract;
    address private _owner;
    uint256 private _marketFee;
    address private _marketWallet;

    mapping(uint256 => TokenByNowDeal[]) private _buyNowTokenDeals;

    mapping(uint256 => TokenAuction[]) private _tokenAuctions;

    mapping(uint256 => bool) private _signedTimestamp;

    uint256 private constant _MAX_AUCTION_DURATION = 100 days;
    uint256 private constant _EXTENSION_DURATION = 15 minutes;

    mapping(uint256 => uint256) private _auctionIdByToken;

    function initialize(
        IERC755 tokenContract,
        uint256 marketFee,
        address marketWallet
    ) external initializer {
        require(
            marketWallet != address(0),
            "invalid market address"
        );
        require(
            address(tokenContract) != address(0),
            "invalid token contract"
        );

        _tokenContract = tokenContract;
        _owner = _msgSender();

        _marketFee = marketFee;
        _marketWallet = marketWallet;
    }

    modifier onlyOwner() {
        require(
            _owner == _msgSender(),
            "caller is not the owner"
        );
        _;
    }

    function _requireMessageSigned(
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) private {
        require(
            !_signedTimestamp[timestamp],
            "timestamp already signed"
        );
        require(
            _msgSender() == ecrecover(
            keccak256(abi.encodePacked(
                "\x19\x01",
                Constants._DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    keccak256("BasicOperation(uint256 timestamp)"),
                    timestamp
                ))
            )),
            v,
            r,
            s
        ),
            "invalid sig"
        );

        _signedTimestamp[timestamp] = true;
    }

    function _requireCanSellTokenRights(
        Structs.Policy[] memory sellRights,
        uint256 tokenId,
        address seller
    ) internal view {
        if (_msgSender() != seller) {
            require(
                _tokenContract.isApprovedForAll(seller, _msgSender()) ||
                _tokenContract.getApproved(
                    seller,
                    tokenId
                ) == _msgSender(),
                "not approved nor operator"
            );
        }

        require(
            _tokenContract.rightsOwned(
                seller,
                sellRights,
                tokenId
            ),
            "rights not owned by seller"
        );
    }

    function getTokenBuyNowDeals(
        uint256 tokenId
    ) external view returns (TokenByNowDeal[] memory) {
        return _buyNowTokenDeals[tokenId];
    }

    function _requireTokenIsApprovedForExchange(
        address seller,
        uint256 tokenId
    ) internal view {
        require(
            _tokenContract.getApproved(seller, tokenId) == address(this),
            "exchange is not approved for the token by seller"
        );
    }

    function setBuyNowPrice(
        Structs.Policy[] memory sellRights,
        uint256 tokenId,
        address seller,
        uint256 price,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external {
        _requireMessageSigned(r, s, v, timestamp);
        _requireCanSellTokenRights(sellRights, tokenId, seller);
        require(price > 0, "price <= 0");

        _requireTokenIsApprovedForExchange(seller, tokenId);

        TokenByNowDeal storage deal = _buyNowTokenDeals[tokenId].push();
        deal.tokenId = tokenId;
        deal.price = price;
        for (uint256 i = 0; i < sellRights.length; i++) {
            _requireRightIsNotOnSale(tokenId, sellRights[i]);
            deal.rights.push(sellRights[i]);
        }
        require(
            _buyNowTokenDeals[tokenId][_buyNowTokenDeals[tokenId].length - 1].rights.length > 0,
            "no rights added to the deal"
        );

        emit TokenRightsListed(
            tokenId,
            price,
            sellRights,
            block.timestamp
        );
    }

    function _requireRightIsNotOnSale(
        uint256 tokenId,
        Structs.Policy memory right
    ) internal view {
        for (uint256 i = 0; i < _buyNowTokenDeals[tokenId].length; i++) {
            Structs.Policy[] memory dealRights = _buyNowTokenDeals[tokenId][i].rights;
            for (uint256 j = 0; j < dealRights.length; j++) {
                if (
                    compareStrings(dealRights[j].action, right.action) &&
                    dealRights[j].permission.wallet == right.permission.wallet
                ) {
                    revert("right is already listed for sale");
                }
            }
        }
    }

    function _rightsEqual(
        Structs.Policy[] memory bundle1,
        Structs.Policy[] memory bundle2
    ) internal pure returns (bool) {
        if (bundle1.length != bundle2.length) {
            return false;
        }

        for (uint256 i = 0; i < bundle1.length; i++) {
            bool foundRight = false;
            for (uint256 j = 0; j < bundle2.length; j++) {
                if (
                    compareStrings(bundle1[i].action, bundle2[j].action) &&
                    bundle1[i].permission.wallet == bundle2[j].permission.wallet
                ) {
                    foundRight = true;
                }
            }
            if (!foundRight) {
                return false;
            }
        }
        return true;
    }

    function removeBuyNowPrice(
        uint256 tokenId,
        uint256 price,
        Structs.Policy[] memory sellRights,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external {
        _requireMessageSigned(r, s, v, timestamp);
        _removeBuyNowPrice(
            tokenId,
            price,
            sellRights
        );
    }

    function _removeBuyNowPrice(
        uint256 tokenId,
        uint256 price,
        Structs.Policy[] memory sellRights
    ) private {
        for (uint256 i = 0; i < _buyNowTokenDeals[tokenId].length; i++) {
            if (_buyNowTokenDeals[tokenId][i].price == price) {
                if (_rightsEqual(_buyNowTokenDeals[tokenId][i].rights, sellRights)) {
                    if (i == _buyNowTokenDeals[tokenId].length - 1) {
                        _buyNowTokenDeals[tokenId].pop();
                    } else {
                        for (uint256 j = i; j < _buyNowTokenDeals[tokenId].length - 1; j++) {
                            _buyNowTokenDeals[tokenId][j] = _buyNowTokenDeals[tokenId][j + 1];
                        }
                        _buyNowTokenDeals[tokenId].pop();
                    }
                }
            }
        }
    }

    function _findTokenDealRights(
        uint256 tokenId,
        Structs.Policy[] memory sellRights,
        uint256 price
    ) internal view returns (Structs.Policy[] memory) {
        for (uint256 i = 0; i < _buyNowTokenDeals[tokenId].length; i++) {
            if (_buyNowTokenDeals[tokenId][i].price == price) {
                if (
                    _rightsEqual(
                        _buyNowTokenDeals[tokenId][i].rights,
                        sellRights
                    )
                ) {
                    return _buyNowTokenDeals[tokenId][i].rights;
                }
            }
        }
        Structs.Policy[] memory emptyRights = new Structs.Policy[](0);
        return emptyRights;
    }

    function _calculatePercentage(
        uint256 number,
        uint256 percentage
    ) private pure returns (uint256) {
        // https://ethereum.stackexchange.com/a/55702
        // https://www.investopedia.com/terms/b/basispoint.asp
        return number * percentage / 10000;
    }

    function _findAuctionByRights(
        uint256 tokenId,
        Structs.Policy[] memory sellRights
    ) internal view returns (TokenAuction memory) {
        for (uint256 i = 0; i < _tokenAuctions[tokenId].length; i++) {
            if (
                _rightsEqual(
                    _tokenAuctions[tokenId][i].rights,
                    sellRights
                )
            ) {
                return _tokenAuctions[tokenId][i];
            }
        }
        return TokenAuction(0, 0, 0, address(0), 0, new Structs.Policy[](0), 0, 0);
    }

    function _payMarketFee(
        uint256 price
    ) internal returns (uint256) {
        uint256 marketFee = _calculatePercentage(price, _marketFee);
        AddressUpgradeable.sendValue(
            payable(_marketWallet),
            marketFee
        );

        return price - marketFee;
    }

    function buyNow(
        uint256 tokenId,
        Structs.Policy[] memory sellRights,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external payable {
        _requireMessageSigned(r, s, v, timestamp);
        uint256 price = msg.value;

        Structs.Policy[] memory buyRights = _findTokenDealRights(
            tokenId,
            sellRights,
            price
        );
        require(
            buyRights.length > 0,
            "no deals for this price and rights"
        );

        uint256 priceAfterMarketFee = _payMarketFee(price);
        _tokenContract.payForTransfer{value: priceAfterMarketFee}(
            buyRights[0].permission.wallet,
            _msgSender(),
            tokenId,
            buyRights
        );
        _tokenContract.safeTransferFrom(
            buyRights[0].permission.wallet,
            _msgSender(),
            tokenId,
            buyRights,
            ""
        );

        _removeBuyNowPrice(tokenId, price, buyRights);

        TokenAuction memory auctionWithRights = _findAuctionByRights(
            tokenId,
            buyRights
        );
        if (auctionWithRights.id > 0) {
            _cancelAuction(
                tokenId,
                auctionWithRights.id
            );
        }

        emit TokenRightsSold(
            tokenId,
            price,
            buyRights,
            buyRights[0].permission.wallet,
            _msgSender(),
            block.timestamp
        );
    }

    function _requireRightIsNotOnAuction(
        uint256 tokenId,
        Structs.Policy memory right
    ) internal view {
        for (uint256 i = 0; i < _tokenAuctions[tokenId].length; i++) {
            Structs.Policy[] memory auctionRights = _tokenAuctions[tokenId][i].rights;
            for (uint256 j = 0; j < auctionRights.length; j++) {
                if (
                    compareStrings(auctionRights[j].action, right.action) &&
                    auctionRights[j].permission.wallet == right.permission.wallet
                ) {
                    revert("right is already on another auction");
                }
            }
        }
    }

    function getTokenAuctions(
        uint256 tokenId
    ) external view returns (TokenAuction[] memory)  {
        return _tokenAuctions[tokenId];
    }

    function startAuction(
        Structs.Policy[] memory sellRights,
        uint256 startPrice,
        uint256 auctionEndTime,
        uint256 tokenId,
        address seller,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external {
        _requireMessageSigned(r, s, v, timestamp);
        _requireCanSellTokenRights(sellRights, tokenId, seller);
        require(startPrice > 0, "initial price should be positive");

        _requireTokenIsApprovedForExchange(seller, tokenId);
        require(
            _numDigits(block.timestamp) == _numDigits(auctionEndTime),
            "incorrect timestamp"
        );
        require(block.timestamp < auctionEndTime, "can't start auction in past");

        TokenAuction storage auction = _tokenAuctions[tokenId].push();
        auction.id = ++_auctionIdByToken[tokenId];
        auction.tokenId = tokenId;
        auction.initialPrice = startPrice;
        auction.endTime = auctionEndTime;
        auction.maxDuration = block.timestamp + _MAX_AUCTION_DURATION;
        for (uint256 i = 0; i < sellRights.length; i++) {
            _requireRightIsNotOnAuction(tokenId, sellRights[i]);
            auction.rights.push(sellRights[i]);
        }

        emit TokenAuctionStarted(
            auction.id,
            auction.tokenId,
            startPrice,
            sellRights,
            auctionEndTime,
            block.timestamp
        );
    }

    function _deleteAuction(
        uint256 tokenId,
        uint256 auctionIndex
    ) internal {
        uint256 i = auctionIndex;

        if (i == _tokenAuctions[tokenId].length - 1) {
            _tokenAuctions[tokenId].pop();
        } else {
            for (uint256 j = i; j < _tokenAuctions[tokenId].length - 1; j++) {
                _tokenAuctions[tokenId][j] = _tokenAuctions[tokenId][j + 1];
            }
            _tokenAuctions[tokenId].pop();
        }
    }

    function cancelAuction(
        uint256 tokenId,
        uint256 auctionId,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external {
        _requireMessageSigned(r, s, v, timestamp);
        _cancelAuction(
            tokenId,
            auctionId
        );
    }

    function _cancelAuction(
        uint256 tokenId,
        uint256 auctionId
    ) private {
        for (uint256 i = 0; i < _tokenAuctions[tokenId].length; i++) {
            if (_tokenAuctions[tokenId][i].id == auctionId) {
                TokenAuction memory auction = _tokenAuctions[tokenId][i];
                if (
                    auction.highestBid > 0 &&
                    auction.highestBidder != address(0)
                ) {
                    // withdraw bid
                    AddressUpgradeable.sendValue(
                        payable(auction.highestBidder),
                        auction.highestBid
                    );
                }

                _deleteAuction(tokenId, i);
            }
        }
    }

    function _findTokenDealByRights(
        uint256 tokenId,
        Structs.Policy[] memory sellRights
    ) internal view returns (TokenByNowDeal memory) {
        for (uint256 i = 0; i < _buyNowTokenDeals[tokenId].length; i++) {
            if (
                _rightsEqual(
                    _buyNowTokenDeals[tokenId][i].rights,
                    sellRights
                )
            ) {
                return _buyNowTokenDeals[tokenId][i];
            }
        }
        return TokenByNowDeal(0, 0, new Structs.Policy[](0));
    }

    function bid(
        uint256 tokenId,
        uint256 auctionId,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external payable {
        _requireMessageSigned(r, s, v, timestamp);
        uint256 bidPrice = msg.value;
        require(bidPrice > 0, "bid should be positive");

        bool auctionExists = false;
        for (uint256 i = 0; i < _tokenAuctions[tokenId].length; i++) {
            if (_tokenAuctions[tokenId][i].id == auctionId) {
                TokenAuction memory auction = _tokenAuctions[tokenId][i];

                require(
                    block.timestamp < auction.endTime,
                    "can't bid on closed auction"
                );
                require(
                    bidPrice > auction.highestBid &&
                    bidPrice > auction.initialPrice,
                    "bid should be higher than initial price & highest bid"
                );

                if (auction.highestBid > 0) {
                    // return previous bid
                    AddressUpgradeable.sendValue(
                        payable(auction.highestBidder),
                        auction.highestBid
                    );
                }

                TokenByNowDeal memory dealWithRights = _findTokenDealByRights(
                    tokenId,
                    auction.rights
                );
                if (
                    dealWithRights.price > 0 &&
                    bidPrice >= _calculatePercentage(dealWithRights.price, 50 * 100)
                ) {
                    _removeBuyNowPrice(
                        tokenId,
                        dealWithRights.price,
                        dealWithRights.rights
                    );
                }

                _tokenAuctions[tokenId][i].highestBid = bidPrice;
                _tokenAuctions[tokenId][i].highestBidder = _msgSender();

                if ((auction.endTime - block.timestamp) <= _EXTENSION_DURATION) {
                    if ((auction.endTime + _EXTENSION_DURATION) < auction.maxDuration) {
                        _tokenAuctions[tokenId][i].endTime += _EXTENSION_DURATION;
                    }
                }

                emit BidPlaced(
                    tokenId,
                    auction.id,
                    _msgSender(),
                    bidPrice,
                    block.timestamp
                );

                auctionExists = true;
            }
        }
        require(auctionExists, "no auction to bid");
    }

    function _numDigits(uint256 number) internal pure returns (uint8) {
        uint8 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }

    function endAuction(
        uint256 tokenId,
        uint256 auctionId
    ) external {
        bool auctionExists = false;
        for (uint256 i = 0; i < _tokenAuctions[tokenId].length; i++) {
            if (_tokenAuctions[tokenId][i].id == auctionId) {
                TokenAuction memory auction = _tokenAuctions[tokenId][i];

                require(
                    block.timestamp >= auction.endTime,
                    "auction is not ended"
                );

                if (auction.highestBid > 0) {
                    TokenByNowDeal memory dealWithRights = _findTokenDealByRights(
                        tokenId,
                        auction.rights
                    );
                    if (dealWithRights.rights.length > 0) {
                        _removeBuyNowPrice(
                            tokenId,
                            dealWithRights.price,
                            dealWithRights.rights
                        );
                    }

                    uint256 priceAfterMarketFee = _payMarketFee(auction.highestBid);
                    _tokenContract.payForTransfer{value: priceAfterMarketFee}(
                        auction.rights[0].permission.wallet,
                        auction.highestBidder,
                        tokenId,
                        auction.rights
                    );
                    _tokenContract.safeTransferFrom(
                        auction.rights[0].permission.wallet,
                        auction.highestBidder,
                        tokenId,
                        auction.rights,
                        ""
                    );

                    emit TokenRightsSold(
                        tokenId,
                        auction.highestBid,
                        auction.rights,
                        auction.rights[0].permission.wallet,
                        auction.highestBidder,
                        block.timestamp
                    );
                }

                _deleteAuction(tokenId, i);

                auctionExists = true;
            }
        }
        require(auctionExists, "no auction to end");
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function version() external virtual pure returns (uint256) {
        return 1;
    }
}