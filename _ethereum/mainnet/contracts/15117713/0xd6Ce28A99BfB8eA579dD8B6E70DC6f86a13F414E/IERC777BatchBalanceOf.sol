// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IERC777BatchBalanceOf {
    function batchBalanceOf(address[] calldata holders) external view returns (uint256[] memory);
}
