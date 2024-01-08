// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface ILottery {

    function buy(uint256 _price, uint8[4] memory _numbers) external;
}