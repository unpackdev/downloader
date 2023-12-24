// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./SafeERC20.sol";
import "./ContractOnlyEthRecipient.sol";
import "./ISwapExecutor.sol";
import "./TokenLibrary.sol";
import "./Errors.sol";
import "./Ownable2Step.sol";
import "./IReactorCallback.sol";
import "./ReactorStructs.sol";
import "./TokenLibrary.sol";
import "./RevertReasonParser.sol";
import "./SafeERC20Ext.sol";

contract UniswapXBarterReactorCallback is IReactorCallback {
    using SafeERC20 for IERC20;
    using SafeERC20Ext for IERC20;
    using TokenLibrary for IERC20;

    error MsgSenderIsNotReactor();
    error OnlyExecuteSwapIsAllowed();

    IReactor private immutable reactor;

    constructor(IReactor _reactor)
    {
        reactor = _reactor;
    }

    function reactorCallback(ResolvedOrder[] memory resolvedOrders, bytes memory callbackData)
        external
    {
        if (msg.sender != address(reactor)) {
            revert MsgSenderIsNotReactor();
        }

        (address executor, UniswapXSwapDesciption[] memory multicallData) =
            abi.decode(callbackData, (address, UniswapXSwapDesciption[]));

        for (uint256 i = 0; i < multicallData.length; i++) {
            UniswapXSwapDesciption memory swapDescription = multicallData[i];
            bytes memory data = swapDescription.data;
            bytes32 sig;
            assembly {
                sig := and(mload(add(data, 0x20)), 0xffffffff00000000000000000000000000000000000000000000000000000000)
            }
            if (sig != bytes32(ISwapExecutor.executeSwap.selector)) {
                revert OnlyExecuteSwapIsAllowed();
            }

            // reactorCallback is not payable so source token cannot be native
            swapDescription.sourceToken.safeTransfer(address(executor), swapDescription.sourceAmount);
            (bool success, bytes memory result) = executor.call(data);
            if (!success) {
                string memory reason = RevertReasonParser.parse(
                    result,
                    "UNIX: "
                );
                revert(reason);
            }
        }

        for (uint256 i = 0; i < resolvedOrders.length; i++) {
            for (uint256 j = 0; j < resolvedOrders[i].outputs.length; j++) {
                if (resolvedOrders[i].outputs[j].token.allowance(address(this), msg.sender) == 0) {
                    resolvedOrders[i].outputs[j].token.setAllowance(
                        msg.sender,
                        type(uint256).max
                    );
                }
            }
        }
    }

    function executeEntry(SignedOrder calldata order, bytes calldata callbackData) external {
        reactor.executeWithCallback(order, callbackData);
    }

    function executeBatchEntry(SignedOrder[] calldata orders, bytes calldata callbackData) external {
        reactor.executeBatchWithCallback(orders, callbackData);
    }

    struct UniswapXSwapDesciption {
        IERC20 sourceToken;
        uint256 sourceAmount;
        bytes data;
    }
}
