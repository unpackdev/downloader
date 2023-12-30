// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./GelatoActionsStandard.sol";
import "./IGelatoInFlowAction.sol";
import "./IGelatoOutFlowAction.sol";
import "./IGelatoInAndOutFlowAction.sol";

/// @title GelatoActionsStandardFull
/// @notice ActionStandard that inherits from all the PipeAction interfaces.
/// @dev Inherit this to enforce implementation of all PipeAction functions.
abstract contract GelatoActionsStandardFull is
    GelatoActionsStandard,
    IGelatoInFlowAction,
    IGelatoOutFlowAction,
    IGelatoInAndOutFlowAction
{
    function DATA_FLOW_IN_TYPE()
        external
        pure
        virtual
        override(IGelatoInFlowAction, IGelatoInAndOutFlowAction)
        returns (bytes32);

    function DATA_FLOW_OUT_TYPE()
        external
        pure
        virtual
        override(IGelatoOutFlowAction, IGelatoInAndOutFlowAction)
        returns (bytes32);
}