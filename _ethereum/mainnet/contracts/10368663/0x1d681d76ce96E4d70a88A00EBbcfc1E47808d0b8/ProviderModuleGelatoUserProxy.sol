// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./GelatoProviderModuleStandard.sol";
import "./IGelatoCore.sol";
import "./IGelatoUserProxyFactory.sol";
import "./IGelatoUserProxy.sol";
import "./GelatoActionPipeline.sol";

contract ProviderModuleGelatoUserProxy is GelatoProviderModuleStandard {

    IGelatoUserProxyFactory public immutable gelatoUserProxyFactory;
    address public immutable gelatoActionPipeline;

    constructor(
        IGelatoUserProxyFactory _gelatoUserProxyFactory,
        address _gelatoActionPipeline
    )
        public
    {
        gelatoUserProxyFactory = _gelatoUserProxyFactory;
        gelatoActionPipeline = _gelatoActionPipeline;
    }

    // ================= GELATO PROVIDER MODULE STANDARD ================
    function isProvided(address _userProxy, address, Task calldata)
        external
        view
        override
        returns(string memory)
    {
        bool proxyOk = gelatoUserProxyFactory.isGelatoUserProxy(_userProxy);
        if (!proxyOk) return "ProviderModuleGelatoUserProxy.isProvided:InvalidUserProxy";
        return OK;
    }

    function execPayload(uint256, address, address, Task calldata _task, uint256)
        external
        view
        override
        returns(bytes memory payload, bool)  // bool==false: no execRevertCheck
    {
        if (_task.actions.length > 1) {
            bytes memory gelatoActionPipelinePayload = abi.encodeWithSelector(
                GelatoActionPipeline.execActionsAndPipeData.selector,
                _task.actions
            );
            Action memory pipelinedActions = Action({
                addr: gelatoActionPipeline,
                data: gelatoActionPipelinePayload,
                operation: Operation.Delegatecall,
                dataFlow: DataFlow.None,
                value: 0,
                termsOkCheck: false
            });
            payload = abi.encodeWithSelector(
                IGelatoUserProxy.execAction.selector,
                pipelinedActions
            );
        } else if (_task.actions.length == 1) {
            payload = abi.encodeWithSelector(
                IGelatoUserProxy.execAction.selector,
                _task.actions[0]
            );
        } else {
            revert("ProviderModuleGelatoUserProxy.execPayload: 0 _task.actions length");
        }
    }
}