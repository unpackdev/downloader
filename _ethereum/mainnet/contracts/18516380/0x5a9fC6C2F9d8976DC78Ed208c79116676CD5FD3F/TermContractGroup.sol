//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./TermAuction.sol";
import "./TermAuctionBidLocker.sol";
import "./TermAuctionOfferLocker.sol";
import "./TermRepoCollateralManager.sol";
import "./TermRepoLocker.sol";
import "./TermRepoRolloverManager.sol";
import "./TermRepoServicer.sol";
import "./TermRepoToken.sol";

struct TermContractGroup {
    TermRepoLocker termRepoLocker;
    TermRepoServicer termRepoServicer;
    TermRepoCollateralManager termRepoCollateralManager;
    TermRepoRolloverManager rolloverManager;
    TermRepoToken termRepoToken;
    TermAuctionOfferLocker termAuctionOfferLocker;
    TermAuctionBidLocker termAuctionBidLocker;
    TermAuction auction;
}
