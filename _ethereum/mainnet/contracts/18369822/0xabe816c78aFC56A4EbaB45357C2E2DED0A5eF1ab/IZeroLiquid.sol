pragma solidity >=0.5.0;

import "./IZeroLiquidActions.sol";
import "./IZeroLiquidAdminActions.sol";
import "./IZeroLiquidErrors.sol";
import "./IZeroLiquidImmutables.sol";
import "./IZeroLiquidEvents.sol";
import "./IZeroLiquidState.sol";

/// @title  IZeroLiquid
/// @author ZeroLiquid
interface IZeroLiquid is
    IZeroLiquidActions,
    IZeroLiquidAdminActions,
    IZeroLiquidErrors,
    IZeroLiquidImmutables,
    IZeroLiquidEvents,
    IZeroLiquidState
{ }
