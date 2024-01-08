// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IHypervisor {
    function deposit(
        uint256,
        uint256,
        address
    ) external returns (uint256);

    function withdraw(
        uint256,
        address,
        address
    ) external returns (uint256, uint256);

    function balanceOf(address) external returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}
