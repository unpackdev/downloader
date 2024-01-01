// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20MetadataUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./AuctionStorage.sol";
import "./WaterTowerStorage.sol";

import "./EIP2535Initializable.sol";
import "./FullMath.sol";
import "./Constants.sol";

import "./IPriceOracleUpgradeable.sol";
import "./IWaterTowerUpgradeable.sol";

/// @title Auction Market for whitelisted erc20 tokens and erc1155 tranche nft
/// @dev  Auction contract allows users sell allowed tokens, buy or bid the tokens with allowed bid tokens
///     1. owner allow sell tokens and bid token groups, and set auction fee
///     2. seller(auctioner) create auction
///     * seller should have enough balance for sell tokens (sell amount + auction fee)
///     3. buyer buy listed tokens immediately or bid with any price in a range
///     * buyer shuold have enough balance for bid tokens (price * buy amount)
///     4. anyone(buyer, seller, or any) close auction after end time

contract AuctionUpgradeable is
    EIP2535Initializable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using AuctionStorage for AuctionStorage.Layout;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /// @dev errors
    error InsufficientFee();
    error InsufficientReserveAsset();
    error NoListTrancheZ();
    error NoTransferEther();
    error InvalidTrancheAuction();
    error InvalidAuctionAmount();
    error InvalidStartTime();
    error InvalidMinBidAmount();
    error InvalidFixedPrice();
    error InvalidEndPrice();
    error InvalidSellToken();
    error NoClosedAuction();
    error NoAuction();
    error InvalidAuction();
    error InactiveAuction();
    error NoAuctioneer();
    error NoIdleAuction();
    error InvalidPurchaseAmount();
    error InvalidIncrementBidPrice();
    error NoStoreWater();
    // bid and buy
    error LowBid();
    error OverPriceBid();
    error NoCancelBid();
    error ClaimedBid();
    error NoBidder();
    error SmallBidAmount();
    error InvalidBidToken();

    event AuctionCreated(
        AuctionSetting auctionSetting,
        address indexed seller,
        uint256 indexed auctionId
    );

    /// @notice Emitted by auction for buyNow
    /// @param buyer The address call buyNow
    /// @param amountIn Token amount paid by user to buy auctioning token
    /// @param amountOut Auctioning token amount that user received
    /// @param auctionId Id of auction list

    event AuctionBuy(
        address indexed buyer,
        uint256 amountIn,
        uint256 amountOut,
        address purchaseToken,
        uint256 indexed auctionId
    );

    /// @notice Emitted by auction when bidder places a bid
    /// @param bid Bid token struct
    /// @param auctionId The id of auction list
    /// @param bidId The id of bid list

    event AuctionBid(Bid bid, uint indexed auctionId, uint indexed bidId, uint availableBidDepth);

    /// @notice Emitted by auction when bidder or auctioneer closes a auction
    /// @param unSoldAmount Amount of unsold auctioning token
    /// @param auctionId Auction id
    /// @param settledBidCount Settled bid count when closing auction
    event AuctionClosed(uint256 unSoldAmount, uint256 indexed auctionId, uint256 settledBidCount);

    event AuctionUpdate(
        uint indexed auctionId,
        uint minBidAmount,
        uint priceRangeStart,
        uint incrementPrice
    );

    event ClaimBid(uint auctionId, uint bidId, bool isWinner, uint claimAmount);

    uint256 internal constant FEE_DENOMINATOR = 1e6;
    uint256 internal constant BID_GAS_LIMIT = 470000;
    uint256 internal constant CLOSE_GAS_LIMIT = 180000;
    uint256 internal constant D12 = 1e12;
    uint256 internal constant MINBID_FACTOR = 100;
    uint256 internal constant INCREMENTBID_FACTOR = 2;

    function createAuction(
        AuctionSetting memory auctionSetting,
        uint8 periodId
    ) external payable whenNotPaused {
        AuctionStorage.Layout storage auctionStorage = AuctionStorage.layout();
        if (!auctionStorage.supportedSellTokens[auctionSetting.sellToken])
            revert InvalidSellToken();
        if (auctionSetting.bidTokenGroupId >= auctionStorage.countOfTokenGroups)
            revert InvalidBidToken();
        if (
            auctionSetting.minBidAmount < auctionSetting.sellAmount / MINBID_FACTOR ||
            auctionSetting.minBidAmount > auctionSetting.sellAmount
        ) revert InvalidMinBidAmount();
        if (auctionSetting.sellAmount == 0) revert InvalidAuctionAmount();

        if (
            (auctionSetting.auctionType == AuctionType.FixedPrice ||
                auctionSetting.auctionType == AuctionType.TimedAndFixed) &&
            auctionSetting.fixedPrice == 0
        ) revert InvalidFixedPrice();
        uint256 priceForFee;
        if (auctionSetting.auctionType != AuctionType.FixedPrice) {
            if (auctionSetting.priceRangeStart > auctionSetting.priceRangeEnd)
                revert InvalidEndPrice();
            if (
                auctionSetting.incrementBidPrice == 0 ||
                auctionSetting.incrementBidPrice * INCREMENTBID_FACTOR >
                auctionSetting.priceRangeStart
            ) revert InvalidIncrementBidPrice();
            priceForFee = auctionSetting.priceRangeStart;
        } else {
            priceForFee = auctionSetting.fixedPrice;
        }

        if (auctionSetting.startTime == 0) auctionSetting.startTime = uint48(block.timestamp);
        else if (
            auctionSetting.startTime < block.timestamp ||
            auctionSetting.startTime > block.timestamp + 30 days
        ) revert InvalidStartTime();
        auctionSetting.endTime = auctionSetting.startTime + auctionStorage.periods[periodId];
        uint256 auctionId = auctionStorage.currentAuctionId + 1;
        uint256 tokenMultiplier;
        // receive auction asset
        if (auctionSetting.trancheIndex == 0) {
            IERC20Upgradeable(auctionSetting.sellToken).safeTransferFrom(
                msg.sender,
                address(this),
                auctionSetting.sellAmount
            );
            tokenMultiplier = (10 **
                (18 - IERC20MetadataUpgradeable(auctionSetting.sellToken).decimals()));
        } else {
            if (auctionSetting.trancheIndex & 3 == 3) revert NoListTrancheZ();
            if (auctionSetting.sellToken != address(this)) revert InvalidTrancheAuction();
            IERC1155Upgradeable(address(this)).safeTransferFrom(
                msg.sender,
                address(this),
                auctionSetting.trancheIndex,
                auctionSetting.sellAmount,
                Constants.EMPTY
            );
            // tranche nft decimals is 6 and ether decimals is 18, so calculated factor = 10 ** (18-6)
            tokenMultiplier = D12;
        }
        (uint256 feeAmount, uint256 lockedLevel) = lockWater(
            msg.sender,
            auctionSetting.sellAmount,
            tokenMultiplier,
            priceForFee
        );
        if (feeAmount > 0) {
            if (msg.value < feeAmount) revert InsufficientFee();
            else if (msg.value > feeAmount) {
                (bool success, ) = msg.sender.call{value: msg.value - feeAmount}("");
                if (!success) revert NoTransferEther();
            }
            uint256 ethReward = (feeAmount * auctionStorage.feeForTower) / FEE_DENOMINATOR;
            auctionStorage.reserveFees[Constants.ETHER] += (feeAmount - ethReward);
            IWaterTowerUpgradeable(address(this)).addETHReward{value: ethReward}();
        }
        auctionStorage.currentAuctionId = auctionId;
        auctionSetting.reserve = auctionSetting.sellAmount;
        auctionStorage.auctions[auctionId].s = auctionSetting;
        auctionStorage.auctions[auctionId].seller = msg.sender;
        auctionStorage.auctions[auctionId].lockedLevel = lockedLevel;
        emit AuctionCreated(auctionSetting, msg.sender, auctionId);
    }

    /// @notice update important options of auction before any bidding
    /// @param auctionId auction id
    /// @param minBidAmount min bid amount to update
    /// @param priceRangeStart start price
    /// @param incrementBidPrice increment bid price
    function updateAuction(
        uint256 auctionId,
        uint128 minBidAmount,
        uint128 priceRangeStart,
        uint128 incrementBidPrice
    ) external whenNotPaused {
        AuctionStorage.Layout storage auctionStorage = AuctionStorage.layout();
        AuctionData memory auction = auctionStorage.auctions[auctionId];
        if (auction.seller != msg.sender) revert NoAuctioneer();
        if (
            auction.status != AuctionStatus.Open ||
            auction.s.endTime < block.timestamp ||
            auction.curBidId != 0
        ) revert NoIdleAuction();

        if (priceRangeStart > auction.s.priceRangeEnd) revert InvalidEndPrice();

        if (
            minBidAmount >= auction.s.sellAmount / MINBID_FACTOR &&
            minBidAmount <= auction.s.sellAmount
        ) auctionStorage.auctions[auctionId].s.minBidAmount = minBidAmount;

        if (priceRangeStart != 0)
            auctionStorage.auctions[auctionId].s.priceRangeStart = priceRangeStart;
        if (
            incrementBidPrice != 0 &&
            incrementBidPrice * INCREMENTBID_FACTOR <=
            auctionStorage.auctions[auctionId].s.priceRangeStart
        ) auctionStorage.auctions[auctionId].s.incrementBidPrice = incrementBidPrice;

        emit AuctionUpdate(auctionId, minBidAmount, priceRangeStart, incrementBidPrice);
    }

    /// @notice buy token immediately with fixed price
    /// @param auctionId      auction id
    /// @param purchaseAmount amount to purchase
    /// @param buyTokenId     token id to buy with
    function buyNow(
        uint256 auctionId,
        uint128 purchaseAmount,
        uint16 buyTokenId
    ) external nonReentrant whenNotPaused {
        AuctionStorage.Layout storage auctionStorage = AuctionStorage.layout();
        AuctionData memory auction = auctionStorage.auctions[auctionId];
        // Check auction.seller if address(0) auction hasn't been initialized/created and then check the auction type.
        if (auction.seller == address(0) || auction.s.auctionType == AuctionType.TimedAuction)
            revert InvalidAuction();
        address _purchaseToken = AuctionStorage
            .layout()
            .bidTokenGroups[auction.s.bidTokenGroupId]
            .bidTokens[buyTokenId];
        checkAuctionInProgress(auction.s.endTime, auction.s.startTime);
        uint128 availableAmount = auction.s.reserve;
        uint256 trancheIndex = auction.s.trancheIndex;
        if (purchaseAmount > availableAmount) revert InsufficientReserveAsset();
        if (auction.s.minBidAmount > purchaseAmount) revert SmallBidAmount();

        unchecked {
            auctionStorage.auctions[auctionId].s.reserve = availableAmount - purchaseAmount;
        }
        uint8 sellTokenDecimals;
        if (trancheIndex == 0) {
            sellTokenDecimals = IERC20MetadataUpgradeable(auction.s.sellToken).decimals();
            IERC20Upgradeable(auction.s.sellToken).safeTransfer(msg.sender, purchaseAmount);
        } else {
            sellTokenDecimals = Constants.TRANCHE_DECIMALS;
            IERC1155Upgradeable(address(this)).safeTransferFrom(
                address(this),
                msg.sender,
                trancheIndex,
                purchaseAmount,
                Constants.EMPTY
            );
        }
        uint256 payAmount = getPayAmount(
            _purchaseToken,
            purchaseAmount,
            auction.s.fixedPrice,
            sellTokenDecimals
        );
        uint256 fee = (payAmount * auctionStorage.fee.successFees[auction.lockedLevel]) /
            FEE_DENOMINATOR;
        IERC20Upgradeable(_purchaseToken).safeTransferFrom(
            msg.sender,
            auction.seller,
            payAmount - fee
        );
        IERC20Upgradeable(_purchaseToken).safeTransferFrom(msg.sender, address(this), fee);
        auctionStorage.reserveFees[_purchaseToken] += fee;
        emit AuctionBuy(msg.sender, payAmount, purchaseAmount, _purchaseToken, auctionId);
    }

    function placeBid(
        uint256 auctionId,
        uint128 bidAmount,
        uint16 bidTokenId,
        uint128 bidPrice,
        uint128 maxBidPrice
    ) external nonReentrant whenNotPaused returns (uint256) {
        AuctionStorage.Layout storage auctionStorage = AuctionStorage.layout();
        AuctionData memory auction = auctionStorage.auctions[auctionId];
        if (auction.seller == address(0) || auction.s.auctionType == AuctionType.FixedPrice)
            revert InvalidAuction();
        address _purchaseToken = AuctionStorage
            .layout()
            .bidTokenGroups[auction.s.bidTokenGroupId]
            .bidTokens[bidTokenId];
        checkAuctionInProgress(auction.s.endTime, auction.s.startTime);
        if (auction.s.minBidAmount > bidAmount) revert SmallBidAmount();
        if (bidAmount > auction.s.reserve) revert InsufficientReserveAsset();
        // bid price starts from priceRangeStart
        uint128 availableBidPrice = auction.curBidId == 0
            ? auction.s.priceRangeStart
            : auctionStorage.bids[auctionId][auction.curBidId].bidPrice +
                auction.s.incrementBidPrice;
        // if bidPrice is 0, place bid in increment way
        if (bidPrice == 0) bidPrice = availableBidPrice;
        else if (bidPrice < availableBidPrice) revert LowBid();
        if (bidPrice > maxBidPrice) revert OverPriceBid();
        uint128 _bidPrice = bidPrice;
        uint256 payAmount = getPayAmount(
            _purchaseToken,
            bidAmount,
            _bidPrice,
            auction.s.trancheIndex > 0
                ? 6
                : IERC20MetadataUpgradeable(auction.s.sellToken).decimals()
        );
        IERC20Upgradeable(_purchaseToken).safeTransferFrom(msg.sender, address(this), payAmount);
        Bid memory bid = Bid({
            bidder: msg.sender,
            bidAmount: bidAmount,
            bidPrice: _bidPrice,
            paidAmount: uint128(payAmount),
            bidTokenId: bidTokenId,
            bCleared: false
        });
        uint128 currentBidId = auction.curBidId + 1;
        {
            uint256 gasRemaining = gasleft();
            uint256 _auctionId = auctionId;
            uint128 _bidAmount = bidAmount;
            auctionStorage.bids[_auctionId][currentBidId] = bid;
            uint256 availableBidDepth = uint256(auction.availableBidDepth) + 1;
            uint128 totalBidAmount = auction.totalBidAmount + _bidAmount;
            address[] memory bidTokens = AuctionStorage
                .layout()
                .bidTokenGroups[auction.s.bidTokenGroupId]
                .bidTokens;
            // cancel bids not eligible in a range of gas limit
            while (true) {
                uint256 _cancelBidId = currentBidId - availableBidDepth + 1;
                Bid memory cancelBid = auctionStorage.bids[_auctionId][_cancelBidId];
                // even though reserve sell amount is smaller than bidAmount, settle the bid and the bidder receives sell token as possible
                if (totalBidAmount < auction.s.reserve + cancelBid.bidAmount) break;
                unchecked {
                    totalBidAmount -= cancelBid.bidAmount;
                    availableBidDepth--;
                }
                /// cancel not eligible bids
                if (cancelBid.bCleared) revert NoCancelBid();
                IERC20Upgradeable(bidTokens[cancelBid.bidTokenId]).safeTransfer(
                    cancelBid.bidder,
                    cancelBid.paidAmount
                );
                AuctionStorage.layout().bids[_auctionId][_cancelBidId].bCleared = true;
                if (gasRemaining - gasleft() > BID_GAS_LIMIT) break;
            }
            AuctionStorage.layout().auctions[_auctionId].availableBidDepth = uint8(
                availableBidDepth
            );
            AuctionStorage.layout().auctions[_auctionId].totalBidAmount = totalBidAmount;
            AuctionStorage.layout().auctions[_auctionId].curBidId = currentBidId;
            emit AuctionBid(bid, _auctionId, currentBidId, availableBidDepth);
        }
        return currentBidId;
    }

    function closeAuction(uint256 auctionId) external nonReentrant whenNotPaused {
        AuctionData memory auction = AuctionStorage.layout().auctions[auctionId];
        require(
            block.timestamp >= auction.s.endTime && auction.status != AuctionStatus.Closed,
            "auction can't be closed"
        );
        _settleAuction(auctionId, auction);
    }

    /// @notice function to get status of bid
    /// @param auctionId auction id
    /// @param bidId  bid id
    /// @return isWinner true if the bid is winner
    /// @return isClaimed true if the bid was claimed

    function isWinnerBid(
        uint256 auctionId,
        uint256 bidId
    ) external view returns (bool isWinner, bool isClaimed, uint256 claimAmount) {
        AuctionStorage.Layout storage auctionStorage = AuctionStorage.layout();
        AuctionData memory auction = auctionStorage.auctions[auctionId];
        Bid memory bid = auctionStorage.bids[auctionId][bidId];
        return _isWinnerBid(auctionId, bidId, auction, bid);
    }

    /// @notice claim bid for winner or canceled bid after auction is closed
    /// @dev anyone can claim bid
    function claimBid(uint256 auctionId, uint256 bidId) external nonReentrant whenNotPaused {
        AuctionStorage.Layout storage auctionStorage = AuctionStorage.layout();
        AuctionData memory auction = auctionStorage.auctions[auctionId];
        Bid memory bid = auctionStorage.bids[auctionId][bidId];
        (bool isWinner, bool isClaimed, uint256 claimAmount) = _isWinnerBid(
            auctionId,
            bidId,
            auction,
            bid
        );
        if (isClaimed) revert ClaimedBid();
        auctionStorage.bids[auctionId][bidId].bCleared = true;
        if (auction.status != AuctionStatus.Closed) revert NoClosedAuction();
        IERC20Upgradeable _purchaseToken = IERC20Upgradeable(
            auctionStorage.bidTokenGroups[auction.s.bidTokenGroupId].bidTokens[bid.bidTokenId]
        );
        if (isWinner) {
            auctionStorage.auctions[auctionId].s.reserve = auction.s.reserve - uint128(claimAmount);
            _settleBid(
                auction.s.sellToken,
                auction.s.trancheIndex,
                _purchaseToken,
                bid,
                uint128(claimAmount)
            );
        } else {
            _purchaseToken.safeTransfer(bid.bidder, bid.paidAmount);
        }
        emit ClaimBid(auctionId, bidId, isWinner, claimAmount);
    }

    function _settleAuction(uint256 auctionId, AuctionData memory auction) internal {
        uint256 gasLimit = gasleft();
        uint128 availableAmount = auction.s.reserve;
        uint256 settledBidCount;
        uint256 curBidId = auction.curBidId;
        AuctionStorage.Layout storage auctionStorage = AuctionStorage.layout();
        address[] memory bidTokens = auctionStorage
            .bidTokenGroups[auction.s.bidTokenGroupId]
            .bidTokens;
        uint256[] memory payoutAmounts = new uint256[](bidTokens.length);
        bool bOverGasLimit = false;
        uint128 reserve = availableAmount;
        while (curBidId > 0 && reserve > 0) {
            Bid memory bid = auctionStorage.bids[auctionId][curBidId];
            if (bid.bCleared) break;
            if (!bOverGasLimit && gasLimit <= gasleft() + CLOSE_GAS_LIMIT) {
                auctionStorage.bids[auctionId][curBidId].bCleared = true;
                (uint128 settledAmount, uint128 payoutAmount) = _settleBid(
                    auction.s.sellToken,
                    auction.s.trancheIndex,
                    IERC20Upgradeable(bidTokens[bid.bidTokenId]),
                    bid,
                    availableAmount
                );
                payoutAmounts[bid.bidTokenId] += payoutAmount;
                unchecked {
                    availableAmount -= settledAmount;
                    reserve -= settledAmount;
                    ++settledBidCount;
                }
            } else {
                // it allows the calculation for gas limit done only one time
                if (!bOverGasLimit) bOverGasLimit = true;
                if (bid.bidAmount > reserve) {
                    payoutAmounts[bid.bidTokenId] += (bid.paidAmount * reserve) / bid.bidAmount;
                    reserve = 0;
                } else {
                    payoutAmounts[bid.bidTokenId] += bid.paidAmount;
                    unchecked {
                        reserve -= bid.bidAmount;
                    }
                }
            }
            unchecked {
                --curBidId;
            }
        }
        // transfer paid tokens from contract to seller
        // unclock locked water
        uint256 realPayPecentage = FEE_DENOMINATOR -
            unlockWater(auction.seller, auction.lockedLevel);
        for (uint256 i; i < bidTokens.length; ) {
            uint256 payoutAmount = payoutAmounts[i];
            if (payoutAmount > 0) {
                address _purchaseToken = bidTokens[i];
                uint256 realPayAmount = (payoutAmount * realPayPecentage) / FEE_DENOMINATOR;
                IERC20Upgradeable(bidTokens[i]).safeTransfer(auction.seller, realPayAmount);
                unchecked {
                    auctionStorage.reserveFees[_purchaseToken] += (payoutAmount - realPayAmount);
                }
            }
            unchecked {
                ++i;
            }
        }

        // refund unsold tokens
        if (reserve > 0) {
            unchecked {
                availableAmount -= reserve;
            }
            if (auction.s.trancheIndex == 0) {
                IERC20Upgradeable(auction.s.sellToken).safeTransfer(auction.seller, reserve);
            } else {
                IERC1155Upgradeable(address(this)).safeTransferFrom(
                    address(this),
                    auction.seller,
                    auction.s.trancheIndex,
                    reserve,
                    Constants.EMPTY
                );
            }
        }

        auctionStorage.auctions[auctionId].s.reserve = availableAmount;
        auctionStorage.auctions[auctionId].status = AuctionStatus.Closed;

        unchecked {
            auctionStorage.auctions[auctionId].totalBidAmount =
                auction.totalBidAmount -
                availableAmount;
            auctionStorage.auctions[auctionId].curBidId =
                auction.curBidId -
                uint128(settledBidCount);
        }
        emit AuctionClosed(availableAmount, auctionId, settledBidCount);
    }

    /// @notice transfer auctioning token to bidder
    function _settleBid(
        address sellToken,
        uint256 trancheIndex,
        IERC20Upgradeable _purchaseToken,
        Bid memory bid,
        uint128 availableAmount
    ) internal returns (uint128 settledAmount, uint128 payoutAmount) {
        settledAmount = bid.bidAmount;
        payoutAmount = bid.paidAmount;
        if (availableAmount < settledAmount) {
            uint128 repayAmount;
            unchecked {
                repayAmount = settledAmount - availableAmount;
            }
            // calculate as payout token
            repayAmount = (repayAmount * bid.paidAmount) / bid.bidAmount;
            payoutAmount -= repayAmount;
            settledAmount = availableAmount;
            _purchaseToken.safeTransfer(bid.bidder, repayAmount);
        }
        if (trancheIndex == 0) {
            IERC20Upgradeable(sellToken).safeTransfer(bid.bidder, settledAmount);
        } else {
            IERC1155Upgradeable(address(this)).safeTransferFrom(
                address(this),
                bid.bidder,
                trancheIndex,
                settledAmount,
                Constants.EMPTY
            );
        }
    }

    function _isWinnerBid(
        uint256 auctionId,
        uint256 bidId,
        AuctionData memory auction,
        Bid memory bid
    ) internal view returns (bool isWinner, bool isClaimed, uint256 claimAmount) {
        AuctionStorage.Layout storage auctionStorage = AuctionStorage.layout();
        if (bid.bCleared) isClaimed = true;
        if (auction.status != AuctionStatus.Closed) {
            return (false, isClaimed, 0);
        } else {
            uint256 curBidId = auction.curBidId;
            uint256 reserve = auction.s.reserve;
            unchecked {
                while (curBidId > bidId && reserve > 0) {
                    Bid memory seniorBid = auctionStorage.bids[auctionId][curBidId];
                    if (!seniorBid.bCleared) {
                        if (reserve > seniorBid.bidAmount) {
                            reserve -= seniorBid.bidAmount;
                        } else reserve = 0;
                    }
                    --curBidId;
                }
                if (reserve > 0) {
                    return (
                        true,
                        isClaimed,
                        reserve >= bid.bidAmount ? bid.bidAmount : bid.bidAmount - reserve
                    );
                } else return (false, isClaimed, 0);
            }
        }
    }

    // admin setters are implemented in IrrigationControl

    // getters
    function getPayAmount(
        address purchaseToken,
        uint128 purchaseAmount,
        uint128 price,
        uint8 sellTokenDecimals
    ) public view returns (uint256) {
        uint256 denominator = (10 **
            (18 - IERC20MetadataUpgradeable(purchaseToken).decimals() + sellTokenDecimals));
        return FullMath.mulDivRoundingUp128(purchaseAmount, price, denominator);
    }

    function getAuction(uint256 auctionId) external view returns (AuctionData memory) {
        return AuctionStorage.layout().auctions[auctionId];
    }

    function getBid(uint256 auctionId, uint256 bidId) external view returns (Bid memory) {
        return AuctionStorage.layout().bids[auctionId][bidId];
    }

    function getAuctionsCount() external view returns (uint256 totalAuctionsCount) {
        return AuctionStorage.layout().currentAuctionId;
    }

    function getBidTokenGroup(
        uint256 tokenGroupId
    ) external view returns (BidTokenGroup memory tokenGroup) {
        return AuctionStorage.layout().bidTokenGroups[tokenGroupId];
    }

    function getBidTokenGroupCount() external view returns (uint256 countOfTokenGroup) {
        return AuctionStorage.layout().countOfTokenGroups;
    }

    function getAuctionPeriods() external view returns (uint48[] memory) {
        return AuctionStorage.layout().periods;
    }

    /// @dev returns true if auction in progress, false otherwise
    function checkAuctionInProgress(uint256 endTime, uint256 startTime) internal view {
        if (startTime > block.timestamp || (endTime > 0 && endTime <= block.timestamp))
            revert InactiveAuction();
    }

    function getListingFeeForUser(
        address user,
        uint256 amount,
        uint256 multiplier,
        uint256 tokenPrice
    ) external view returns (uint256 feeAmount) {
        (uint256 listingFee, , , ) = getAuctionFeeAndLimit(WaterTowerStorage.userInfo(user).amount);
        feeAmount = getListingFee(listingFee, amount, multiplier, tokenPrice);
    }

    /// @notice returns fee level, fee amount, listing fee and closing fee numerator for water amount
    function getAuctionFeeAndLimit(
        uint256 waterAmount
    )
        public
        view
        returns (uint256 listingFee, uint256 successFee, uint256 feeLevel, uint256 limit)
    {
        AuctionFee memory fee = AuctionStorage.layout().fee;
        uint256 i;
        for (i; i < fee.limits.length - 1; ) {
            if (waterAmount < fee.limits[i + 1])
                return (fee.listingFees[i], fee.successFees[i], i, fee.limits[i]);
            unchecked {
                ++i;
            }
        }
        return (fee.listingFees[i], fee.successFees[i], i, fee.limits[i]);
    }

    /// @notice return listing fee amount for amount and fee percentage
    function getListingFee(
        uint256 listingFee,
        uint256 auctionAmount,
        uint256 multiplier,
        uint256 tokenPrice
    ) internal view returns (uint256 feeEthAmount) {
        /// @dev fee is calulated with ether price, auction price, and auction amount
        uint256 ethPrice = IPriceOracleUpgradeable(address(this)).getUnderlyingPriceETH();
        return
            (((auctionAmount * multiplier * listingFee * tokenPrice) / ethPrice)) / FEE_DENOMINATOR;
    }

    // lock water for fee level and return listing fee amount
    // called when creating auction
    function lockWater(
        address user,
        uint256 auctionAmount,
        uint256 multiplier,
        uint256 tokenPrice
    ) internal returns (uint256 fee, uint256 lockedLevel) {
        WaterTowerStorage.Layout storage wl = WaterTowerStorage.layout();
        uint256 userAmount = wl.users[user].amount;
        LockedUserInfo storage lockedInfo = wl.lockedUsers[user];
        (uint256 listingFee, , uint256 feeLevel, uint256 amountToLock) = getAuctionFeeAndLimit(
            userAmount
        );
        /// @dev fee is calulated with ether price, auction price, and auction amount
        fee = getListingFee(listingFee, auctionAmount, multiplier, tokenPrice);
        if (amountToLock != 0) {
            lockedInfo.lockedCounts[feeLevel] = lockedInfo.lockedCounts[feeLevel] + 1;
            if (lockedInfo.lockedAmount < amountToLock) lockedInfo.lockedAmount = amountToLock;
        }
        return (fee, feeLevel);
    }

    function unlockWater(
        address user,
        uint256 lockedLevelForAuction
    ) internal returns (uint256 successFee) {
        // WaterTowerStorage.Layout storage wl = WaterTowerStorage.layout();
        LockedUserInfo storage lockedInfo = WaterTowerStorage.layout().lockedUsers[user];
        AuctionFee memory fee = AuctionStorage.layout().fee;
        successFee = fee.successFees[lockedLevelForAuction];
        uint256 lockedForAuction = fee.limits[lockedLevelForAuction];
        if (lockedForAuction == 0) return successFee;
        uint256 lockedCount = lockedInfo.lockedCounts[lockedLevelForAuction] - 1;
        lockedInfo.lockedCounts[lockedLevelForAuction] = uint32(lockedCount);
        if (lockedCount == 0 && lockedInfo.lockedAmount == lockedForAuction) {
            if (lockedLevelForAuction >= 1) {
                // find locked min level
                for (uint256 i = lockedLevelForAuction - 1; i > 0; ) {
                    if (lockedInfo.lockedCounts[i] > 0) {
                       lockedInfo.lockedAmount = fee.limits[i];
                        return successFee;
                    }
                    unchecked {
                        --i;
                    }
                }
            }
            lockedInfo.lockedAmount = fee.limits[0];
        }
    }

    function getReserveFee(address token) external view returns (uint256 fee) {
        return AuctionStorage.layout().reserveFees[token];
    }
}
