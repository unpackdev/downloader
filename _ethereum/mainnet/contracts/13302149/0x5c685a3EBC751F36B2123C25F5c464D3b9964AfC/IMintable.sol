// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

interface IMintable {
    function mint(address to) external;
    function owner() external returns (address);
}