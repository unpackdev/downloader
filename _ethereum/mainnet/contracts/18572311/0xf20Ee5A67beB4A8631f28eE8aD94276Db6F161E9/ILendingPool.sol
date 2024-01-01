// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @notice interface for lending pool
/// This is not the full interface, rather a bare mininum to connect other contracts to the pool
interface ILendingPool {
    function onTrancheDeposit(uint8 trancheId, address depositorAddress, uint amount) external;

    function onTrancheWithdraw(uint8 trancheId, address depositorAddress, uint amount) external;
}
