// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IDeposits {
    function removeAllPendingDepositsExternal(address addr) external;
    function putTotalBalanceToLock(address addr) external;
}
