// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface INinjaOtomebyAkezie {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getTotalSupply() external view returns (uint256);
    function mint(address _address, uint256 _tokenId) external;
}