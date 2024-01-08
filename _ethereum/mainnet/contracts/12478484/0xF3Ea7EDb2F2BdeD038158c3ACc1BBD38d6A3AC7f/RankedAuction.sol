// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC20Permit.sol";
import "./AdminPausableUpgradeSafe.sol";
import "./WETHBase.sol";
import "./VersionedInitializable.sol";
import "./DataTypes.sol";
import "./Errors.sol";

/**
 * @title RankedAuction contract.
 * @author Aito
 *
 * @notice A simple auction contract that just stores bids and relies on an external entity to manage the auctioning
 * logic.
 */
contract RankedAuction is
    VersionedInitializable,
    AdminPausableUpgradeSafe,
    WETHBase,
    ReentrancyGuard
{
    using SafeERC20 for IERC20Permit;
    using SafeMath for uint256;

    uint256 public constant RANKEDAUCTION_REVISION = 0x1;

    mapping(uint256 => DataTypes.RankedAuctionData) internal _auctionsById;
    mapping(address => mapping(uint256 => uint256)) internal _bids;
    mapping(address => mapping(uint256 => bool)) internal _outbid;
    mapping(address => bool) internal _currencyWhitelisted;

    uint256 internal _auctionCounter;
    uint40 internal _overtimeWindow;

    /**
     * @notice Emitted upon contract initialization.
     *
     * @param weth The WETH address whitelisted.
     * @param overtimeWindow The overtime window set.
     */
    event Initialized(address weth, uint256 overtimeWindow);

    /**
     * @notice Emitted when a new bid is placed or when an account's bid is increased.
     *
     * @param auctionId The auction identifier.
     * @param bidder The bidder address.
     * @param spender The address spending currency.
     * @param amount The bid amount.
     */
    event BidSubmitted(uint256 indexed auctionId, address bidder, address spender, uint256 amount);

    /**
     * @notice Emitted when the minimum price is updated by the admin.
     *
     * @param auctionId The auction identifier.
     * @param minimumPrice The auction's new minimum price.
     */
    event MinimumPriceUpdated(uint256 indexed auctionId, uint256 minimumPrice);

    /**
     * @notice Emitted when an outbid bid is withdrawn.
     *
     * @param auctionId The auction identifier.
     * @param bidder The address of the bidder who withdrew.
     * @param amount The amount withdrew.
     */
    event BidWithdrew(uint256 indexed auctionId, address indexed bidder, uint256 indexed amount);

    /**
     * @notice Emitted when an auction is created.
     *
     * @param auctionId The auction identifier.
     * @param currency The auction's underlying bid currency.
     * @param minPrice The minimum starting price of the auction.
     * @param maxWinners The expected maximum amount of NFT winners.
     * @param recipient The funds recipient.
     * @param startTimestamp The starting timestamp.
     * @param endTimestamp The ending timestamp.
     */
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed currency,
        uint256 indexed minPrice,
        uint256 maxWinners,
        address recipient,
        uint40 startTimestamp,
        uint40 endTimestamp
    );

    /**
     * @notice Emitted when funds are received by the recipient.
     *
     * @param auctionId The auction identifier.
     * @param recipient The recipient address.
     * @param amount The amount received.
     */
    event FundsReceived(
        uint256 indexed auctionId,
        address indexed recipient,
        address[] bidders,
        uint256 amount
    );

    /**
     * @notice Emitted when a currency is whitelisted.
     *
     * @param currency The newly whitelisted currency.
     */
    event CurrencyWhitelisted(address currency);

    /**
     * @notice Emitted when a currency is removed from the whitelist.
     *
     * @param currency The newly unwhitelisted currency.
     */
    event CurrencyUnwhitelisted(address currency);

    /**
     * @notice Emitted when user bids are manually marked as outbid. Used as a backup
     * when there are multiple bids of the same price.
     *
     * @param auctionId The auction identifier.
     * @param bidders The array of bidders outbid.
     */
    event UsersOutbid(uint256 indexed auctionId, address[] bidders);

    /**
     * @notice Constructor sets the immutable WETH address.
     *
     * @param weth The WETH address.
     */
    constructor(address weth) WETHBase(weth) {}

    /**
     * @notice Initializes the contract.
     *
     * @param admin The admin address to set.
     * @param overtimeWindow The overtime window to set.
     */
    function initialize(address admin, uint40 overtimeWindow) external initializer {
        require(admin != address(0) && overtimeWindow < 2 days, Errors.INVALID_INIT_PARAMS);
        _admin = admin;
        _overtimeWindow = overtimeWindow;
        _currencyWhitelisted[address(WETH)] = true;
        _paused = false;

        emit Initialized(address(WETH), overtimeWindow);
    }

    /**
     * @notice Creates a new auction, only available to the admin.
     *
     * @param maxWinners The total amount of winners expected, must be emitted.
     * @param minPrice The starting minimum price for the auction.
     * @param currency The currency to be used in the auction.
     * @param recipient The address to receive proceeds from the auction.
     * @param startTimestamp The starting timestamp for the auction.
     * @param endTimestamp The ending timestamp for the auction.
     */
    function createAuction(
        uint256 maxWinners,
        address currency,
        uint256 minPrice,
        address recipient,
        uint40 startTimestamp,
        uint40 endTimestamp
    ) external nonReentrant onlyAdmin whenNotPaused {
        require(recipient != address(0), Errors.ZERO_RECIPIENT);
        require(currency != address(0), Errors.ZERO_CURRENCY);
        require(_currencyWhitelisted[currency], Errors.CURRENCY_NOT_WHITELSITED);
        require(
            startTimestamp > block.timestamp && endTimestamp > startTimestamp,
            Errors.INVALID_AUCTION_TIMESTAMPS
        );
        DataTypes.RankedAuctionData storage auction = _auctionsById[_auctionCounter];
        auction.minPrice = minPrice;
        auction.recipient = recipient;
        auction.currency = currency;
        auction.startTimestamp = startTimestamp;
        auction.endTimestamp = endTimestamp;

        emit AuctionCreated(
            _auctionCounter++,
            currency,
            minPrice,
            maxWinners,
            recipient,
            startTimestamp,
            endTimestamp
        );
    }

    /**
     * @notice Bids on the auction.
     *
     * @param auctionId The auction identifier.
     * @param onBehalfOf The address to bid on behalf of.
     * @param amount The amount to bid.
     */
    function bid(
        uint256 auctionId,
        address onBehalfOf,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        _bid(auctionId, msg.sender, onBehalfOf, amount);
    }

    /**
     * @notice Bids bypassing an 'approval' transaction by bundling the bid with a permit on the underlying asset.
     *
     * @param auctionId The auction identifier.
     * @param params The parameters containing the necessary data to execute the 'permit' and the 'bid.'
     */
    function bidWithPermit(uint256 auctionId, DataTypes.SimpleBidWithPermitParams calldata params)
        external
        nonReentrant
        whenNotPaused
    {
        IERC20Permit currency = IERC20Permit(_auctionsById[auctionId].currency);
        currency.permit(
            msg.sender,
            address(this),
            params.amount,
            params.deadline,
            params.v,
            params.r,
            params.s
        );
        _bid(auctionId, msg.sender, params.onBehalfOf, params.amount);
    }

    /**
     * @dev Sets the minimum price for new bids, allowing lower bids to withdraw.
     *
     * @param auctionId The auction identifier.
     * @param newMinimum New minimum bid price.
     */
    function updateMinimumPrice(uint256 auctionId, uint256 newMinimum)
        external
        nonReentrant
        onlyAdmin
    {
        _auctionsById[auctionId].minPrice = newMinimum;

        emit MinimumPriceUpdated(auctionId, newMinimum);
    }

    /**
     * @dev Sets user bids as manually outbid, in case bids are placed at the same price, causing the
     * minimum price to not allow users to withdraw their bids.
     *
     * @param auctionId The auction identifier.
     * @param toOutbid The array of addresses to mark as outbid.
     */
    function setOutbid(uint256 auctionId, address[] calldata toOutbid)
        external
        nonReentrant
        onlyAdmin
    {
        for (uint256 i = 0; i < toOutbid.length; i++) {
            require(_bids[toOutbid[i]][auctionId] > 0, Errors.INVALID_BID_AMOUNT);
            _outbid[toOutbid[i]][auctionId] = true;
        }

        emit UsersOutbid(auctionId, toOutbid);
    }

    /**
     * @notice Withdraws the caller's bid if it is outbid.
     *
     * @param auctionId The auction identifier.
     */
    function withdrawBid(uint256 auctionId) external nonReentrant whenNotPaused {
        DataTypes.RankedAuctionData storage auction = _auctionsById[auctionId];
        uint256 returnAmount = _bids[msg.sender][auctionId];
        require(
            (returnAmount > 0 && returnAmount < auction.minPrice) || _outbid[msg.sender][auctionId],
            Errors.RA_NOT_OUTBID
        );
        IERC20Permit currency = IERC20Permit(auction.currency);
        delete (_bids[msg.sender][auctionId]);
        delete (_outbid[msg.sender][auctionId]);

        if (address(currency) == address(WETH)) {
            WETH.withdraw(returnAmount);
            (bool success, ) = msg.sender.call{value: returnAmount}(new bytes(0));
            if (!success) {
                WETH.deposit{value: returnAmount}();
                IERC20Permit(address(WETH)).safeTransferFrom(
                    address(this),
                    msg.sender,
                    returnAmount
                );
            }
        } else {
            currency.safeTransfer(msg.sender, returnAmount);
        }

        emit BidWithdrew(auctionId, msg.sender, returnAmount);
    }

    /**
     * @notice Transfers the funds from winning bids to the recipient address.
     *
     * @param auctionId The auction identifier.
     * @param toReceive winning bid addresses to transfer bid amounts from.
     */
    function receiveFunds(uint256 auctionId, address[] calldata toReceive)
        external
        nonReentrant
        onlyAdmin
    {
        DataTypes.RankedAuctionData storage auction = _auctionsById[auctionId];
        uint256 endTimestamp = auction.endTimestamp;
        uint256 minPrice = auction.minPrice;
        uint256 amountToTransfer;
        address recipient = auction.recipient;
        IERC20Permit currency = IERC20Permit(auction.currency);
        require(block.timestamp > endTimestamp, Errors.INVALID_AUCTION_TIMESTAMPS);

        for (uint256 i = 0; i < toReceive.length; i++) {
            require(!_outbid[toReceive[i]][auctionId], Errors.RA_OUTBID);
            uint256 bidAmount = _bids[toReceive[i]][auctionId];
            require(bidAmount >= minPrice, Errors.RA_OUTBID);
            amountToTransfer = amountToTransfer.add(bidAmount);
            delete (_bids[toReceive[i]][auctionId]);
        }
        currency.safeTransfer(recipient, amountToTransfer);

        emit FundsReceived(auctionId, recipient, toReceive, amountToTransfer);
    }

    /**
     * @dev Admin function to whitelist a currency.
     *
     * @param toWhitelist The currency address to whitelist.
     */
    function whitelistCurrency(address toWhitelist) external onlyAdmin {
        _currencyWhitelisted[toWhitelist] = true;
        emit CurrencyWhitelisted(toWhitelist);
    }

    /**
     * @dev Admin function to remove a whitelisted currency.
     *
     * @param toRemove The currency address to remove from the whitelist.
     */
    function removeCurrencyFromWhitelist(address toRemove) external onlyAdmin {
        _currencyWhitelisted[toRemove] = false;
        emit CurrencyUnwhitelisted(toRemove);
    }

    /**
     * @dev transfer native Ether, for native Ether recovery in case of stuck Ether
     * due selfdestructs or transfer ether to pre-computated contract address before deployment.
     *
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyEtherTransfer(address to, uint256 amount) external onlyAdmin {
        _safeTransferETH(to, amount);
    }

    /**
     * @notice Returns the auction data for a given auction ID.
     *
     * @return The RankedAuctionData struct containing the auction's parameters.
     */
    function getAuctionData(uint256 auctionId)
        external
        view
        returns (DataTypes.RankedAuctionData memory)
    {
        return _auctionsById[auctionId];
    }

    /**
     * @notice Returns a specific bid data query.
     *
     * @param bidder The bidder to query the bid for.
     * @param auctionId The auction ID to query the bid for.
     */
    function getBid(address bidder, uint256 auctionId) external view returns (uint256) {
        return _bids[bidder][auctionId];
    }

    /**
     * @notice Returns the overtime window.
     *
     * @return The overtime window.
     */
    function getOvertimeWindow() external view returns (uint256) {
        return _overtimeWindow;
    }

    /**
     * @notice Returns whether a currency address is whitelisted and allowed to be used in the auction.
     *
     * @param query The address to query.
     */
    function isWhitelisted(address query) external view returns (bool) {
        return _currencyWhitelisted[query];
    }

    /**
     * @dev Internal function executes the underlying logic of a bid.
     *
     * @param auctionId The auction identifier.
     * @param spender The spender to transfer currency from.
     * @param onBehalfOf The address to bid on behalf of.
     * @param amount The amount to bid with.
     */
    function _bid(
        uint256 auctionId,
        address spender,
        address onBehalfOf,
        uint256 amount
    ) internal {
        DataTypes.RankedAuctionData storage auction = _auctionsById[auctionId];
        uint256 minPrice = auction.minPrice;
        IERC20Permit currency = IERC20Permit(auction.currency);
        uint40 startTimestamp = auction.startTimestamp;
        uint40 endTimestamp = auction.endTimestamp;
        require(onBehalfOf != address(0), Errors.INVALID_BIDDER);
        require(amount > minPrice, Errors.INVALID_BID_AMOUNT);
        require(
            block.timestamp > startTimestamp && block.timestamp < endTimestamp,
            Errors.INVALID_BID_TIMESTAMPS
        );
        if (_overtimeWindow > 0 && block.timestamp > endTimestamp - _overtimeWindow) {
            endTimestamp = endTimestamp + _overtimeWindow;
        }

        uint256 previousBid = _bids[onBehalfOf][auctionId];
        _bids[onBehalfOf][auctionId] = amount;
        if (amount > previousBid) {
            currency.safeTransferFrom(spender, address(this), amount - previousBid);
        } else {
            revert(Errors.INVALID_BID_AMOUNT);
        }

        emit BidSubmitted(auctionId, onBehalfOf, spender, amount);
    }

    function getRevision() internal pure override returns (uint256) {
        return RANKEDAUCTION_REVISION;
    }

    receive() external payable {
        require(msg.sender == address(WETH));
    }
}
