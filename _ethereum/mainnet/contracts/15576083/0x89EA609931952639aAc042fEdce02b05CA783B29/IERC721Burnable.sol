// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./IERC721.sol";

interface IERC721Burnable is IERC721 {
    function burn(uint tokenId) external virtual;
}
