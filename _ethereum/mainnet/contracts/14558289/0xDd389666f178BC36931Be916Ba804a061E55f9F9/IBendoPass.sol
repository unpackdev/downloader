// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBendoPass {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function burn(address account, uint256 id, uint256 value) external;
    function burnBatch(address account, uint256[] memory ids,uint256[] memory values) external;
}