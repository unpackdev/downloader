// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ITripsters.sol";
import "./LinearDutchAuction.sol";

contract DutchTripsters is LinearDutchAuction {
    ITripsters public tripsters;
    bool public startDutchAuction;

    constructor(
        address payable beneficiary
    )
        LinearDutchAuction(
            LinearDutchAuction.DutchAuctionConfig({
                startPoint: 0,
                startPrice: 0.375 ether,
                unit: AuctionIntervalUnit.Time,
                decreaseInterval: 600,
                decreaseSize: 0.01 ether,
                numDecreases: 8
            }),
            0.295 ether,
            Seller.SellerConfig({
                totalInventory: 4400,
                lockTotalInventory: true,
                maxPerAddress: 3,
                maxPerTx: 3,
                freeQuota: 0,
                lockFreeQuota: true,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {}

    /// LinearDutchAuction Required Functions
    /// @notice Entry point for purchase of a single token.
    function mint(uint256 amount) external payable {
        require(startDutchAuction, "Not Live");
        Seller._purchase(msg.sender, amount);
    }

    /// @notice Internal override of Seller function for handling purchase (i.e. minting).
    function _handlePurchase(
        address to,
        uint256 num,
        bool
    ) internal override {
        tripsters.adminMint(num, to);
    }

    function setTripsters(ITripsters _tripsters) external onlyOwner {
        tripsters = _tripsters;
    }

    function toggleDutchAuction() external onlyOwner {
        startDutchAuction = !startDutchAuction;
    }
}