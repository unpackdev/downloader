// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title Dutch Auction interface made by Artiffine.
 * @author https://artiffine.com/
 */
interface IDutchAuction {
    /**
     * @notice Returns current price auction in wei.
     *
     * @dev Throws `AuctionIsClosed()` error.
     */
    function getAuctionPrice() external view returns (uint256);

    /**
     * @notice Owner function to reset auction paramters.
     */
    function resetAuction(
        uint256 _startTime,
        uint256 _stepTime,
        uint256 _startPrice,
        uint256 _priceDiscount,
        uint256 _finalPrice
    ) external;
}
