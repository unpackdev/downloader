// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "./ERC721Enumerable.sol";

interface ICollectible is IERC721Enumerable {
    function mint(address to, uint256 amount) external;
}
