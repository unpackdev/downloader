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

import "./Auction.sol";
import "./CoveragePool.sol";

/// @title AuctionBidder
/// @notice A contract for auction bidders for buying coverage pool auctions. This
///         contract offers additional features for bidders to decide if their
///         requirements for making a purchase are satisfied.
contract AuctionBidder {
    CoveragePool public immutable coveragePool;

    constructor(CoveragePool _coveragePool) {
        coveragePool = _coveragePool;
    }

    /// @notice Takes an offer from an auction buyer with a minimum required amount
    ///         of tokens to seize from the coverage pool.
    /// @dev 'minAmountToSeize' sets a minimum amount of tokens to seize in this
    ///      transaction. A bidder can call `takeOffer` directly in the Auction
    ///      contract but this function is a recommended way of taking coverage pool
    ///      auctions. It might happen that the order of transactions might be changed
    ///      for 'takeOffer' calls in the same block or claim and withdrawals from
    ///      an AssetPool might occur. These reasons can affect a taker's expected
    ///      amount of the coverage pool tokens to receive. Whereas if a minimum
    ///      amount of tokens is specified but not satisfied, then the transaction
    ///      will revert.
    /// @param auction coverage pool auction
    /// @param amount the amount a taker is paying, denominated in token accepted
    ///               by the auction
    /// @param minAmountToSeize minimum amount of tokens to seize from the coverage
    ///                         pool
    function takeOfferWithMin(
        Auction auction,
        uint256 amount,
        uint256 minAmountToSeize
    ) external {
        uint256 auctionAmountOutstanding = auction.amountOutstanding();
        uint256 amountToPay = Math.min(amount, auctionAmountOutstanding);
        (uint256 amountOnOffer, ) = auction.onOffer();
        uint256 portionToSeize = (amountOnOffer * amountToPay) /
            auctionAmountOutstanding;

        uint256 amountToSeize = coveragePool.amountToSeize(portionToSeize);

        require(
            minAmountToSeize <= amountToSeize,
            "Can't fulfill offer with a minimal amount to seize"
        );

        auction.takeOffer(amount);
    }
}
