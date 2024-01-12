// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IBalancerV2Interfaces.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

abstract contract BalancerV2Executor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function swapBalancerV2(
        uint256 amountSpecified,
        bytes32 poolId,
        address payable recipient,
        IVault vault,
        IERC20 sourceToken,
        IERC20 targetToken
    ) external {
        sourceToken.safeApprove(address(vault), amountSpecified);
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap(
            poolId,
            IVault.SwapKind.GIVEN_IN,
            sourceToken,
            targetToken,
            amountSpecified,
            ""
        );
        IVault.FundManagement memory funds = IVault.FundManagement(
            address(this),
            false,
            recipient,
            false
        );
        vault.swap(singleSwap, funds, 1, type(uint256).max);
    }
}
