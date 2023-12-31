// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;

    function setApprovalForAll(address to, bool _approved) external;

    function balanceOf(address _owner) external view returns (uint256);
}
