//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

interface IBaseRegistrar {
    function transferFrom(address from, address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function setApprovalForAll(address operator, bool _approved) external;
}
