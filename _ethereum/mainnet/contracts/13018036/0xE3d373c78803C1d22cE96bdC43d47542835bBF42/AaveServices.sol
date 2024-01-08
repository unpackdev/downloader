// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity 0.8.7;

import "./ASimpleServiceStandard.sol";
import "./IAction.sol";
import "./GelatoBytes.sol";
import "./SProtection.sol";

/// @author Gelato Digital
/// @title Aave Automated Services Contract.
/// @dev Automate any type of task related to Aave.
contract AaveServices is ASimpleServiceStandard {
    using GelatoBytes for bytes;

    constructor(address _gelato) ASimpleServiceStandard(_gelato) {}

    /// Submit Aave Task.
    /// @param _action Task's executor address.
    /// @param _taskData Data needed to perform the task.
    /// @param _isPermanent Defining if it's a permanent task.
    function submitTask(
        address _action,
        bytes memory _taskData,
        bool _isPermanent
    )
        external
        isActionOk(_action)
        gelatoSubmit(_action, _taskData, _isPermanent)
    {}

    /// Cancel Aave Task.
    /// @param _action Type of action (for example Protection)
    function cancelTask(address _action) external gelatoCancel(_action) {}

    /// Update Aave Task.
    /// @param _action Task's executor address.
    /// @param _data new data needed to perform the task.
    /// @param _isPermanent Defining if it's a permanent task.
    function updateTask(
        address _action,
        bytes memory _data,
        bool _isPermanent
    ) external isActionOk(_action) gelatoModify(_action, _data, _isPermanent) {}

    /// Execution of Aave Task.
    /// @param _execData data containing user, action Addr, on chain data, off chain data, is permanent.
    function exec(ExecutionData memory _execData)
        external
        isActionOk(_execData.action)
        gelatofy(
            _execData.user,
            _execData.action,
            _execData.subBlockNumber,
            _execData.data,
            _execData.isPermanent
        )
    {
        bytes memory payload = abi.encodeWithSelector(
            IAction.exec.selector,
            hashTask(
                _execData.user,
                _execData.subBlockNumber,
                _execData.data,
                _execData.isPermanent
            ),
            _execData.data,
            _execData.offChainData
        );
        (bool success, bytes memory returndata) = _execData.action.call(
            payload
        );
        if (!success) returndata.revertWithError("AaveServices.exec:");

        if (_execData.isPermanent)
            _submitTask(
                _execData.user,
                _execData.action,
                _execData.data,
                _execData.isPermanent
            );
    }
}
