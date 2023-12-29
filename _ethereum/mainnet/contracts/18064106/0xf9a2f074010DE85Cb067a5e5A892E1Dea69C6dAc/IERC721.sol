// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}
