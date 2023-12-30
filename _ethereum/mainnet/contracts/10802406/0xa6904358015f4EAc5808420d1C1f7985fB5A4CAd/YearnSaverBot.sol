// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./IGelatoCore.sol";
import "./IGelatoSysAdmin.sol";
import "./IGelatoUserProxyFactory.sol";
import "./IGelatoUserProxy.sol";
import "./GelatoTaskReceipt.sol";
import "./GelatoString.sol";
import "./GelatoBytes.sol";
import "./IGelatoProviderModule.sol";


import "./IStrategyMKRVaultDAIDelegate.sol";
import "./GelatoManager.sol";

contract YearnSaverBot is GelatoManager {

    constructor(
        address _gelatoCore,
        address _yETHStrat,
        IGelatoProviderModule[] memory modules,
        IGelatoCondition _condition
    )
        public
        GelatoManager(
            _gelatoCore, // GelatoCore
            modules, // GelatoUserProxyProviderModule
            0xd70D5fb9582cC3b5B79BBFAECbb7310fd0e3B582 // Gelato Executor Network
        )
    {
        Condition memory condition = Condition({
            inst: _condition,
            data: ""
        });

        bytes memory repayData = abi.encodeWithSignature("repay()");

        Action memory action = Action({
            addr: _yETHStrat,
            data: repayData,
            operation: Operation.Call,
            dataFlow: DataFlow.None,
            value: 0,
            termsOkCheck: false
        });

        Condition[] memory singleCondition = new Condition[](1);
        singleCondition[0] = condition;
        Action[] memory singleAction = new Action[](1);
        singleAction[0] = action;

        Task memory task = Task({
            conditions: singleCondition,
            actions: singleAction,
            selfProviderGasLimit: 5000000, // Cap gas limit of tx to 5M
            selfProviderGasPriceCeil: 0
        });

        Task[] memory singleTask = new Task[](1);
        singleTask[0] = task;

        Provider memory provider = Provider({
            addr: address(this),
            module: IGelatoProviderModule(0x4372692C2D28A8e5E15BC2B91aFb62f5f8812b93)
        });

        // Submit the Task to Gelato
        submitTaskCycle(provider, singleTask, 0, 0);

    }

}