// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IERC20.sol";

import "./Utils.sol";
import "./IBalancerV2Vault.sol";

contract BalancerV2 {
    using SafeMath for uint256;

    struct BalancerV2Data {
        IBalancerV2Vault.BatchSwapStep[] swaps;
        address[] assets;
        IBalancerV2Vault.FundManagement funds;
        int256[] limits;
        uint256 deadline;
    }

    function swapOnBalancerV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address vault,
        bytes calldata payload
    ) internal {
        BalancerV2Data memory data = abi.decode(payload, (BalancerV2Data));

        uint256 totalAmount;
        for (uint256 i = 0; i < data.swaps.length; ++i) {
            totalAmount = totalAmount.add(data.swaps[i].amount);
        }

        // This will only work for a direct swap on balancer
        if (totalAmount != fromAmount) {
            for (uint256 i = 0; i < data.swaps.length; ++i) {
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
                data.deadline
            );
        } else {
            Utils.approve(vault, address(fromToken), fromAmount);
            IBalancerV2Vault(vault).batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                data.swaps,
                data.assets,
                data.funds,
                data.limits,
                data.deadline
            );
        }
    }

    function buyOnBalancerV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address vault,
        bytes calldata payload
    ) internal {
        BalancerV2Data memory data = abi.decode(payload, (BalancerV2Data));

        if (address(fromToken) == Utils.ethAddress()) {
            IBalancerV2Vault(vault).batchSwap{ value: fromAmount }(
                IBalancerV2Vault.SwapKind.GIVEN_OUT,
                data.swaps,
                data.assets,
                data.funds,
                data.limits,
                data.deadline
            );
        } else {
            Utils.approve(vault, address(fromToken), fromAmount);
            IBalancerV2Vault(vault).batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_OUT,
                data.swaps,
                data.assets,
                data.funds,
                data.limits,
                data.deadline
            );
        }
    }
}
