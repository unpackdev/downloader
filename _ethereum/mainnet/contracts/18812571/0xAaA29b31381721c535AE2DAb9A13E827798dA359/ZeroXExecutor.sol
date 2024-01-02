// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./I0xExchangeRouter.sol";
import "./IExecutor.sol";
import "./VaultBaseExternal.sol";
import "./Registry.sol";

import "./Call.sol";
import "./Constants.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IERC20Metadata.sol";

contract ZeroXExecutor is IExecutor {
    using SafeERC20 for IERC20;

    bool public constant override requiresCPIT = true;

    // This function is called by the vault via delegatecall cannot access state of this contract
    function swap(
        address sellTokenAddress,
        uint sellAmount,
        address buyTokenAddress,
        uint buyAmount,
        bytes memory zeroXSwapData
    ) external {
        Registry registry = VaultBaseExternal(payable(address(this)))
            .registry();
        require(
            registry.deprecatedAssets(buyTokenAddress) == false,
            'ZeroXExecutor: OutputToken is deprecated'
        );
        require(
            registry.hardDeprecatedAssets(buyTokenAddress) == false,
            'ZeroXExecutor: OutputToken is hard deprecated'
        );

        address _0xExchangeRouter = registry.zeroXExchangeRouter();

        IERC20(sellTokenAddress).approve(_0xExchangeRouter, sellAmount);

        uint balanceBefore = IERC20(buyTokenAddress).balanceOf(address(this));
        // Blindly execute the call to the 0x exchange router
        Call._call(_0xExchangeRouter, zeroXSwapData);

        uint balanceAfter = IERC20(buyTokenAddress).balanceOf(address(this));
        uint amountReceived = balanceAfter - balanceBefore;

        require(
            amountReceived >= buyAmount,
            'ZeroXExecutor: Not enough received'
        );

        uint unitPrice = (amountReceived * Constants.VAULT_PRECISION) /
            sellAmount;

        VaultBaseExternal(payable(address(this))).updateActiveAsset(
            sellTokenAddress
        );
        VaultBaseExternal(payable(address(this))).addActiveAsset(
            buyTokenAddress
        );
        registry.emitEvent();
        emit ZeroXSwap(
            sellTokenAddress,
            sellAmount,
            buyTokenAddress,
            buyAmount,
            amountReceived,
            unitPrice
        );
    }
}
