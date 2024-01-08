// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISpaceInmates {
    function addToWhiteList(address[] calldata addresses) external;

    function isOnWhitelist(address addr) external returns (bool);

    function removeFromWhitelist(address[] calldata addresses) external;

    function preSaleClaimedBy(address owner) external returns (uint256);

    function purchase(uint256 numberOfTokens) external payable;

    function purchasePreSale(uint256 numberOfTokens) external payable;

    function reserve(address to, uint256 amount) external;

    function setIsActive(bool isActive) external;

    function setIsPreSaleActive(bool isAllowListActive) external;

    function setPreSaleMaxMint(uint256 maxMint) external;

    function setProof(string memory proofString) external;

    function withdraw() external;
}
