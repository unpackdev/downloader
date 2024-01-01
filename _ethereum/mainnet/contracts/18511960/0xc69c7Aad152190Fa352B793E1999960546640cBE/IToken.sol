// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IToken {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function transfer(address to, uint256 amount) external;

    function approve(address spender, uint256 value) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}
