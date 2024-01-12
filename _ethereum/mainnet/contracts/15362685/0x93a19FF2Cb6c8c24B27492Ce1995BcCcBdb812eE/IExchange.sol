// SPDX-License-Identifier: MIT
// IExchange Contracts v4.1.0
// Creator: mumulei

pragma solidity ^0.8.4;

import "./Attributes.sol";

/**
 * @dev Interface of an IExchangeFacet compliant contract.
 */
interface IExchange {

    event MakeOrder(uint256 id, bytes32 indexed hash, address seller);

    event CancelOrder(uint256 id, bytes32 indexed hash, address seller);

    event Claim(uint256 id, bytes32 indexed hash, address seller, address taker, uint256 price);

    function tokenOrderLength(uint256 id) external view returns (uint256 length);

    function sellerOrderLength(address seller) external view returns (uint256 length);

    function getOrderHashByToken(uint256 tokenId, uint256 index) external view returns (bytes32);

    function getOrderHashBySeller(address seller, uint256 index) external view returns (bytes32);

    function getOrderInfo(bytes32 orderHash) external view returns (ExchangeOrder memory);

    function getCurrentPrice(bytes32 order) external view returns (uint256 price);

    function sell(uint256 _id, uint256 _price) external;

    function batchSell(uint256[] memory _ids, uint256[] memory _prices) external;

    function buyItNow(bytes32 _order) external payable;

    function cancelOrder(bytes32 _order) external;

}