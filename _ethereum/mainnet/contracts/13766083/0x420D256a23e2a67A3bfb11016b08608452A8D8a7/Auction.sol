// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

pragma experimental ABIEncoderV2;

import {Initializable} from "Initializable.sol";
import {IERC721} from "IERC721.sol";
import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {IERC165} from "IERC165.sol";
import {DataTypes} from "DataTypes.sol";
import {Errors} from "Errors.sol";
import {OwnerPausableUpgradeSafe} from "OwnerPausableUpgradeSafe.sol";
import "IERC721TokenAuthor.sol";


/**
 * @dev Auction between NFT holders and participants.
 */
contract Auction is OwnerPausableUpgradeSafe, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;

    mapping(uint256 /*tokenId*/ => DataTypes.AuctionData) internal _nftId2auction;
    uint256 public minPriceStepNumerator;
    uint256 constant public DENOMINATOR = 10000;
    uint256 constant public MIN_MIN_PRICE_STEP_NUMERATOR = 1;  // 0.01%
    uint256 constant public MAX_MIN_PRICE_STEP_NUMERATOR = 10000;  // 100%

    uint256 public authorRoyaltyNumerator;
    uint256 public overtimeWindow;
    uint256 public auctionDuration;
    uint256 constant MAX_OVERTIME_WINDOW = 365 days;
    uint256 constant MIN_OVERTIME_WINDOW = 1 minutes;
    uint256 constant MAX_AUCTION_DURATION = 365 days;
    uint256 constant MIN_AUCTION_DURATION = 1 minutes;
    IERC20 public payableToken;
    IERC721 public nft;

    address public treasury;
    uint256 public feeCreatorToBuyerTokenNumerator;
    uint256 public feeResellerToBuyerTokenNumerator;
    uint256 public feeCreatorToBuyerETHNumerator;
    uint256 public feeResellerToBuyerETHNumerator;

    /**
     * @notice Emitted when a new treasury is set.
     *
     * @param treasury The treasury address.
     */
    event TreasurySet(
        address indexed treasury
    );

    /**
     * @notice Emitted when a new feeCreatorToBuyerTokenNumerator is set.
     *
     * @param feeCreatorToBuyerTokenNumerator The feeCreatorToBuyerTokenNumerator value.
     */
    event FeeCreatorToBuyerTokenNumeratorSet(
        uint256 indexed feeCreatorToBuyerTokenNumerator
    );

    /**
     * @notice Emitted when a new feeResellerToBuyerTokenNumerator is set.
     *
     * @param feeResellerToBuyerTokenNumerator The feeResellerToBuyerTokenNumerator value.
     */
    event FeeResellerToBuyerTokenNumeratorSet(
        uint256 indexed feeResellerToBuyerTokenNumerator
    );

    /**
     * @notice Emitted when a new feeCreatorToBuyerETHNumerator is set.
     *
     * @param feeCreatorToBuyerETHNumerator The feeCreatorToBuyerETHNumerator value.
     */
    event FeeCreatorToBuyerETHNumeratorSet(
        uint256 indexed feeCreatorToBuyerETHNumerator
    );

    /**
     * @notice Emitted whepaidToAuctioneern a new feeResellerToBuyerETHNumerator is set.
     *
     * @param feeResellerToBuyerETHNumerator The feeResellerToBuyerETHNumerator value.
     */
    event FeeResellerToBuyerETHNumeratorSet(
        uint256 indexed feeResellerToBuyerETHNumerator
    );

    /**
     * @notice Emitted when a new auction is created.
     *
     * @param nftId The NFT ID of the token to auction.
     * @param auctioneer The creator.
     * @param startPrice The auction's starting price.
     * @param priceToken The token of startPrice or 0 for ether.
     */
    event AuctionCreated(
        uint256 indexed nftId,
        address indexed auctioneer,
        uint256 startPrice,
        address priceToken
    );

    /**
     * @notice Emitted when a royalty paid to an author.
     *
     * @param nftId The NFT ID of the token to auction.
     * @param author The author.
     * @param amount The royalty amount.
     * @param amountToken The token of royalty amount or 0 for ether.
     */
    event RoyaltyPaid(
        uint256 indexed nftId,
        address indexed author,
        uint256 amount,
        address amountToken
    );

    /**
     * @notice Emitted when fee is paid to treasury.
     *
     * @param nftId The NFT ID of the token to auction.
     * @param payer The payer.
     * @param feeAmount The fee amount.
     * @param amountToken The token of amount or 0 for ether.
     */
    event FeePaid(
        uint256 indexed nftId,
        address indexed payer,
        uint256 feeAmount,
        address amountToken
    );

    /**
     * @notice Emitted when an auction is canceled.
     *
     * @param nftId The NFT ID of the token to auction.
     * @param canceler Who canceled the auction.
     */
    event AuctionCanceled(
        uint256 indexed nftId,
        address indexed canceler
    );

    /**
     * @notice Emitted when a new auction params are set.
     *
     * @param minPriceStepNumerator.
     */
    event MinPriceStepNumeratorSet(
        uint256 minPriceStepNumerator
    );

    /**
     * @notice Emitted when a new auction params are set.
     *
     * @param auctionDuration.
     */
    event AuctionDurationSet(
        uint256 auctionDuration
    );

    /**
     * @notice Emitted when a new auction params are set.
     *
     * @param overtimeWindow.
     */
    event OvertimeWindowSet(
        uint256 overtimeWindow
    );

    /**
     * @notice Emitted when a new auction params are set.
     *
     * @param authorRoyaltyNumerator.
     */
    event AuthorRoyaltyNumeratorSet(
        uint256 authorRoyaltyNumerator
    );

    /**
     * @notice Emitted when a new bid or outbid is created on a given NFT.
     *
     * @param nftId The NFT ID of the token bid on.
     * @param bidder The bidder address.
     * @param amount The amount used to bid.
     * @param amountToken The token of amount bid or 0 for ether.
     * @param endTimestamp The new end timestamp.
     */
    event BidSubmitted(
        uint256 indexed nftId,
        address indexed bidder,
        uint256 amount,
        address amountToken,
        uint256 endTimestamp
    );

    /**
     * @notice Emitted when an NFT is won and claimed.
     *
     * @param nftId The NFT ID of the token claimed.
     * @param winner The winner of the NFT.
     * @param claimCaller Who called the claim method.
     * @param wonBidAmount The total bid amount.
     * @param paidToAuctioneer How much tokens are paid to auctioneer (excluding fee and royalty).
     */
    event WonNftClaimed(
        uint256 indexed nftId,
        address indexed winner,
        address claimCaller,
        uint256 wonBidAmount,
        uint256 paidToAuctioneer
    );

    /**
     * @notice Emitted when auction reserve price changed.
     *
     * @param nftId The NFT ID of the token changed.
     * @param startPrice The new reserve price.
     * @param startPriceToken The token of start price or 0 for ether.
     * @param reservePriceChanger The caller of the method.
     */
    event ReservePriceChanged(
        uint256 indexed nftId,
        uint256 startPrice,
        address startPriceToken,
        address indexed reservePriceChanger
    );

    function getPaused() external view returns(bool) {
        return _paused;
    }

    /**
     * @dev Initializes the contract.
     *
     * @param _overtimeWindow The overtime window,
     * triggers on bid `endTimestamp := max(endTimestamp, bid.timestamp + overtimeWindow)`
     * @param _auctionDuration The minimum auction duration.  (e.g. 24*3600)
     * @param _minStepNumerator The minimum auction price step. (e.g. 500 ~ 5% see `DENOMINATOR`)
     * @param _payableToken The address of payable token.
     * @param _nft Only one NFT is allowed.
     * @param _ownerAddress The owner address to set, allows pausing and editing settings.
     * @param _treasury The address of treasury.
     * @param _feeCreatorToBuyerTokenNumerator fee for token auctions.
     * @param _feeResellerToBuyerTokenNumerator fee for token auctions.
     * @param _feeCreatorToBuyerETHNumerator fee for ETH auctions.
     * @param _feeResellerToBuyerETHNumerator fee for ETH auctions.
     */
    function initialize(
        uint256 _overtimeWindow,
        uint256 _auctionDuration,
        uint256 _minStepNumerator,
        uint256 _authorRoyaltyNumerator,
        address _payableToken,
        address _nft,
        address _ownerAddress,
        address _treasury,
        uint256 _feeCreatorToBuyerTokenNumerator,
        uint256 _feeResellerToBuyerTokenNumerator,
        uint256 _feeCreatorToBuyerETHNumerator,
        uint256 _feeResellerToBuyerETHNumerator
    ) external initializer {
        require(
            _ownerAddress != address(0),
            Errors.ZERO_ADDRESS
        );
        require(
            _payableToken != address(0),
            Errors.ZERO_ADDRESS
        );
        require(
            _nft != address(0),
            Errors.ZERO_ADDRESS
        );
        require(
            _treasury != address(0),
            Errors.ZERO_ADDRESS
        );
        _transferOwnership(_ownerAddress);
        payableToken = IERC20(_payableToken);
        nft = IERC721(_nft);
        treasury = _treasury;
        setAuctionDuration(_auctionDuration);
        setOvertimeWindow(_overtimeWindow);
        setMinPriceStepNumerator(_minStepNumerator);
        setAuthorRoyaltyNumerator(_authorRoyaltyNumerator);
        setFeeCreatorToBuyerTokenNumerator(_feeCreatorToBuyerTokenNumerator);
        setFeeResellerToBuyerTokenNumerator(_feeResellerToBuyerTokenNumerator);
        setFeeCreatorToBuyerETHNumerator(_feeCreatorToBuyerETHNumerator);
        setFeeResellerToBuyerETHNumerator(_feeResellerToBuyerETHNumerator);
    }

    /**
     * @dev Owner function to set new treasury address.
     *
     * @param treasuryAddress The new treasury address.
     */
    function setTreasury(address treasuryAddress) external onlyOwner {
        require(
            treasuryAddress != address(0),
            Errors.ZERO_ADDRESS
        );
        treasury = treasuryAddress;
        emit TreasurySet(treasuryAddress);
    }

    /**
     * @dev Owner function to change the auction duration.
     *
     * @param newAuctionDuration The new minimum auction duration to set.
     */
    function setAuctionDuration(uint256 newAuctionDuration) public onlyOwner {
        require(newAuctionDuration >= MIN_AUCTION_DURATION && newAuctionDuration <= MAX_AUCTION_DURATION,
            Errors.INVALID_AUCTION_PARAMS);
        auctionDuration = newAuctionDuration;
        emit AuctionDurationSet(newAuctionDuration);
    }

    /**
     * @dev Owner function to set the auction overtime window.
     *
     * @param newOvertimeWindow The new overtime window to set.
     */
    function setOvertimeWindow(uint256 newOvertimeWindow) public onlyOwner {
        require(newOvertimeWindow >= MIN_OVERTIME_WINDOW && newOvertimeWindow <= MAX_OVERTIME_WINDOW,
            Errors.INVALID_AUCTION_PARAMS);
        overtimeWindow = newOvertimeWindow;
        emit OvertimeWindowSet(newOvertimeWindow);
    }

    /**
     * @dev Owner function to set the auction price step numerator.
     *
     * @param newMinPriceStepNumerator The new overtime window to set.
     */
    function setMinPriceStepNumerator(uint256 newMinPriceStepNumerator) public onlyOwner {
        require(newMinPriceStepNumerator >= MIN_MIN_PRICE_STEP_NUMERATOR &&
                newMinPriceStepNumerator <= MAX_MIN_PRICE_STEP_NUMERATOR,
            Errors.INVALID_AUCTION_PARAMS);
        minPriceStepNumerator = newMinPriceStepNumerator;
        emit MinPriceStepNumeratorSet(newMinPriceStepNumerator);
    }

    /**
     * @dev Owner function to set author royalty numerator.
     *
     * @param newAuthorRoyaltyNumerator The new overtime window to set.
     */
    function setAuthorRoyaltyNumerator(uint256 newAuthorRoyaltyNumerator) public onlyOwner {
        require(newAuthorRoyaltyNumerator <= DENOMINATOR, Errors.INVALID_AUCTION_PARAMS);
        authorRoyaltyNumerator = newAuthorRoyaltyNumerator;
        emit AuthorRoyaltyNumeratorSet(newAuthorRoyaltyNumerator);
    }

    /**
     * @dev Owner function to set setFeeCreatorToBuyerTokenNumerator.
     *
     * @param newFeeCreatorToBuyerTokenNumerator The new value.
     */
    function setFeeCreatorToBuyerTokenNumerator(uint256 newFeeCreatorToBuyerTokenNumerator) public onlyOwner {
        require(newFeeCreatorToBuyerTokenNumerator <= DENOMINATOR, Errors.INVALID_AUCTION_PARAMS);
        feeCreatorToBuyerTokenNumerator = newFeeCreatorToBuyerTokenNumerator;
        emit FeeCreatorToBuyerTokenNumeratorSet(newFeeCreatorToBuyerTokenNumerator);
    }

    /**
     * @dev Owner function to set setFeeResellerToBuyerTokenNumerator.
     *
     * @param newFeeResellerToBuyerTokenNumerator The new value.
     */
    function setFeeResellerToBuyerTokenNumerator(uint256 newFeeResellerToBuyerTokenNumerator) public onlyOwner {
        require(newFeeResellerToBuyerTokenNumerator <= DENOMINATOR, Errors.INVALID_AUCTION_PARAMS);
        feeResellerToBuyerTokenNumerator = newFeeResellerToBuyerTokenNumerator;
        emit FeeResellerToBuyerTokenNumeratorSet(newFeeResellerToBuyerTokenNumerator);
    }

    /**
     * @dev Owner function to set setFeeCreatorToBuyerETHNumerator.
     *
     * @param newFeeCreatorToBuyerETHNumerator The new value.
     */
    function setFeeCreatorToBuyerETHNumerator(uint256 newFeeCreatorToBuyerETHNumerator) public onlyOwner {
        require(newFeeCreatorToBuyerETHNumerator <= DENOMINATOR, Errors.INVALID_AUCTION_PARAMS);
        feeCreatorToBuyerETHNumerator = newFeeCreatorToBuyerETHNumerator;
        emit FeeCreatorToBuyerETHNumeratorSet(newFeeCreatorToBuyerETHNumerator);
    }

    /**
     * @dev Owner function to set setFeeResellerToBuyerETHNumerator.
     *
     * @param newFeeResellerToBuyerETHNumerator The new value.
     */
    function setFeeResellerToBuyerETHNumerator(uint256 newFeeResellerToBuyerETHNumerator) public onlyOwner {
        require(newFeeResellerToBuyerETHNumerator <= DENOMINATOR, Errors.INVALID_AUCTION_PARAMS);
        feeResellerToBuyerETHNumerator = newFeeResellerToBuyerETHNumerator;
        emit FeeResellerToBuyerETHNumeratorSet(newFeeResellerToBuyerETHNumerator);
    }

    /**
     * @dev Create new auction.
     *
     * @param nftId Id of NFT token for the auction (must be approved for transfer by Auction smart-contract).
     * @param startPrice Minimum price for the first bid in ether or tokens depending on isEtherPrice value.
     * @param isEtherPrice True to create auction in ether, false to create auction in payableToken.
     */
    function createAuction(
        uint256 nftId,
        uint256 startPrice,
        bool isEtherPrice
    ) external nonReentrant whenNotPaused {
        require(_nftId2auction[nftId].auctioneer == address(0), Errors.AUCTION_EXISTS);
        require(startPrice > 0, Errors.INVALID_AUCTION_PARAMS);
        address token = isEtherPrice ? address(0) : address(payableToken);
        DataTypes.AuctionData memory auctionData = DataTypes.AuctionData(
            startPrice,
            token,
            msg.sender,
            address(0),  // bidder
            0  // endTimestamp
        );
        _nftId2auction[nftId] = auctionData;
        IERC721(nft).transferFrom(msg.sender, address(this), nftId);  // maybe use safeTransferFrom
        emit AuctionCreated(nftId, msg.sender, startPrice, token);
    }

    /**
     * @notice Claims a won NFT after an auction. Can be called by anyone.
     *
     * @param nftId The NFT ID of the token to claim.
     */
    function claimWonNFT(uint256 nftId) external nonReentrant whenNotPaused {
        DataTypes.AuctionData storage auction = _nftId2auction[nftId];

        address auctioneer = auction.auctioneer;
        address winner = auction.currentBidder;
        uint256 endTimestamp = auction.endTimestamp;
        uint256 currentBid = auction.currentBid;
        uint256 payToAuctioneer = currentBid;
        address bidToken = auction.bidToken;

        require(block.timestamp > endTimestamp, Errors.AUCTION_NOT_FINISHED);
        require(winner != address(0), Errors.EMPTY_WINNER);  // auction does not exist or did not start, no bid
        require((msg.sender == auctioneer) || (msg.sender == winner) || (msg.sender == owner()), Errors.NO_RIGHTS);
        delete _nftId2auction[nftId];  // storage change before external calls

        // warning: will not work for usual erc721
        address author = IERC721TokenAuthor(address(nft)).tokenAuthor(nftId);
        if (author != auctioneer) {  // pay royalty
            uint256 payToAuthor = currentBid * authorRoyaltyNumerator / DENOMINATOR;
            payToAuctioneer -= payToAuthor;
            emit RoyaltyPaid(nftId, author, payToAuthor, bidToken);
            if (bidToken == address(0)) {  // eth
                payable(author).transfer(payToAuthor);
            } else {  // erc20
                payableToken.safeTransfer(author, payToAuthor);
            }
            // note: as the result of this mechanism, there is one contr-intuitive consequence:
            //   creator receives the discount on buying back his created NFT.
            //   New nft holder must be informed that he will not receive 100%
            //   of money from his auction because of the roylaty
        }

        if (bidToken == address(0)) {  // eth
            uint256 fee = 0;
            if (author == auctioneer) {  // creatorToBuyer
                fee = payToAuctioneer * uint256(feeCreatorToBuyerETHNumerator) / uint256(DENOMINATOR);
            } else {  // resellerToBuyer
                fee = payToAuctioneer * uint256(feeResellerToBuyerETHNumerator) / uint256(DENOMINATOR);
            }
            if (fee > 0) {
                payToAuctioneer -= fee;
                payable(treasury).transfer(fee);
            }
            emit FeePaid({
                nftId: nftId,
                payer: winner,
                feeAmount: fee,
                amountToken: address(0)
            });
            emit WonNftClaimed(nftId, winner, msg.sender, currentBid, payToAuctioneer);
            payable(auctioneer).transfer(payToAuctioneer);
        } else {  //erc20
            uint256 fee = 0;
            if (author == auctioneer) {  // creatorToBuyer
                fee = payToAuctioneer * uint256(feeCreatorToBuyerTokenNumerator) / uint256(DENOMINATOR);
            } else {  // resellerToBuyer
                fee = payToAuctioneer * uint256(feeResellerToBuyerTokenNumerator) / uint256(DENOMINATOR);
            }
            if (fee > 0) {
                payToAuctioneer -= fee;
                payableToken.safeTransfer(treasury, fee);
            }
            emit FeePaid({
                nftId: nftId,
                payer: winner,
                feeAmount: fee,
                amountToken: address(payableToken)
            });
            emit WonNftClaimed(nftId, winner, msg.sender, currentBid, payToAuctioneer);
            payableToken.safeTransfer(auctioneer, payToAuctioneer);
        }
        // sine we use the only one nft, we don't need to call safeTransferFrom
        IERC721(nft).transferFrom(address(this), winner, nftId);
    }

    /**
     * @notice Returns the auction data for a given NFT.
     *
     * @param nftId The NFT ID to query.
     *
     * @return The AuctionData containing all data related to a given NFT.
     */
    function getAuctionData(uint256 nftId) external view returns (DataTypes.AuctionData memory) {
        DataTypes.AuctionData memory auction = _nftId2auction[nftId];
        require(auction.auctioneer != address(0), Errors.AUCTION_NOT_EXISTS);
        return auction;
    }

    /**
     * @notice Cancel an auction. Can be called by the auctioneer or by the owner.
     *
     * @param nftId The NFT ID of the token to cancel.
     */
    function cancelAuction(
        uint256 nftId
    ) external whenNotPaused nonReentrant {
        DataTypes.AuctionData memory auction = _nftId2auction[nftId];
        require(
            auction.auctioneer != address(0),
            Errors.AUCTION_NOT_EXISTS
        );
        require(
            msg.sender == auction.auctioneer || msg.sender == owner(),
            Errors.NO_RIGHTS
        );
        require(
            auction.currentBidder == address(0),
            Errors.AUCTION_ALREADY_STARTED
        );  // auction can't be canceled if someone placed a bid.
        delete _nftId2auction[nftId];
        emit AuctionCanceled(nftId, msg.sender);
        // maybe use safeTransfer (I don't want unclear onERC721Received stuff)
        IERC721(nft).transferFrom(address(this), auction.auctioneer, nftId);
    }

    /**
     * @notice Change the reserve price (minimum price) of the auction.
     *
     * @param nftId The NFT ID of the token.
     * @param startPrice New start price in tokens or ether depending on auction type.
     * @param isEtherPrice Should the bidToken be ETH or ERC20.
     */
    function changeReservePrice(
        uint256 nftId,
        uint256 startPrice,
        bool isEtherPrice
    ) external whenNotPaused nonReentrant {
        DataTypes.AuctionData memory auction = _nftId2auction[nftId];
        require(
            auction.auctioneer != address(0),
            Errors.AUCTION_NOT_EXISTS
        );
        require(
            msg.sender == auction.auctioneer || msg.sender == owner(),
            Errors.NO_RIGHTS
        );
        require(
            auction.currentBidder == address(0),
            Errors.AUCTION_ALREADY_STARTED
        );  // auction can't be canceled if someone placed a bid.
        require(
            startPrice > 0,
            Errors.INVALID_AUCTION_PARAMS
        );
        address bidToken = isEtherPrice ? address(0) : address(payableToken);
        _nftId2auction[nftId].currentBid = startPrice;
        _nftId2auction[nftId].bidToken = bidToken;
        emit ReservePriceChanged({
            nftId: nftId,
            startPrice: startPrice,
            startPriceToken: bidToken,
            reservePriceChanger: msg.sender
        });
    }

    /**
     * @notice Place the bid in ERC20 tokens.
     *
     * @param nftId The NFT ID of the token.
     * @param amount Bid amount in ERC20 tokens.
     */
    function bid(
        uint256 nftId,
        uint256 amount
    ) external whenNotPaused nonReentrant {
        _bid(nftId, amount, address(payableToken));
    }

    /**
     * @notice Place the bid in ETH.
     *
     * @param nftId The NFT ID of the token.
     * @param amount Bid amount in ETH.
     */
    function bidEther(
        uint256 nftId,
        uint256 amount
    ) external payable whenNotPaused nonReentrant {
        _bid(nftId, amount, address(0));
    }

    /**
     * @notice Place the bid.
     *
     * @param nftId The NFT id.
     * @param amount Bid amount.
     */
    function _bid(
        uint256 nftId,
        uint256 amount,
        address auctionToken
    ) internal {
        DataTypes.AuctionData storage auction = _nftId2auction[nftId];
        require(auction.auctioneer != address(0), Errors.AUCTION_NOT_EXISTS);
        uint256 currentBid = auction.currentBid;
        address currentBidder = auction.currentBidder;
        uint256 endTimestamp = auction.endTimestamp;

        if (auctionToken != address(0)){  // erc20
            require(
                auction.bidToken == auctionToken,
                Errors.CANT_BID_ETHER_AUCTION_BY_TOKENS
            );
        } else {  // eth
            require(
                auction.bidToken == address(0),
                Errors.CANT_BID_TOKEN_AUCTION_BY_ETHER
            );
        }

        require(
            block.timestamp < endTimestamp || // already finished
            endTimestamp == 0,  // or not started
            Errors.AUCTION_FINISHED
        );

        uint256 newEndTimestamp = auction.endTimestamp;
        if (endTimestamp == 0) { // first bid
            require(amount >= currentBid, Errors.SMALL_BID_AMOUNT);  // >= startPrice stored in currentBid
            newEndTimestamp = block.timestamp + auctionDuration;
            auction.endTimestamp = newEndTimestamp;
        } else {
            require(amount >= (DENOMINATOR + minPriceStepNumerator) * currentBid / DENOMINATOR,
                Errors.SMALL_BID_AMOUNT);  // >= step over the previous bid
            if (block.timestamp > endTimestamp - overtimeWindow) {
                newEndTimestamp = block.timestamp + overtimeWindow;
                auction.endTimestamp = newEndTimestamp;
            }
        }

        auction.currentBidder = msg.sender;
        auction.currentBid = amount;

        // emit here to avoid reentry events mis-ordering
        emit BidSubmitted(nftId, msg.sender, amount, auction.bidToken, newEndTimestamp);

        if (auctionToken != address(0)){  // erc20
            if (currentBidder != msg.sender) {
                if (currentBidder != address(0)) {
                     payableToken.safeTransfer(currentBidder, currentBid);
                }
                payableToken.safeTransferFrom(msg.sender, address(this), amount);
            } else {
                uint256 more = amount - currentBid;
                payableToken.safeTransferFrom(msg.sender, address(this), more);
            }
        } else {  // eth
            if (currentBidder != msg.sender) {
                require(msg.value == amount, Errors.INVALID_ETHER_AMOUNT);
                if (currentBidder != address(0)) {
                    payable(currentBidder).transfer(currentBid);
                }
            } else {
                uint256 more = amount - currentBid;
                require(msg.value == more, Errors.INVALID_ETHER_AMOUNT);
            }
        }
    }

    uint256[50] private __gap;
}
