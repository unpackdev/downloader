// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./RoyaltyPayoutHelper.sol";
import "./CommonUtils.sol";
import "./TLAuctionHouseUtils.sol";

/*//////////////////////////////////////////////////////////////////////////
                            TL Auction House
//////////////////////////////////////////////////////////////////////////*/

/// @title TLAuctionHouse
/// @notice Transient Labs Auction House with Reserve Auctions and Buy Now Sales for ERC-721 tokens
/// @author transientlabs.xyz
/// @custom:version-last-updated 2.1.0
contract TLAuctionHouse is
    Ownable,
    Pausable,
    ReentrancyGuard,
    RoyaltyPayoutHelper,
    ITLAuctionHouseEvents,
    AuctionHouseErrors
{
    /*//////////////////////////////////////////////////////////////////////////
                                  Constants
    //////////////////////////////////////////////////////////////////////////*/

    string public constant VERSION = "2.1.0";
    uint256 public constant EXTENSION_TIME = 15 minutes;
    uint256 public constant BASIS = 10_000;

    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    address public protocolFeeReceiver; // the payout receiver for the protocol fee
    uint256 public minBidIncreasePerc; // the nominal bid increase percentage (out of BASIS) so bids can't be increased by just tiny amounts
    uint256 public minBidIncreaseLimit; // the absolute min bid increase amount (ex: 1 ether)
    uint256 public protocolFeePerc; // the nominal protocol fee percentage (out of BASIS) to charge the buyer or seller
    uint256 public protocolFeeLimit; // the absolute limit for the protocol fee (ex: 1 ether)
    mapping(address => mapping(uint256 => Auction)) internal _auctions; // nft address -> token id -> auction
    mapping(address => mapping(uint256 => Sale)) internal _sales; // nft address -> token id -> sale

    /*//////////////////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        address initSanctionsOracle,
        address initWethAddress,
        address initRoyaltyEngineAddress,
        address initProtocolFeeReceiver,
        uint256 initMinBidIncreasePerc,
        uint256 initMinBidIncreaseLimit,
        uint256 initProtocolFeePerc,
        uint256 initProtocolFeeLimit
    )
        Ownable()
        Pausable()
        ReentrancyGuard()
        RoyaltyPayoutHelper(initSanctionsOracle, initWethAddress, initRoyaltyEngineAddress)
    {
        _setMinBidIncreaseSettings(initMinBidIncreasePerc, initMinBidIncreaseLimit);
        _setProtocolFeeSettings(initProtocolFeeReceiver, initProtocolFeePerc, initProtocolFeeLimit);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Owner Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to set a new royalty engine address
    /// @dev Requires owner
    /// @param newRoyaltyEngine The new royalty engine address
    function setRoyaltyEngine(address newRoyaltyEngine) external onlyOwner {
        address prevRoyaltyEngine = address(royaltyEngine);
        _setRoyaltyEngineAddress(newRoyaltyEngine);

        emit RoyaltyEngineUpdated(prevRoyaltyEngine, newRoyaltyEngine);
    }

    /// @notice Function to set a new weth address
    /// @dev Requires owner
    /// @param newWethAddress The new weth address
    function setWethAddress(address newWethAddress) external onlyOwner {
        address prevWeth = weth;
        _setWethAddress(newWethAddress);

        emit WethUpdated(prevWeth, newWethAddress);
    }

    /// @notice Function to set the min bid increase settings
    /// @dev Requires owner
    /// @param newMinBidIncreasePerc The new minimum bid increase nominal percentage, out of `BASIS`
    /// @param newMinBidIncreaseLimit The new minimum bid increase absolute limit
    function setMinBidIncreaseSettings(uint256 newMinBidIncreasePerc, uint256 newMinBidIncreaseLimit)
        external
        onlyOwner
    {
        _setMinBidIncreaseSettings(newMinBidIncreasePerc, newMinBidIncreaseLimit);
    }

    /// @notice Function to set the protocol fee settings
    /// @dev Requires owner
    /// @param newProtocolFeeReceiver The new protocol fee receiver
    /// @param newProtocolFeePerc The new protocol fee percentage, out of `BASIS`
    /// @param newProtocolFeeLimit The new protocol fee limit
    function setProtocolFeeSettings(
        address newProtocolFeeReceiver,
        uint256 newProtocolFeePerc,
        uint256 newProtocolFeeLimit
    ) external onlyOwner {
        _setProtocolFeeSettings(newProtocolFeeReceiver, newProtocolFeePerc, newProtocolFeeLimit);
    }

    /// @notice Function to pause the contract
    /// @dev Requires owner
    /// @param status The boolean to set the internal pause variable
    function pause(bool status) external onlyOwner {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @notice Function to set the sanctions oracle
    /// @dev Requires owner
    /// @param newOracle The new oracle address
    function setSanctionsOracle(address newOracle) external onlyOwner {
        _updateSanctionsOracle(newOracle);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Auction Configuration Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to configure an auction
    /// @dev Requires the following items to be true
    ///     - contract is not paused
    ///     - the auction hasn't been configured yet for the current token owner
    ///     - msg.sender is the owner of the token
    ///     - auction house is approved for all
    ///     - payoutReceiver isn't the zero address
    /// @param nftAddress The nft contract address
    /// @param tokenId The nft token id
    /// @param payoutReceiver The address that receives the payout from the auction
    /// @param currencyAddress The currency to use
    /// @param reservePrice The auction reserve price
    /// @param auctionOpenTime The time at which bidding is allowed
    /// @param duration The duration of the auction after it is started
    /// @param reserveAuction A flag dictating if the auction is a reserve auction or regular scheduled auction
    function configureAuction(
        address nftAddress,
        uint256 tokenId,
        address payoutReceiver,
        address currencyAddress,
        uint256 reservePrice,
        uint256 auctionOpenTime,
        uint256 duration,
        bool reserveAuction
    ) external whenNotPaused nonReentrant {
        // sanctions
        _isSanctioned(msg.sender, true);
        _isSanctioned(payoutReceiver, true);

        IERC721 nft = IERC721(nftAddress);
        bool isNftOwner = _checkTokenOwnership(nft, tokenId, msg.sender);
        uint256 startTime = reserveAuction ? 0 : auctionOpenTime;

        if (isNftOwner) {
            if (!_checkAuctionHouseApproval(nft, msg.sender)) revert AuctionHouseNotApproved();
            if (!_checkPayoutReceiver(payoutReceiver)) revert PayoutToZeroAddress();
        } else {
            revert CallerNotTokenOwner();
        }

        Auction memory auction = Auction(
            msg.sender,
            payoutReceiver,
            currencyAddress,
            address(0),
            0,
            reservePrice,
            auctionOpenTime,
            startTime,
            duration
        );

        _auctions[nftAddress][tokenId] = auction;

        emit AuctionConfigured(msg.sender, nftAddress, tokenId, auction);
    }

    /// @notice Function to cancel an auction
    /// @dev Requires the following to be true
    ///     - msg.sender to be the auction seller
    ///     - the auction cannot be started
    /// @param nftAddress The nft contract address
    /// @param tokenId The nft token id
    function cancelAuction(address nftAddress, uint256 tokenId) external nonReentrant {
        IERC721 nft = IERC721(nftAddress);
        Auction memory auction = _auctions[nftAddress][tokenId];
        bool isNftOwner = _checkTokenOwnership(nft, tokenId, msg.sender);

        if (msg.sender != auction.seller) {
            if (!isNftOwner) revert CallerNotTokenOwner();
        }
        if (auction.highestBidder != address(0)) revert AuctionStarted();

        delete _auctions[nftAddress][tokenId];

        emit AuctionCanceled(msg.sender, nftAddress, tokenId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    Auction Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to bid on an auction
    /// @dev Requires the following to be true
    ///     - contract is not paused
    ///     - block.timestamp is greater than the auction open timestamp
    ///     - bid meets or exceeds the reserve price / min bid price
    ///     - msg.sender has attached enough eth/erc20 as specified by `amount`
    ///     - protocol fee has been supplied, if needed
    /// @param nftAddress The nft contract address
    /// @param tokenId The nft token id
    /// @param amount The amount to bid in the currency address set in the auction
    function bid(address nftAddress, uint256 tokenId, uint256 amount) external payable whenNotPaused nonReentrant {
        _isSanctioned(msg.sender, true);

        // cache items
        Auction memory auction = _auctions[nftAddress][tokenId];
        IERC721 nft = IERC721(nftAddress);
        bool firstBid;
        bool durationExtended;

        // check if the auction is open
        if (auction.seller == address(0)) revert AuctionNotConfigured();
        if (block.timestamp < auction.auctionOpenTime) revert AuctionNotOpen();

        if (auction.highestBidder == address(0)) {
            // first bid
            // - check bid amount
            // - clear sale
            // - start the auction (if reserve auction)
            // - escrow the NFT
            if (amount < auction.reservePrice) revert BidTooLow();
            delete _sales[nftAddress][tokenId];
            if (auction.startTime == 0) {
                auction.startTime = block.timestamp;
                firstBid = true;
            }
            // escrow nft
            if (nft.ownerOf(tokenId) != auction.seller) revert NftNotOwnedBySeller();
            nft.transferFrom(auction.seller, address(this), tokenId);
            if (nft.ownerOf(tokenId) != address(this)) revert NftNotTransferred();
        } else {
            // subsequent bids
            // - check if auction ended
            // - check bid amount
            // - refund previous bidder
            if (block.timestamp > auction.startTime + auction.duration) revert AuctionEnded();
            if (amount < _calcNextMinBid(auction.highestBid)) revert BidTooLow();
            uint256 refundAmount = auction.highestBid + _calcProtocolFee(auction.highestBid);
            if (auction.currencyAddress == address(0)) {
                _safeTransferETH(auction.highestBidder, refundAmount, weth);
            } else {
                _safeTransferERC20(auction.highestBidder, auction.currencyAddress, refundAmount);
            }
        }

        // set highest bid
        auction.highestBid = amount;
        auction.highestBidder = msg.sender;

        // extend auction if needed
        uint256 timeRemaining = auction.startTime + auction.duration - block.timestamp;
        if (timeRemaining < EXTENSION_TIME) {
            auction.duration += EXTENSION_TIME - timeRemaining;
            durationExtended = true;
        }

        // store updated parameters to storage
        Auction storage sAuction = _auctions[nftAddress][tokenId];
        sAuction.highestBid = auction.highestBid;
        sAuction.highestBidder = auction.highestBidder;
        if (firstBid) sAuction.startTime = auction.startTime;
        if (durationExtended) sAuction.duration = auction.duration;

        // calculate the protocol fee
        uint256 protocolFee = _calcProtocolFee(amount);

        // transfer funds (move ERC20, refund ETH)
        uint256 totalAmount = amount + protocolFee;
        if (auction.currencyAddress == address(0)) {
            if (msg.value < totalAmount) revert InsufficientMsgValue();
            uint256 refund = msg.value - totalAmount;
            if (refund > 0) {
                _safeTransferETH(msg.sender, refund, weth);
            }
        } else {
            _safeTransferFromERC20(msg.sender, address(this), auction.currencyAddress, totalAmount);
            if (msg.value > 0) {
                _safeTransferETH(msg.sender, msg.value, weth);
            }
        }

        emit AuctionBid(msg.sender, nftAddress, tokenId, auction);
    }

    /// @notice Function to settle an auction
    /// @dev Can be called by anyone
    /// @dev Requires the following to be true
    ///     - auction has been started
    ///     - auction has ended
    /// @param nftAddress The nft contract address
    /// @param tokenId The nft token id
    function settleAuction(address nftAddress, uint256 tokenId) external nonReentrant {
        // cache items
        Auction memory auction = _auctions[nftAddress][tokenId];
        IERC721 nft = IERC721(nftAddress);

        // check requirements
        if (auction.highestBidder == address(0)) revert AuctionNotStarted();
        if (block.timestamp < auction.startTime + auction.duration) revert AuctionNotEnded();

        // clear the auction
        delete _auctions[nftAddress][tokenId];

        // payout auction
        _payout(nftAddress, tokenId, auction.currencyAddress, auction.highestBid, auction.payoutReceiver);

        // transfer nft
        nft.transferFrom(address(this), auction.highestBidder, tokenId);
        if (nft.ownerOf(tokenId) != auction.highestBidder) revert NftNotTransferred();

        emit AuctionSettled(msg.sender, nftAddress, tokenId, auction);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Sales Configuration Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to configure a buy now sale
    /// @dev Requires the following to be true
    ///     - contract is not paused
    ///     - the sale hasn't been configured yet by the current token owner
    ///     - an auction hasn't been started - this is captured by token ownership
    ///     - msg.sender is the owner of the token
    ///     - auction house is approved for all
    ///     - payoutReceiver isn't the zero address
    /// @param nftAddress The nft contract address
    /// @param tokenId The nft token id
    /// @param payoutReceiver The address that receives the payout from the sale
    /// @param currencyAddress The currency to use
    /// @param price The sale price
    /// @param saleOpenTime The time at which the sale opens
    function configureSale(
        address nftAddress,
        uint256 tokenId,
        address payoutReceiver,
        address currencyAddress,
        uint256 price,
        uint256 saleOpenTime
    ) external whenNotPaused nonReentrant {
        // sanctions
        _isSanctioned(msg.sender, true);
        _isSanctioned(payoutReceiver, true);

        IERC721 nft = IERC721(nftAddress);
        bool isNftOwner = _checkTokenOwnership(nft, tokenId, msg.sender);

        if (isNftOwner) {
            if (!_checkAuctionHouseApproval(nft, msg.sender)) revert AuctionHouseNotApproved();
            if (!_checkPayoutReceiver(payoutReceiver)) revert PayoutToZeroAddress();
        } else {
            revert CallerNotTokenOwner();
        }

        Sale memory sale = Sale(msg.sender, payoutReceiver, currencyAddress, price, saleOpenTime);

        _sales[nftAddress][tokenId] = sale;

        emit SaleConfigured(msg.sender, nftAddress, tokenId, sale);
    }

    /// @notice Function to cancel a sale
    /// @dev Requires msg.sender to be the token owner
    /// @param nftAddress The nft contract address
    /// @param tokenId The nft token id
    function cancelSale(address nftAddress, uint256 tokenId) external nonReentrant {
        IERC721 nft = IERC721(nftAddress);
        Sale memory sale = _sales[nftAddress][tokenId];
        bool isNftOwner = _checkTokenOwnership(nft, tokenId, msg.sender);

        if (msg.sender != sale.seller) {
            if (!isNftOwner) revert CallerNotTokenOwner();
        }

        delete _sales[nftAddress][tokenId];

        emit SaleCanceled(msg.sender, nftAddress, tokenId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    Sales Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to buy a token
    /// @dev Requires the following to be true
    ///     - contract is not paused
    ///     - block.timestamp is greater than the sale open timestamp
    ///     - msg.sender has attached enough eth/erc20 as specified by the sale
    ///     - protocol fee has been supplied, if needed
    /// @param nftAddress The nft contract address
    /// @param tokenId The nft token id
    function buyNow(address nftAddress, uint256 tokenId) external payable whenNotPaused nonReentrant {
        _isSanctioned(msg.sender, true);

        // cache items
        Sale memory sale = _sales[nftAddress][tokenId];
        IERC721 nft = IERC721(nftAddress);

        // check if the sale is open
        if (sale.seller == address(0)) revert SaleNotConfigured();
        if (block.timestamp < sale.saleOpenTime) revert SaleNotOpen();

        // check that the nft is owned by the seller still
        if (nft.ownerOf(tokenId) != sale.seller) revert NftNotOwnedBySeller();

        // clear storage
        delete _auctions[nftAddress][tokenId];
        delete _sales[nftAddress][tokenId];

        // calculate the protocol fee
        uint256 protocolFee = _calcProtocolFee(sale.price);

        // transfer funds to the contract, refunding if needed
        uint256 totalAmount = sale.price + protocolFee;
        if (sale.currencyAddress == address(0)) {
            if (msg.value < totalAmount) revert InsufficientMsgValue();
            uint256 refund = msg.value - totalAmount;
            if (refund > 0) {
                _safeTransferETH(msg.sender, refund, weth);
            }
        } else {
            _safeTransferFromERC20(msg.sender, address(this), sale.currencyAddress, totalAmount);
            if (msg.value > 0) {
                _safeTransferETH(msg.sender, msg.value, weth);
            }
        }

        // payout sale
        _payout(nftAddress, tokenId, sale.currencyAddress, sale.price, sale.payoutReceiver);

        // transfer nft
        nft.transferFrom(sale.seller, msg.sender, tokenId);
        if (nft.ownerOf(tokenId) != msg.sender) revert NftNotTransferred();

        emit SaleFulfilled(msg.sender, nftAddress, tokenId, sale);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                External View Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to get a sale
    /// @param nftAddress The nft contract address
    /// @param tokenId The nft token id
    /// @return sale The sale struct
    function getSale(address nftAddress, uint256 tokenId) external view returns (Sale memory) {
        return _sales[nftAddress][tokenId];
    }

    /// @notice function to get an auction
    /// @param nftAddress The nft contract address
    /// @param tokenId The nft token id
    /// @return auction The auction struct
    function getAuction(address nftAddress, uint256 tokenId) external view returns (Auction memory) {
        return _auctions[nftAddress][tokenId];
    }

    /// @notice function to get the next minimum bid price for an auction
    /// @param nftAddress The nft contract address
    /// @param tokenId The nft token id
    /// @return uint256 The next minimum bid required
    function calcNextMinBid(address nftAddress, uint256 tokenId) external view returns (uint256) {
        return _calcNextMinBid(_auctions[nftAddress][tokenId].highestBid);
    }

    /// @notice function to calculate the protocol fee
    /// @param amount The value to calculate the fee for
    /// @return uint256 The calculated fee
    function calcProtocolFee(uint256 amount) external view returns (uint256) {
        return _calcProtocolFee(amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Internal Helper Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Internal function to set the min bid increase settings
    /// @param newMinBidIncreasePerc The new minimum bid increase nominal percentage, out of `BASIS`
    /// @param newMinBidIncreaseLimit The new minimum bid increase absolute limit
    function _setMinBidIncreaseSettings(uint256 newMinBidIncreasePerc, uint256 newMinBidIncreaseLimit) internal {
        if (newMinBidIncreasePerc > BASIS) revert PercentageTooLarge();

        minBidIncreasePerc = newMinBidIncreasePerc;
        minBidIncreaseLimit = newMinBidIncreaseLimit;

        emit MinBidIncreaseUpdated(newMinBidIncreasePerc, newMinBidIncreaseLimit);
    }

    /// @notice Internal function to set the protocol fee settings
    /// @param newProtocolFeeReceiver The new protocol fee receiver
    /// @param newProtocolFeePerc The new protocol fee percentage, out of `BASIS`
    /// @param newProtocolFeeLimit The new protocol fee limit
    function _setProtocolFeeSettings(
        address newProtocolFeeReceiver,
        uint256 newProtocolFeePerc,
        uint256 newProtocolFeeLimit
    ) internal {
        if (newProtocolFeePerc > BASIS) revert PercentageTooLarge();

        protocolFeeReceiver = newProtocolFeeReceiver;
        protocolFeePerc = newProtocolFeePerc;
        protocolFeeLimit = newProtocolFeeLimit;

        emit ProtocolFeeUpdated(newProtocolFeeReceiver, newProtocolFeePerc, newProtocolFeeLimit);
    }

    /// @notice Internal function to check if a token is owned by an address
    /// @param nft The nft contract
    /// @param tokenId The nft token id
    /// @param potentialTokenOwner The potential token owner to check against
    /// @return bool Indication of if the address in quesion is the owner of the token
    function _checkTokenOwnership(IERC721 nft, uint256 tokenId, address potentialTokenOwner)
        internal
        view
        returns (bool)
    {
        return nft.ownerOf(tokenId) == potentialTokenOwner;
    }

    /// @notice Internal function to check if the auction house is approved for all
    /// @param nft The nft contract
    /// @param seller The seller to check against
    /// @return bool Indication of if the auction house is approved for all by the seller
    function _checkAuctionHouseApproval(IERC721 nft, address seller) internal view returns (bool) {
        return nft.isApprovedForAll(seller, address(this));
    }

    /// @notice Internal function to check if a payout address is a valid address
    /// @param payoutReceiver The payout address to check
    /// @return bool Indication of if the payout address is not the zero address
    function _checkPayoutReceiver(address payoutReceiver) internal pure returns (bool) {
        return payoutReceiver != address(0);
    }

    /// @notice Internal function to calculate the next min bid price
    /// @param currentBid The current bid
    /// @return nextMinBid The next minimum bid
    function _calcNextMinBid(uint256 currentBid) internal view returns (uint256 nextMinBid) {
        uint256 bidIncrease = currentBid * minBidIncreasePerc / BASIS;
        if (bidIncrease > minBidIncreaseLimit) {
            bidIncrease = minBidIncreaseLimit;
        }
        nextMinBid = currentBid + bidIncrease;
    }

    /// @notice Internal function to calculate the protocol fee
    /// @param amount The value of the sale
    /// @return fee The protocol fee
    function _calcProtocolFee(uint256 amount) internal view returns (uint256 fee) {
        fee = amount * protocolFeePerc / BASIS;
        if (fee > protocolFeeLimit) {
            fee = protocolFeeLimit;
        }
    }

    /// @notice Internal function to payout from the contract
    /// @param nftAddress The nft contract address
    /// @param tokenId The token id
    /// @param currencyAddress The currency address (ZERO ADDRESS == ETH)
    /// @param amount The sale/auction end price
    /// @param payoutReceiver The receiver for the sale payout (what's remaining after royalties)
    function _payout(
        address nftAddress,
        uint256 tokenId,
        address currencyAddress,
        uint256 amount,
        address payoutReceiver
    ) internal {
        // calc protocol fee
        uint256 protocolFee = _calcProtocolFee(amount);

        // payout royalties
        uint256 remainingAmount = _payoutRoyalties(nftAddress, tokenId, currencyAddress, amount);

        // distribute protocol fee and remaining amount - should be escrowed in this contract
        if (currencyAddress == address(0)) {
            // transfer protocol fee
            _safeTransferETH(protocolFeeReceiver, protocolFee, weth);
            // transfer remaining value to payout receiver
            _safeTransferETH(payoutReceiver, remainingAmount, weth);
        } else {
            // transfer protocol fee
            _safeTransferERC20(protocolFeeReceiver, currencyAddress, protocolFee);
            // transfer remaining value to payout receiver
            _safeTransferERC20(payoutReceiver, currencyAddress, remainingAmount);
        }
    }
}
