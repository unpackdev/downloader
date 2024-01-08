//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IAuction {
    /**
     * @return  bool The active status of the auction. Will only return true if
     *          the auction has been initialised and is active.
     */
    function isActive() external view returns (bool);

    /**
     * @param   _lotID The ID of the lot.
     * @return  bool If bidding has started on the lot.
     */
    function hasBiddingStarted(uint256 _lotID) external view returns (bool);

    /**
     * @return  uint256 The auction ID as set by the auction hub of this
     *          auction.
     */
    function getAuctionID() external view returns (uint256);

    /**
     * @param   _auctionID ID of the auction this auction is
     * @dev     This call will be protected so only the Auction hub can call it.
     *          This function will also set the auction state to active.
     */
    function init(uint256 _auctionID) external returns (bool);

    /**
     * @param   _lotID ID of the lot
     * @dev     Transfers the token from the auction back to the lot requester
     */
    function cancelLot(uint256 _lotID) external;
}
