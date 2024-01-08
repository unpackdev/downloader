//SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IPoets is IERC721 {
    function getWordCount(uint256 tokenId) external view returns (uint8);
}
