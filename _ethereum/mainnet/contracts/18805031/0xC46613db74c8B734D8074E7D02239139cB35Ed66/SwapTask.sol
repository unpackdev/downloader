// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./SwapOperation.sol";

import "./Constants.sol";
import "./SlippageMath.sol";

struct SwapTask {
    SwapOperation swapOperation;
    address creditAccount;
    address tokenIn;
    address tokenOut;
    address[] connectors;
    uint256 amount;
    uint256 leftoverAmount;
}

library SwapTaskOps {
    function makeConnectorToConnectorTask(
        SwapTask memory swapTask,
        uint256 amount,
        uint256 connectorLeftoverAmount,
        uint256 index0,
        uint256 index1
    ) internal pure returns (SwapTask memory result) {
        result = SwapTask({
            swapOperation: SwapOperation.EXACT_INPUT_DIFF,
            creditAccount: swapTask.creditAccount,
            tokenIn: swapTask.connectors[index0],
            tokenOut: swapTask.connectors[index1],
            connectors: new address[](0),
            amount: amount,
            leftoverAmount: connectorLeftoverAmount
        });
    }

    function makeConnectorInTask(SwapTask memory swapTask, uint256 amount, uint256 index)
        internal
        pure
        returns (SwapTask memory result)
    {
        address[] memory connectors;
        result = SwapTask({
            swapOperation: swapTask.swapOperation,
            creditAccount: swapTask.creditAccount,
            tokenIn: swapTask.tokenIn,
            tokenOut: swapTask.connectors[index],
            connectors: connectors,
            amount: amount,
            leftoverAmount: swapTask.leftoverAmount
        });
    }

    function makeConnectorInTask(SwapTask memory swapTask, uint256 index)
        internal
        pure
        returns (SwapTask memory result)
    {
        result = makeConnectorInTask(swapTask, swapTask.amount, index);
    }

    function makeConnectorOutTask(
        SwapTask memory swapTask,
        uint256 amountIn,
        uint256 connectorLeftoverAmount,
        uint256 index
    ) internal pure returns (SwapTask memory result) {
        address[] memory connectors;
        result = SwapTask({
            swapOperation: SwapOperation.EXACT_INPUT_DIFF,
            creditAccount: swapTask.creditAccount,
            tokenIn: swapTask.connectors[index],
            tokenOut: swapTask.tokenOut,
            connectors: connectors,
            amount: amountIn,
            leftoverAmount: connectorLeftoverAmount
        });
    }

    function isInputTask(SwapTask memory swapTask) internal pure returns (bool) {
        if (
            swapTask.swapOperation == SwapOperation.EXACT_INPUT
                || swapTask.swapOperation == SwapOperation.EXACT_INPUT_DIFF
        ) return true;

        if (swapTask.swapOperation == SwapOperation.EXACT_OUTPUT) return false;

        revert UnsupportedSwapOperation(swapTask.swapOperation);
    }

    function isOutputTask(SwapTask memory swapTask) internal pure returns (bool) {
        return !isInputTask(swapTask);
    }

    function noSlippageCheckValue(SwapTask memory swapTask) internal pure returns (uint256) {
        if (isInputTask(swapTask)) {
            return 0;
        } else {
            return type(uint256).max;
        }
    }
}
