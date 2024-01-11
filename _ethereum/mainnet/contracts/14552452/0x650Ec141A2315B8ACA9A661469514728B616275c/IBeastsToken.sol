// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BeastsToken

pragma solidity ^0.8.6;

import "./IERC721.sol";

interface IBeastsToken is IERC721 {
    function mint(address recipient) external returns (uint256);

    function exists(uint256 tokenId) external returns (bool);
}
