// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface ICassette {
    function currentMaxPage() external view returns (uint);
    function replicatorMint(address to, uint256 chapter, uint256 amount) external payable;
}