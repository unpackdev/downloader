// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC165.sol";

interface IPriceEngine is IERC165 {

    /**
     *  @dev Determine price of an asset given the number
     *  already minted.
     */
    function price(uint256 assetId, uint256 alreadyMinted) view external returns (uint256);

}