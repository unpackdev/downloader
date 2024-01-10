//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IFun1155 {
    function mint(address account, uint256 id, uint256 amount) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}