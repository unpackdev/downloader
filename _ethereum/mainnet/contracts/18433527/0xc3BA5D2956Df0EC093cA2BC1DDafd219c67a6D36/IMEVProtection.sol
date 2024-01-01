// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMEVProtection {
    error PoolIsNotStable();
    error NotEnoughObservations();

    function ensureNoMEV(address pool, bytes memory data) external view;
}
