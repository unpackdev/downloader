// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface IConnectInstaPoolV2 {
    function flashBorrowAndCast(
        address token,
        uint256 amt,
        uint256 route,
        bytes memory data
    ) external payable;

    function flashPayback(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable;
}
