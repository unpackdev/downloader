// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./Utils.sol";
import "./IBalancerV2Vault.sol";

contract SwaapV2 {
    using SafeMath for uint256;

    struct BalancerBatchData {
        IBalancerV2Vault.BatchSwapStep[] swaps;
        address[] assets;
        IBalancerV2Vault.FundManagement funds;
        int256[] limits;
    }

    struct BalancerSimpleData {
        IBalancerV2Vault.SingleSwap singleSwap;
        IBalancerV2Vault.FundManagement funds;
        uint256 limit;
    }

    function substituteCallerOrigin(bytes memory swapUserData, uint256 memorySlot) public view {
        if(swapUserData.length >= memorySlot.add(32)) {
            assembly {
                let swapUserDataPtr := add(swapUserData, 0x20) // first 32 bytes corresponds to length
                let callerPtr := add(swapUserDataPtr, memorySlot)
                mstore(callerPtr, caller())
            }
        }
    }

    function swapOnSwaapV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address vault,
        bytes calldata payload
    ) internal {

        (bool isBatchSwap) = abi.decode(payload, (bool));

        if(isBatchSwap) {

            (,
            uint256[] memory callerSlots,
            BalancerBatchData memory data
            ) = abi.decode(payload, (bool, uint256[], BalancerBatchData));

            uint256 totalSwaps = data.swaps.length;
            require(data.swaps.length == callerSlots.length);

            uint256 totalAmount;
            for (uint256 i = 0; i < totalSwaps; ++i) {
                IBalancerV2Vault.BatchSwapStep memory swap = data.swaps[i];
                substituteCallerOrigin(swap.userData, callerSlots[i]);
                totalAmount = totalAmount.add(swap.amount);
            }

            // This will only work for a direct swap on balancer
            if (totalAmount != fromAmount) {
                for (uint256 i = 0; i < totalSwaps; ++i) {
                    data.swaps[i].amount = data.swaps[i].amount.mul(fromAmount).div(totalAmount);
                }
            }

            if (address(fromToken) == Utils.ethAddress()) {
                IBalancerV2Vault(vault).batchSwap{ value: fromAmount }(
                    IBalancerV2Vault.SwapKind.GIVEN_IN,
                    data.swaps,
                    data.assets,
                    data.funds,
                    data.limits,
                    block.timestamp
                );
            } else {
                Utils.approve(vault, address(fromToken), fromAmount);
                IBalancerV2Vault(vault).batchSwap(
                    IBalancerV2Vault.SwapKind.GIVEN_IN,
                    data.swaps,
                    data.assets,
                    data.funds,
                    data.limits,
                    block.timestamp
                );
            }

        } else {

            (, uint256 callerSlot, BalancerSimpleData memory data) = abi.decode(payload, (bool, uint256, BalancerSimpleData));

            substituteCallerOrigin(data.singleSwap.userData, callerSlot);

            data.singleSwap.amount = fromAmount;

            if (address(fromToken) == Utils.ethAddress()) {
                IBalancerV2Vault(vault).swap{ value: fromAmount }(
                    data.singleSwap,
                    data.funds,
                    data.limit,
                    block.timestamp
                );
            } else {
                Utils.approve(vault, address(fromToken), fromAmount);
                IBalancerV2Vault(vault).swap(
                    data.singleSwap,
                    data.funds,
                    data.limit,
                    block.timestamp
                );
            }
        }
    }

    function buyOnSwaapV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address vault,
        bytes calldata payload
    ) internal {

        (bool isBatchSwap) = abi.decode(payload, (bool));

        if(isBatchSwap) {

            (,
            uint256[] memory callerSlots,
            BalancerBatchData memory data
            ) = abi.decode(payload, (bool, uint256[], BalancerBatchData));

            uint256 totalSwaps = data.swaps.length;
            require(data.swaps.length == callerSlots.length);

            uint256 totalAmount;
            for (uint256 i = 0; i < totalSwaps; ++i) {
                IBalancerV2Vault.BatchSwapStep memory swap = data.swaps[i];
                substituteCallerOrigin(swap.userData, callerSlots[i]);
                totalAmount = totalAmount.add(swap.amount);
            }

            // This will only work for a direct swap on balancer
            if (totalAmount != toAmount) {
                for (uint256 i = 0; i < totalSwaps; ++i) {
                    data.swaps[i].amount = data.swaps[i].amount.mul(toAmount).div(totalAmount);
                }
            }

            if (address(fromToken) == Utils.ethAddress()) {
                IBalancerV2Vault(vault).batchSwap{ value: fromAmount }(
                    IBalancerV2Vault.SwapKind.GIVEN_OUT,
                    data.swaps,
                    data.assets,
                    data.funds,
                    data.limits,
                    block.timestamp
                );
            } else {
                Utils.approve(vault, address(fromToken), fromAmount);
                IBalancerV2Vault(vault).batchSwap(
                    IBalancerV2Vault.SwapKind.GIVEN_OUT,
                    data.swaps,
                    data.assets,
                    data.funds,
                    data.limits,
                    block.timestamp
                );
            }

        } else {

            (, uint256 callerSlot, BalancerSimpleData memory data) = abi.decode(payload, (bool, uint256, BalancerSimpleData));

            substituteCallerOrigin(data.singleSwap.userData, callerSlot);

            data.singleSwap.amount = toAmount;
            data.limit = fromAmount;

            if (address(fromToken) == Utils.ethAddress()) {
                IBalancerV2Vault(vault).swap{ value: fromAmount }(
                    data.singleSwap,
                    data.funds,
                    data.limit,
                    block.timestamp
                );
            } else {
                Utils.approve(vault, address(fromToken), fromAmount);
                IBalancerV2Vault(vault).swap(
                    data.singleSwap,
                    data.funds,
                    data.limit,
                    block.timestamp
                );
            }
        }
    }
}
