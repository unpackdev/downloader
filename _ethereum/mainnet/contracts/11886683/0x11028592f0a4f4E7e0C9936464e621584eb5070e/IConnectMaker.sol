// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IConnectMaker {
    function payback(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable;

    function borrow(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable;

    function open(string calldata colType)
        external
        payable
        returns (uint256 vault);

    function withdraw(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable;

    function deposit(
        uint256 vault,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable;
}
