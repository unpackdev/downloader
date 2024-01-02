// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IPositionManagerOwnerActions.sol";
import { IPositionManagerState }        from './IPositionManagerState.sol';
import "./IPositionManagerDerivedState.sol";
import { IPositionManagerErrors }       from './IPositionManagerErrors.sol';
import { IPositionManagerEvents }       from './IPositionManagerEvents.sol';

/**
 *  @title Position Manager Interface
 */
interface IPositionManager is
    IPositionManagerOwnerActions,
    IPositionManagerState,
    IPositionManagerDerivedState,
    IPositionManagerErrors,
    IPositionManagerEvents
{

}
