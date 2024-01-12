// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMoonSkulls {
    function mint(address minter,uint256 quantity) external;
    function numberMinted(address minter) external view returns (uint256);
    function nextTokenId() external view returns (uint256);
    function mTotalSupply() external view returns (uint256);
    function mOwnerOf(uint256 tokenId) external view returns (address);
    function mTokensOfOwner(address owner) external view returns (uint256[] memory);
}