// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.9;

import "./IERC1155.sol";

interface IRegion is IERC1155 {
    function trustedCreateRegion() external returns (uint256 theNewRegion);
    function newRegion() external returns (uint256 theNewRegion);
    function getCurrentRegionCount() external view returns (uint256);
    function getCurrentRegionPricingCounter() external view returns (uint256);
    function ownerOf(uint256 _id) external view returns (address);
    function getRegionCost(int256 offset) external view returns (uint256);
    function getRegionName(uint256 regionID) external;
    function payRegion(uint256 regionID, uint256 amount, bool tax) external;
}