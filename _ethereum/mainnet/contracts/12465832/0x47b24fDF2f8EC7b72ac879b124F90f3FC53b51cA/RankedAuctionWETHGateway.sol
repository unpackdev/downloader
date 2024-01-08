// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./IRankedAuction.sol";
import "./WETHGatewayBase.sol";

/**
 * @title RankedAuctionWETHGateway contract
 *
 * @author Aito
 * @notice Simple gateway to allow bidding in Aito ranked auctions denominated in WETH using ETH.
 */
contract RankedAuctionWETHGateway is WETHGatewayBase {

    constructor(address weth) WETHGatewayBase(weth){}

    /**
     * @notice Bids using the caller's ETH onBehalfOf the given address.
     *
     * @param auction The auction address to query an auction to bid on.
     * @param auctionId The ranked auction ID to bid on.
     * @param onBehalfOf The address to bid on behalf of.
     * @param amount The amount to bid.
     */
    function bidWithEth(
        address auction,
        uint256 auctionId,
        address onBehalfOf,
        uint256 amount
    ) external payable {
        uint256 WETHBefore = WETH.balanceOf(address(this));
        WETH.deposit{value: msg.value}();
        IRankedAuction(auction).bid(auctionId, onBehalfOf, amount);
        uint256 WETHAfter = WETH.balanceOf(address(this));
        if (WETHAfter > WETHBefore) {
            uint256 diff = WETHAfter - WETHBefore;
            WETH.withdraw(diff);
            _safeTransferETH(msg.sender, diff);
        }
        require(WETH.balanceOf(address(this)) == WETHBefore, "RankedAuctionWETHGateway: Invalid WETH After");
    }

    receive() external payable {
        require(msg.sender == address(WETH), "RankedAuctionWETHGateway: Not WETH address");
    }
}
