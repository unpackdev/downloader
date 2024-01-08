// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IExchange {

    function openPosition(bytes32 currencyKey, uint8 direction, uint16 leverage, uint position) external returns (uint32);

    function addDeposit(uint32 positionId, uint margin) external;

    function closePosition(uint32 positionId) external;

    function rebase() external;
}
