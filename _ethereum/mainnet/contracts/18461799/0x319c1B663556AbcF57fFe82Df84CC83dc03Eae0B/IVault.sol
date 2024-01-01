// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
    function isBidExist(uint256 listingId) external view returns (bool);

    function isBidder(
        address sender,
        uint256 listingId
    ) external view returns (bool);

    function getBidPrice(uint256 listingId) external view returns (uint256);

    function updateBid(
        uint256 listingId,
        address bidder,
        address currency,
        uint256 price
    ) external;

    function refundBid(uint256 listingId, address currency) external;

    function acceptBid(
        uint256 listingId,
        address receiver,
        address currency,
        uint256 fee,
        address royaltyReceiver,
        uint256 royalty
    ) external;

    function updateFeeAccumulator(address currency, uint256 fee) external;
}
