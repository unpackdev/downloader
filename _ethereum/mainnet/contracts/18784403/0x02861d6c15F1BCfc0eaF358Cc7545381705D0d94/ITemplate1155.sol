// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
// import "./ERC1155URIStorageUpgradeable.sol";
// import "./ERC2981Upgradeable.sol";

interface ITemplate1155 {
        function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes memory data)external;
        function balanceOf(address account, uint256 id) external returns (uint256);
        function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
        function setApprovalForAll(address operator,bool approved)external;
}