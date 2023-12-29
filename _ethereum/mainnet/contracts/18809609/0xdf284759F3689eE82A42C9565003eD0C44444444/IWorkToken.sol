// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

interface IWorkToken {
    function mint(address to, uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external returns (uint256);
}
