// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERC721.sol";


interface IERC721Mintable is IERC721 {
    function safeMint(address to, uint256 tokenId) external;
}
