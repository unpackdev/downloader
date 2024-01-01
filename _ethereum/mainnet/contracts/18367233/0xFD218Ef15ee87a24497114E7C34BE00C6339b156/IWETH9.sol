// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface IWETH9 {
    function balanceOf(address) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}
