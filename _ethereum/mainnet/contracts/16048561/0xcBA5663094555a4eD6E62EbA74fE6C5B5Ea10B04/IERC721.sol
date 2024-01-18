// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "./IERC721Upgradeable.sol";

interface IERC721V0 is IERC721Upgradeable {}

interface IERC721V1 is IERC721Upgradeable {
    function burn(uint256 tokenId) external;
}
