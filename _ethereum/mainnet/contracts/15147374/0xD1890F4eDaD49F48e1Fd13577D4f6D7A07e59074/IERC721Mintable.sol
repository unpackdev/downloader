// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IAccessControl.sol";
import "./IERC721.sol";

interface IERC721Mintable is IERC721, IAccessControl {
    function mint(address to, uint256 tokenId) external;

    function mint(address to) external; 
}