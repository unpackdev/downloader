// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ERC165.sol";

interface IAshCC is IERC165 {

    function transferPoints(uint cardFrom, uint cardTo, uint numPoints) external;

    function addMerchant(address merchant, uint discountPercent) external;

    function updateMerchant(address merchant, uint discountPercent) external;

    function removeMerchant(address merchant) external;

    function addPoints(uint tokenId, uint numPoints) external;

    function getDiscount(address merchant) external view returns (uint);

    function getPoints(uint tokenId) external returns (uint);
}
