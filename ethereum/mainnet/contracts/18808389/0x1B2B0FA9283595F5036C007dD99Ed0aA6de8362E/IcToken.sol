// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IcToken {
    function crop() external view returns (string memory);
    function mint(address account, uint256 amount) external;
}