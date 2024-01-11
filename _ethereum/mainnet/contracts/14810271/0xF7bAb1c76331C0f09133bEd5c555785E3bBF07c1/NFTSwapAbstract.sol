// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;
pragma abicoder v2;

abstract contract ERC721Interface {
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external virtual;
}

abstract contract ERC1155Interface {
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external virtual;
}

abstract contract ERC20Interface {
    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
}