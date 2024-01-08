// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IERC721.sol";


interface IBlitmap is IERC721 {
    function tokenNameOf(uint256 tokenId) external view returns (string memory);
    function tokenSvgDataOf(uint256 tokenId) external view returns (string memory);
}
