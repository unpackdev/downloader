// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAuctionFactory {
    function auctionSellerTax() external view returns (uint256);
    function saleSellerTax() external view returns (uint256);
    function treasury() external view returns (address);
    function auctionDeadlineDelay() external view returns (uint256);
    function saleDeadlineDelay() external view returns (uint256);
}