// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ImmortalzInterface {
    function addToPresaleList(address[] calldata addresses) external;

    function onPresaleList(address addr) external returns (bool);

    function removeFromPresaleList(address[] calldata addresses) external;

    function presaleListClaimedBy(address owner) external returns (uint256);

    function purchase(uint256 numberOfTokens) external payable;

    function purchasePresaleList(uint256 numberOfTokens) external payable;

    function setIsActive(bool isActive) external;

    function setIsPresaleListActive(bool isAllowListActive) external;

    function setPresaleListMaxMint(uint256 maxMint) external;

    function withdraw() external;
}
