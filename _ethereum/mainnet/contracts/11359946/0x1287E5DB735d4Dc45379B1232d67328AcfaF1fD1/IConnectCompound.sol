// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface IConnectCompound {
    function borrow(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable;

    function deposit(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable;
}
