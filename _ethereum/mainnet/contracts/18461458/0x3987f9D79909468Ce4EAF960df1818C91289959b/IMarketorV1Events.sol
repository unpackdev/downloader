// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IMarketorV1Events {
    event e_setMarketorByMarketCreator(address);
    event e_delMarketorByMarketCreator(address);
}
