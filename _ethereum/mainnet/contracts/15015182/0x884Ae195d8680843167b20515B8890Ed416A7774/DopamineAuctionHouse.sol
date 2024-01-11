// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// DoapmineAuctionHouse is a modification of Nouns DAO's NounsAuctionHouse.sol:
/// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
/// Copyright licensing is under the GPL-3.0 license, as the above contract
/// is itself a modification of Zora's Auction House (GPL-3.0 licensed).
///
/// The following major changes were made from the original Nouns DAO contract:
/// - `SettleCurrentAndCreateNewAuction()` and `SettleAuction()` were unified
///   into a single `SettleAuction()` function that can be called, paused or not
/// - Auctions begin with `auction.settled = true` to make settlements simpler
/// - The semantics around pausing vs. unpausing were changed to orient around
///   suspension of NEW auctions (pausing has no effect on the current auction)
/// - `AuctionCreationFailed` event added to indicate failed auction creation
/// - Proxy was changed from OZ's TransparentUpgradeableProxy to OZ's UUPS proxy
/// - Support for WETH as a fallback for failed ETH refunds was removed
/// - Support for splitting auction revenue with another address was added
/// - Failed ETH refunds now emit `RefundFailed` events

import "./UUPSUpgradeable.sol";

import "./Errors.sol";
import "./IDopamineAuctionHouse.sol";
import "./IDopamineAuctionHouseToken.sol";
import "./DopamineAuctionHouseStorage.sol";

/// @title Dopamine Auction House Contract
/// @notice The Dopamine auction house contract is an English auctions platform
///  that auctions NFTs of a given collection at `auctionDuration` intervals.
///  This contract specifically configures seasonal emissions for Dopamine tabs.
contract DopamineAuctionHouse is UUPSUpgradeable, DopamineAuctionHouseStorage, IDopamineAuctionHouse {

    /// @notice The min % difference a bidder must bid relative to the last bid.
    uint256 public constant MIN_BID_DIFF = 5;

    /// @notice The minimum time buffer in seconds that can be set for auctions.
    uint256 public constant MIN_AUCTION_BUFFER = 60 seconds;

    /// @notice The maximum time buffer in seconds that can be set for auctions.
    uint256 public constant MAX_AUCTION_BUFFER = 24 hours;

    /// @notice The minimum reserve price in wei that can be set for auctions.
    uint256 public constant MIN_RESERVE_PRICE = 1 wei;

    /// @notice The maximum reserve price in wei that can be set for auctions.
    uint256 public constant MAX_RESERVE_PRICE = 99 ether;

    /// @notice The minimum time period in seconds an auction can run for.
    uint256 public constant MIN_AUCTION_DURATION = 30 minutes;

    /// @notice The maximum time period in seconds an auction can run for.
    uint256 public constant MAX_AUCTION_DURATION = 1 weeks;

    /// @dev Gas-efficient reentrancy & suspension markers marking true / false.
    uint256 private constant _TRUE = 1;
    uint256 private constant _FALSE = 2;

    /// @dev This modifier restrict calls to only the admin.
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert AdminOnly();
        }
        _;
    }

    /// @dev This modifier acts as a reentrancy guard.
    modifier nonReentrant() {
        if (_locked != _FALSE) {
            revert FunctionReentrant();
        }
        _locked = _TRUE;
        _;
        _locked = _FALSE;
    }

    /// @notice Initializes the Dopamine auction house contract.
    /// @param token_ The address of the NFT up for auction.
    /// @param reserve_ Address of the Dopamine reserve.
    /// @param treasury_ Address of the Dopamine treasury.
    /// @param treasurySplit_ Sale % given to `treasury_` (rest to `reserve_`).
    /// @param auctionBuffer_ Time window in seconds auctions may be extended.
    /// @param reservePrice_ The minimum bidding price for auctions in wei.
    /// @param auctionDuration_ How long in seconds an auction may be up for.
    function initialize(
        address token_,
        address payable reserve_,
        address payable treasury_,
        uint256 treasurySplit_,
        uint256 auctionBuffer_,
        uint256 reservePrice_,
        uint256 auctionDuration_
    ) onlyProxy external {
        if (address(token) != address(0)) {
            revert ContractAlreadyInitialized();
        }

        _suspended = _TRUE;
        _locked = _FALSE;

        admin = msg.sender;
        emit AdminChanged(address(0), admin);

        token = IDopamineAuctionHouseToken(token_);
        auction.settled = true;

        setTreasury(treasury_);
        setReserve(reserve_);
        setTreasurySplit(treasurySplit_);
        setAuctionBuffer(auctionBuffer_);
        setReservePrice(reservePrice_);
        setAuctionDuration(auctionDuration_);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function suspended() external view returns (bool) {
        return _suspended == _TRUE;
    }

    /// @inheritdoc IDopamineAuctionHouse
    function suspendNewAuctions() external onlyAdmin {
        if (_suspended == _TRUE) {
            revert AuctionAlreadySuspended();
        }
        _suspended = _TRUE;
        emit AuctionSuspended();
    }

    /// @inheritdoc IDopamineAuctionHouse
    function resumeNewAuctions() external onlyAdmin {

        // This function can only be called if auctions are currently suspended.
        if (_suspended == _FALSE) {
            revert AuctionNotSuspended();
        }

        // Unless auction settles and ensuing creation fails, resume auctions.
        if (!auction.settled || _createAuction()) {
            _suspended = _FALSE;
            emit AuctionResumed();
        }
    }

    /// @inheritdoc IDopamineAuctionHouse
    function settleAuction() external nonReentrant {
        _settleAuction();

        // If auctions are live, create a new auction but suspend under failure.
        if (_suspended != _TRUE && !_createAuction()) {
            _suspended = _TRUE;
            emit AuctionSuspended();
        }
    }

    /// @inheritdoc IDopamineAuctionHouse
    function createBid(uint256 tokenId) external payable nonReentrant {
        if (block.timestamp > auction.endTime) {
            revert AuctionExpired();
        }
        if (auction.tokenId != tokenId) {
            revert AuctionBidInvalid();
        }
        if (
            msg.value < reservePrice ||
            msg.value < auction.amount + ((auction.amount * MIN_BID_DIFF) / 100)
        ) {
            revert AuctionBidTooLow();
        }

        address payable lastBidder = auction.bidder;

        // Emit a `RefundFailed` event if the refund to the last bidder fails.
        // This only happens if the bidder is a contract not accepting payments.
        if (
            lastBidder != address(0) &&
            !_transferETH(lastBidder, auction.amount)
        )
        {
            _transferETH(treasury, auction.amount);
            emit RefundFailed(lastBidder);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend auction if bid is received within `auctionBuffer` of end time.
        bool extended = auction.endTime - block.timestamp < auctionBuffer;
        emit AuctionBid(auction.tokenId, msg.sender, msg.value, extended);

        if (extended) {
            auction.endTime = block.timestamp + auctionBuffer;
            emit AuctionExtended(tokenId, auction.endTime);
        }

    }

    /// @inheritdoc IDopamineAuctionHouse
    function acceptAdmin() public override {
        if (msg.sender != pendingAdmin) {
            revert PendingAdminOnly();
        }

        emit AdminChanged(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setPendingAdmin(address newPendingAdmin) public override onlyAdmin {
        pendingAdmin = newPendingAdmin;
        emit PendingAdminSet(pendingAdmin);
    }


    /// @inheritdoc IDopamineAuctionHouse
    function setTreasury(address payable newTreasury) public onlyAdmin {
        treasury = newTreasury;
        emit TreasurySet(treasury);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setReserve(address payable newReserve) public onlyAdmin {
        reserve = newReserve;
        emit ReserveSet(reserve);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setAuctionDuration(uint256 newAuctionDuration) public onlyAdmin {
        if (
            newAuctionDuration < MIN_AUCTION_DURATION ||
            newAuctionDuration > MAX_AUCTION_DURATION
        ) {
            revert AuctionDurationInvalid();
        }
        auctionDuration = newAuctionDuration;
        emit AuctionDurationSet(auctionDuration);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setTreasurySplit(uint256 newTreasurySplit)
        public override onlyAdmin
    {
        if (newTreasurySplit > 100) {
            revert AuctionTreasurySplitInvalid();
        }
        treasurySplit = newTreasurySplit;
        emit AuctionTreasurySplitSet(treasurySplit);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setAuctionBuffer(uint256 newAuctionBuffer)
        public
        override
        onlyAdmin
    {
        if (
            newAuctionBuffer < MIN_AUCTION_BUFFER ||
            newAuctionBuffer > MAX_AUCTION_BUFFER
        ) {
            revert AuctionBufferInvalid();
        }
        auctionBuffer = newAuctionBuffer;
        emit AuctionBufferSet(auctionBuffer);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setReservePrice(uint256 newReservePrice)
        public
        override
        onlyAdmin
    {
        if (
            newReservePrice < MIN_RESERVE_PRICE ||
            newReservePrice > MAX_RESERVE_PRICE
        ) {
            revert AuctionReservePriceInvalid();
        }
        reservePrice = newReservePrice;
        emit AuctionReservePriceSet(reservePrice);
    }

    /// @dev Puts the NFT produced by `token.mint()` up for auction.
    /// @return created True if auction creation succeeds, false otherwise.
    function _createAuction() internal returns (bool created) {
        try token.mint() returns (uint256 tokenId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + auctionDuration;

            auction = Auction({
                tokenId: tokenId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            created = true;
            emit AuctionCreated(tokenId, startTime, endTime);
        } catch {
            emit AuctionCreationFailed();
        }
    }

    /// @dev Settles the auction, transferring the NFT to the winning bidder.
    function _settleAuction() internal {
        if (auction.settled) {
            revert AuctionAlreadySettled();
        }

        if (block.timestamp < auction.endTime) {
            revert AuctionOngoing();
        }

        auction.settled = true;

        if (auction.bidder == address(0)) {
            token.transferFrom(address(this), treasury, auction.tokenId);
        } else {
            token.transferFrom(address(this), auction.bidder, auction.tokenId);
        }

        if (auction.amount > 0) {
            uint256 treasuryProceeds = auction.amount * treasurySplit / 100;
            uint256 reserveProceeds = auction.amount - treasuryProceeds;
            _transferETH(treasury, treasuryProceeds);
            if (reserveProceeds != 0) {
                _transferETH(reserve, reserveProceeds);
            }
        }

        emit AuctionSettled(auction.tokenId, auction.bidder, auction.amount);
    }

    /// @dev Transfers `value` wei to address `to`, forwarding a max of 30k gas.
    /// @return True if transfer is successful, False otherwise.
    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    /// @dev Performs an admin authorization check for UUPS upgrades.
    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != admin) {
            revert UpgradeUnauthorized();
        }
    }

}
