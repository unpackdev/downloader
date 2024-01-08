// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./IAuction.sol";
import "./Auctioneer.sol";
import "./CoveragePoolConstants.sol";

import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/// @title Auction
/// @notice A contract to run a linear falling-price auction against a diverse
///         basket of assets held in a collateral pool. Auctions are taken using
///         a single asset. Over time, a larger and larger portion of the assets
///         are on offer, eventually hitting 100% of the backing collateral
///         pool. Auctions can be partially filled, and are meant to be amenable
///         to flash loans and other atomic constructions to take advantage of
///         arbitrage opportunities within a single block.
/// @dev  Auction contracts are not meant to be deployed directly, and are
///       instead cloned by an auction factory. Auction contracts clean up and
///       self-destruct on close. An auction that has run the entire length will
///       stay open, forever, or until priced fluctuate and it's eventually
///       profitable to close.
contract Auction is IAuction {
    using SafeERC20 for IERC20;

    struct AuctionStorage {
        IERC20 tokenAccepted;
        Auctioneer auctioneer;
        // the auction price, denominated in tokenAccepted
        uint256 amountOutstanding;
        uint256 amountDesired;
        uint256 startTime;
        uint256 startTimeOffset;
        uint256 auctionLength;
    }

    AuctionStorage public self;
    address public immutable masterContract;

    /// @notice Throws if called by any account other than the auctioneer.
    modifier onlyAuctioneer() {
        //slither-disable-next-line incorrect-equality
        require(
            msg.sender == address(self.auctioneer),
            "Caller is not the auctioneer"
        );

        _;
    }

    constructor() {
        masterContract = address(this);
    }

    /// @notice Initializes auction
    /// @dev At the beginning of an auction, velocity pool depleting rate is
    ///      always 1. It increases over time after a partial auction buy.
    /// @param _auctioneer    the auctioneer contract responsible for seizing
    ///                       funds from the backing collateral pool
    /// @param _tokenAccepted the token with which the auction can be taken
    /// @param _amountDesired the amount denominated in _tokenAccepted. After
    ///                       this amount is received, the auction can close.
    /// @param _auctionLength the amount of time it takes for the auction to get
    ///                       to 100% of all collateral on offer, in seconds.
    function initialize(
        Auctioneer _auctioneer,
        IERC20 _tokenAccepted,
        uint256 _amountDesired,
        uint256 _auctionLength
    ) external {
        require(!isMasterContract(), "Can not initialize master contract");
        //slither-disable-next-line incorrect-equality
        require(self.startTime == 0, "Auction already initialized");
        require(_amountDesired > 0, "Amount desired must be greater than zero");
        require(_auctionLength > 0, "Auction length must be greater than zero");
        self.auctioneer = _auctioneer;
        self.tokenAccepted = _tokenAccepted;
        self.amountOutstanding = _amountDesired;
        self.amountDesired = _amountDesired;
        /* solhint-disable-next-line not-rely-on-time */
        self.startTime = block.timestamp;
        self.startTimeOffset = 0;
        self.auctionLength = _auctionLength;
    }

    /// @notice Takes an offer from an auction buyer.
    /// @dev There are two possible ways to take an offer from a buyer. The first
    ///      one is to buy entire auction with the amount desired for this auction.
    ///      The other way is to buy a portion of an auction. In this case an
    ///      auction depleting rate is increased.
    ///      WARNING: When calling this function directly, it might happen that
    ///      the expected amount of tokens to seize from the coverage pool is
    ///      different from the actual one. There are a couple of reasons for that
    ///      such another bids taking this offer, claims or withdrawals on an
    ///      Asset Pool that are executed in the same block. The recommended way
    ///      for taking an offer is through 'AuctionBidder' contract with
    ///      'takeOfferWithMin' function, where a caller can specify the minimal
    ///      value to receive from the coverage pool in exchange for its amount
    ///      of tokenAccepted.
    /// @param amount the amount the taker is paying, denominated in tokenAccepted.
    ///               In the scenario when amount exceeds the outstanding tokens
    ///               for the auction to complete, only the amount outstanding will
    ///               be taken from a caller.
    function takeOffer(uint256 amount) external override {
        require(amount > 0, "Can't pay 0 tokens");
        uint256 amountToTransfer = Math.min(amount, self.amountOutstanding);
        uint256 amountOnOffer = _onOffer();

        //slither-disable-next-line reentrancy-no-eth
        self.tokenAccepted.safeTransferFrom(
            msg.sender,
            address(self.auctioneer),
            amountToTransfer
        );

        uint256 portionToSeize = (amountOnOffer * amountToTransfer) /
            self.amountOutstanding;

        if (!isAuctionOver() && amountToTransfer != self.amountOutstanding) {
            // Time passed since the auction start or the last takeOffer call
            // with a partial fill.


                uint256 timePassed /* solhint-disable-next-line not-rely-on-time */
             = block.timestamp - self.startTime - self.startTimeOffset;

            // Ratio of the auction's amount included in this takeOffer call to
            // the whole outstanding auction amount.
            uint256 ratioAmountPaid = (CoveragePoolConstants
            .FLOATING_POINT_DIVISOR * amountToTransfer) /
                self.amountOutstanding;
            // We will shift the start time offset and increase the velocity pool
            // depleting rate proportionally to the fraction of the outstanding
            // amount paid in this function call so that the auction can offer
            // no worse financial outcome for the next takers than the current
            // taker has.
            //
            //slither-disable-next-line divide-before-multiply
            self.startTimeOffset =
                self.startTimeOffset +
                ((timePassed * ratioAmountPaid) /
                    CoveragePoolConstants.FLOATING_POINT_DIVISOR);
        }

        self.amountOutstanding -= amountToTransfer;

        //slither-disable-next-line incorrect-equality
        bool isFullyFilled = self.amountOutstanding == 0;

        // inform auctioneer of proceeds and winner. the auctioneer seizes funds
        // from the collateral pool in the name of the winner, and controls all
        // proceeds
        //
        //slither-disable-next-line reentrancy-no-eth
        self.auctioneer.offerTaken(
            msg.sender,
            self.tokenAccepted,
            amountToTransfer,
            portionToSeize,
            isFullyFilled
        );

        //slither-disable-next-line incorrect-equality
        if (isFullyFilled) {
            harikari();
        }
    }

    /// @notice Tears down the auction manually, before its entire amount
    ///         is bought by takers.
    /// @dev Can be called only by the auctioneer which may decide to early
    //       close the auction in case it is no longer needed.
    function earlyClose() external onlyAuctioneer {
        require(self.amountOutstanding > 0, "Auction must be open");

        harikari();
    }

    /// @notice How much of the collateral pool can currently be purchased at
    ///         auction, across all assets.
    /// @dev _onOffer() / FLOATING_POINT_DIVISOR) returns a portion of the
    ///      collateral pool. Ex. if 35% available of the collateral pool,
    ///      then _onOffer() / FLOATING_POINT_DIVISOR) returns 0.35
    /// @return the ratio of the collateral pool currently on offer
    function onOffer() external view override returns (uint256, uint256) {
        return (_onOffer(), CoveragePoolConstants.FLOATING_POINT_DIVISOR);
    }

    function amountOutstanding() external view returns (uint256) {
        return self.amountOutstanding;
    }

    function amountTransferred() external view returns (uint256) {
        return self.amountDesired - self.amountOutstanding;
    }

    /// @dev Delete all storage and destroy the contract. Should only be called
    ///      after an auction has closed.
    function harikari() internal {
        require(!isMasterContract(), "Master contract can not harikari");
        selfdestruct(payable(address(self.auctioneer)));
    }

    function _onOffer() internal view returns (uint256) {
        // when the auction is over, entire pool is on offer
        if (isAuctionOver()) {
            // Down the road, for determining a portion on offer, a value returned
            // by this function will be divided by FLOATING_POINT_DIVISOR. To
            // return the entire pool, we need to return just this divisor in order
            // to get 1.0 ie. FLOATING_POINT_DIVISOR / FLOATING_POINT_DIVISOR = 1.0
            return CoveragePoolConstants.FLOATING_POINT_DIVISOR;
        }

        // How fast portions of the collateral pool become available on offer.
        // It is needed to calculate the right portion value on offer at the
        // given moment before the auction is over.
        // Auction length once set is constant and what changes is the auction's
        // "start time offset" once the takeOffer() call has been processed for
        // partial fill. The auction's "start time offset" is updated every takeOffer().
        // velocityPoolDepletingRate = auctionLength / (auctionLength - startTimeOffset)
        // velocityPoolDepletingRate always starts at 1.0 and then can go up
        // depending on partial offer calls over auction life span to maintain
        // the right ratio between the remaining auction time and the remaining
        // portion of the collateral pool.
        //slither-disable-next-line divide-before-multiply
        uint256 velocityPoolDepletingRate = (CoveragePoolConstants
        .FLOATING_POINT_DIVISOR * self.auctionLength) /
            (self.auctionLength - self.startTimeOffset);

        return
            /* solhint-disable-next-line not-rely-on-time */
            ((block.timestamp - (self.startTime + self.startTimeOffset)) *
                velocityPoolDepletingRate) / self.auctionLength;
    }

    function isAuctionOver() internal view returns (bool) {
        /* solhint-disable-next-line not-rely-on-time */
        return block.timestamp >= self.startTime + self.auctionLength;
    }

    function isMasterContract() internal view returns (bool) {
        return masterContract == address(this);
    }
}
