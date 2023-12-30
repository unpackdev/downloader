// // "SPDX-License-Identifier: UNLICENSED"
// pragma solidity ^0.6.10;
// pragma experimental ABIEncoderV2;


// import "./IGelatoCore.sol";
// import "./IGelatoProviderModule.sol";


// import "./IStrategyMKRVaultDAIDelegate.sol";
// import "./GelatoManager.sol";

// contract YearnSaverBot is GelatoManager {

//     /// @dev Submits a task to gelato which tracks whether yETH CDP debt should be repaid or not
//     /// and repays it automatically when it can
//     constructor(
//         address _gelatoCore,
//         address _yETHStrat,
//         IGelatoProviderModule[] memory modules,
//         IGelatoCondition _condition
//     )
//         public
//         payable
//         GelatoManager(
//             _gelatoCore, // GelatoCore
//             modules, // GelatoUserProxyProviderModule
//             0xd70D5fb9582cC3b5B79BBFAECbb7310fd0e3B582 // Gelato Executor Network
//         )
//     {
//         // ConditionYETHStratRepay.sol
        // Condition memory condition = Condition({
        //     inst: _condition,
        //     data: ""
        // });

        // bytes memory repayData = abi.encodeWithSignature("repay()");

        // // 0x932fc4fd0eEe66F22f1E23fBA74D7058391c0b15
        // Action memory action = Action({
        //     addr: _yETHStrat,
        //     data: repayData,
        //     operation: Operation.Call,
        //     dataFlow: DataFlow.None,
        //     value: 0,
        //     termsOkCheck: false
        // });

        // Condition[] memory singleCondition = new Condition[](1);
        // singleCondition[0] = condition;
        // Action[] memory singleAction = new Action[](1);
        // singleAction[0] = action;

        // Task memory task = Task({
        //     conditions: singleCondition,
        //     actions: singleAction,
        //     selfProviderGasLimit: 0,
        //     selfProviderGasPriceCeil: 0
        // });

        // Task[] memory singleTask = new Task[](1);
        // singleTask[0] = task;

        // Provider memory provider = Provider({
        //     addr: address(this),
        //     module: IGelatoProviderModule(modules[0])
        // });

        // // Submit the Task to Gelato
        // submitTaskCycle(provider, singleTask, 0, 0);

//     }

// }