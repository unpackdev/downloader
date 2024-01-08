// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

interface IMagicLampERC721 is IERC721Enumerable {
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}
