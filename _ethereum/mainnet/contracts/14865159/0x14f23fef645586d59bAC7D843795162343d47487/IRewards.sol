pragma solidity ^0.8.0;

interface IRewards {
    function purchaseEvent(
        address buyer,
        address seller,
        uint256 price,
        address collection,
        uint256 tokenId
    ) external;

    function purchaseEvent(
        address buyer,
        address seller,
        uint256 price,
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external;
}
