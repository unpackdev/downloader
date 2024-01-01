// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract The8102Factory {
    function burn(uint256 _id, uint256 _amount) external virtual;
    function balanceOf(address account, uint256 id) public view virtual returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual;
    function setApprovalForAll(address operator, bool approved) public virtual;
    function isApprovedForAll(address account, address operator) public view virtual returns (bool);
}
