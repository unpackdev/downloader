pragma solidity >=0.5.0;

import "./IAlchemistV2Actions.sol";
import "./IAlchemistV2AdminActions.sol";
import "./IAlchemistV2Errors.sol";
import "./IAlchemistV2Immutables.sol";
import "./IAlchemistV2Events.sol";
import "./IAlchemistV2State.sol";

/// @title  IAlchemistV2
/// @author Alchemix Finance
interface IAlchemistV2 is
    IAlchemistV2Actions,
    IAlchemistV2AdminActions,
    IAlchemistV2Errors,
    IAlchemistV2Immutables,
    IAlchemistV2Events,
    IAlchemistV2State
{ }
