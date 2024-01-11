// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMercurianAssets {
    function getPrice(uint256 _tokenId, address _currency) external view returns (uint256);
    function mint(address _to, uint256 _tokenId,  uint256 _amount) external;
}