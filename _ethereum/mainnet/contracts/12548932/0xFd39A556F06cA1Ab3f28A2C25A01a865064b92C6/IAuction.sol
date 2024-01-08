// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;


/**
 * @title IAuction
 */
interface IAuction {
    function buySingle(address receiver, uint256 tokenId) external payable;
    function buyMany(address[] calldata receivers, uint256[] calldata tokenIds) external payable;
}