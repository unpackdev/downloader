// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITemplate721 {
        function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
         function ownerOf(uint256 tokenId) external view returns (address owner);
        function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
        function setApprovalForAll(address operator, bool _approved) external;
}