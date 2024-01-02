// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./ICreditFacadeV3Multicall.sol";
import "./SwapOperation.sol";
import "./SwapTask.sol";
import "./Balances.sol";
import "./ExtraBalanceOps.sol";
import "./BalancesLogic.sol";
import "./ICreditFacadeV3.sol";
import "./MultiCall.sol";
import "./SlippageMath.sol";
import "./IAdapter.sol";
import "./RouterResult.sol";
import "./Constants.sol";
// CREDIT
import "./ICreditManagerV3.sol";
import "./ICreditConfiguratorV3.sol";
import "./ICreditAccount.sol";

struct TokenAdapters {
    address token;
    address depositAdapter;
    address withdrawAdapter;
}

/// @dev Internal struct is widely use inside Router
/// End user doesn't interact with it, it's created in Router and then used to manage
/// whole process
struct StrategyPathTask {
    address creditAccount;
    Balance[] balances;
    Balance[] leftoverBalances;
    address target;
    address[] connectors;
    address[] adapters;
    uint256 slippage;
    bool force;
    //
    // for internal use
    uint8 targetType;
    TokenAdapters[] foundAdapters;
    uint256 gasPriceTargetRAY;
    uint256 gasUsage;
    uint256 initTargetBalance;
    MultiCall[] calls;
}

error NoSpaceForSlippageCallException();
error DifferentTargetComparisonException();

library StrategyPathTaskOps {
    using SlippageMath for uint256;
    using BalanceOps for Balance[];
    using ExtraBalanceOps for BalanceDelta[];
    using MultiCallOps for MultiCall[];

    function toSwapTask(StrategyPathTask memory task, uint256 tokenIndex, address target)
        internal
        pure
        returns (SwapTask memory)
    {
        return SwapTask({
            swapOperation: SwapOperation.EXACT_INPUT_DIFF,
            creditAccount: task.creditAccount,
            tokenIn: task.balances[tokenIndex].token,
            tokenOut: target,
            connectors: task.connectors,
            amount: getBalanceDiff(task, tokenIndex),
            leftoverAmount: task.leftoverBalances[tokenIndex].balance
        });
    }

    function toSwapTask(
        StrategyPathTask memory task,
        address tokenIn,
        uint256 amount,
        address tokenOut,
        bool isDiffInput,
        bool externalSlippage
    ) internal pure returns (SwapTask memory) {
        return SwapTask({
            swapOperation: isDiffInput ? SwapOperation.EXACT_INPUT_DIFF : SwapOperation.EXACT_INPUT,
            creditAccount: task.creditAccount,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            connectors: task.connectors,
            amount: amount,
            leftoverAmount: task.leftoverBalances.getBalance(tokenIn)
        });
    }

    function amountOutWithSlippage(StrategyPathTask memory task, uint256 amount) internal pure returns (uint256) {
        return amount.applySlippage(task.slippage, true);
    }

    function isZeroBalance(StrategyPathTask memory task, address token) internal pure returns (bool) {
        return task.balances.getBalance(token) == 0;
    }

    function getBalanceDiff(StrategyPathTask memory task, address token) internal pure returns (uint256) {
        uint256 index = task.balances.getIndex(token);
        return getBalanceDiff(task, index);
    }

    function getBalanceDiff(StrategyPathTask memory task, uint256 index) internal pure returns (uint256) {
        if (task.leftoverBalances[index].balance > task.balances[index].balance) return 0;
        return task.balances[index].balance - task.leftoverBalances[index].balance;
    }

    function findAdapterByTarget(StrategyPathTask memory task, address targetContract)
        internal
        view
        returns (address adapter)
    {
        for (uint256 i; i < task.adapters.length;) {
            if (task.adapters[i] == address(0)) continue;
            try IAdapter(task.adapters[i]).targetContract() returns (address currentTarget) {
                if (currentTarget == targetContract) {
                    return task.adapters[i];
                }
            } catch {}

            unchecked {
                ++i;
            }
        }

        revert("StrategyPathTask: Adapter for target contract not found");
    }

    function isolateAdapter(StrategyPathTask memory task, uint256 adapterIndex) internal pure {
        address[] memory newAdapters = new address[](1);
        newAdapters[0] = task.adapters[adapterIndex];
        task.adapters = newAdapters;
    }

    function getTokenDepositAdapter(StrategyPathTask memory task, address token)
        internal
        pure
        returns (address adapter)
    {
        for (uint256 i; i < task.foundAdapters.length;) {
            if (task.foundAdapters[i].token == token) {
                return task.foundAdapters[i].depositAdapter;
            }

            unchecked {
                ++i;
            }
        }
    }

    function getTokenWithdrawAdapter(StrategyPathTask memory task, address token)
        internal
        pure
        returns (address adapter)
    {
        for (uint256 i; i < task.foundAdapters.length;) {
            if (task.foundAdapters[i].token == token) {
                return task.foundAdapters[i].withdrawAdapter;
            }

            unchecked {
                ++i;
            }
        }
    }

    function addTokenDepositAdapter(StrategyPathTask memory task, address token, address adapter) internal pure {
        uint256 len = task.foundAdapters.length;
        TokenAdapters[] memory res = new TokenAdapters[](len + 1);

        for (uint256 i; i < len;) {
            if (task.foundAdapters[i].token == token) {
                task.foundAdapters[i].depositAdapter = adapter;
                return;
            }
            res[i] = task.foundAdapters[i];
            unchecked {
                ++i;
            }
        }

        res[len] = TokenAdapters({token: token, depositAdapter: adapter, withdrawAdapter: address(0)});
        task.foundAdapters = res;
    }

    function addTokenWithdrawAdapter(StrategyPathTask memory task, address token, address adapter) internal pure {
        uint256 len = task.foundAdapters.length;
        TokenAdapters[] memory res = new TokenAdapters[](len + 1);

        for (uint256 i; i < len;) {
            if (task.foundAdapters[i].token == token) {
                task.foundAdapters[i].withdrawAdapter = adapter;
                return;
            }
            res[i] = task.foundAdapters[i];
            unchecked {
                ++i;
            }
        }

        res[len] = TokenAdapters({token: token, depositAdapter: address(0), withdrawAdapter: adapter});
        task.foundAdapters = res;
    }

    function initSlippageControl(StrategyPathTask memory task) internal pure {
        if (task.calls.length != 0) revert NoSpaceForSlippageCallException();

        task.calls = new MultiCall[](1);
        task.initTargetBalance = task.balances.getBalance(task.target);
    }

    function updateSlippageControl(StrategyPathTask memory task) internal view {
        updateSlippageControl(task, getCreditFacade(task.creditAccount));
    }

    function updateSlippageControl(StrategyPathTask memory task, address creditFacade) internal view {
        BalanceDelta[] memory limit = new BalanceDelta[](1);

        limit[0] = BalanceDelta({
            token: task.target,
            amount: int256(amountOutWithSlippage(task, task.balances.getBalance(task.target) - task.initTargetBalance))
        });

        task.calls[0] = MultiCall({
            target: creditFacade,
            callData: abi.encodeCall(ICreditFacadeV3Multicall.storeExpectedBalances, (limit))
        });

        task.calls = task.calls.append(
            MultiCall({target: creditFacade, callData: abi.encodeCall(ICreditFacadeV3Multicall.compareBalances, ())})
        );
    }

    function getCreditFacade(address creditAccount) private view returns (address creditFacade) {
        // TODO: Not sure this is implemented in the credit facade
        if (creditAccount == address(0)) {
            return 0xFAcAdEfAcadefaCadEfacADeFACAdEfACaDefAce;
        }
        ICreditManagerV3 creditManager = ICreditManagerV3(ICreditAccount(creditAccount).creditManager());

        creditFacade = creditManager.creditFacade();
    }

    function toRouterResult(StrategyPathTask memory task) internal pure returns (RouterResult memory r) {
        r.calls = task.calls;
        r.amount = task.balances.getBalance(task.target) - task.initTargetBalance;
        r.minAmount = amountOutWithSlippage(task, task.balances.getBalance(task.target) - task.initTargetBalance);
        r.gasUsage = task.gasUsage;
    }

    function isBetter(StrategyPathTask memory task1, StrategyPathTask memory task2) internal pure returns (bool) {
        if (task1.target != task2.target || task1.gasPriceTargetRAY != task2.gasPriceTargetRAY) {
            revert DifferentTargetComparisonException();
        }

        uint256 amount1 = task1.balances.getBalance(task1.target);
        uint256 amount2 = task2.balances.getBalance(task2.target);
        return safeIsGreater(
            amount1,
            (task1.gasUsage * task1.gasPriceTargetRAY) / RAY,
            amount2,
            (task2.gasUsage * task2.gasPriceTargetRAY) / RAY
        );
    }

    function safeIsGreater(uint256 amount1, uint256 gasCost1, uint256 amount2, uint256 gasCost2)
        internal
        pure
        returns (bool isGreater)
    {
        if (amount1 >= gasCost1 && amount2 >= gasCost2) {
            return (amount1 - gasCost1) > (amount2 - gasCost2);
        }

        int256 diff1 = int256(amount1) - int256(gasCost1);
        int256 diff2 = int256(amount2) - int256(gasCost2);

        return diff1 > diff2;
    }

    function clone(StrategyPathTask memory task) internal pure returns (StrategyPathTask memory) {
        return StrategyPathTask({
            creditAccount: task.creditAccount,
            balances: task.balances.clone(),
            leftoverBalances: task.leftoverBalances.clone(),
            target: task.target,
            connectors: task.connectors,
            adapters: task.adapters,
            slippage: task.slippage,
            targetType: task.targetType,
            foundAdapters: task.foundAdapters,
            gasPriceTargetRAY: task.gasPriceTargetRAY,
            gasUsage: task.gasUsage,
            initTargetBalance: task.initTargetBalance,
            calls: task.calls.clone(),
            force: task.force
        });
    }

    function trim(StrategyPathTask[] memory tasks) internal pure returns (StrategyPathTask[] memory) {
        uint256 foundLen;

        for (uint256 i = 0; i < tasks.length; ++i) {
            if (tasks[i].calls.length > 0) ++foundLen;
        }

        StrategyPathTask[] memory trimmed = new StrategyPathTask[](foundLen);

        for (uint256 i = 0; i < foundLen; ++i) {
            trimmed[i] = tasks[i];
        }

        return trimmed;
    }
}
