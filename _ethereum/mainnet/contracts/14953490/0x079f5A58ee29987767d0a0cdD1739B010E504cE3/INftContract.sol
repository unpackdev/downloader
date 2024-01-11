// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface INftContract {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function getApproved(uint256 _tokenId) external returns (address _account);
    function approve(address _approved, uint256 _tokenId) external returns (address _account);
    function isApprovedForAll(address owner, address operator) external returns (bool);
}