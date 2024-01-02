// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";

import "./Utils.sol";
import "./IModule.sol";
import "./ICyanPaymentPlanV2.sol";
import "./IWETH.sol";

import "./AddressProvider.sol";

/// @title Cyan Wallet's Cyan Payment Plan Module - A Cyan wallet's Cyan Payment Plan handling module.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract CyanPaymentPlanV2Module is IModule {
    AddressProvider private constant addressProvider = AddressProvider(0xCF9A19D879769aDaE5e4f31503AAECDa82568E55);

    /// @inheritdoc IModule
    function handleTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable override returns (bytes memory) {
        return Utils._execute(to, value, data);
    }

    function autoPay(
        uint256 planId,
        uint256 payAmount,
        uint8 autoRepayStatus
    ) external payable {
        ICyanPaymentPlanV2 paymentPlanContract = ICyanPaymentPlanV2(msg.sender);
        address currencyAddress = paymentPlanContract.getCurrencyAddressByPlanId(planId);
        if (currencyAddress == address(0)) {
            if (autoRepayStatus == 2) {
                // Auto-repaying from main wallet
                address wethAddress = addressProvider.addresses("WETH");
                if (wethAddress == address(0)) revert AddressProvider.AddressNotFound("WETH");

                IWETH weth = IWETH(wethAddress);
                require(weth.balanceOf(address(this)) >= payAmount, "Not enough ETH in the wallet.");
                weth.withdraw(payAmount);
            } else {
                require(address(this).balance >= payAmount, "Not enough ETH in the wallet.");
            }

            paymentPlanContract.pay{ value: payAmount }(planId, false);
        } else {
            IERC20 erc20 = IERC20(currencyAddress);
            require(erc20.balanceOf(address(this)) >= payAmount, "Not enough balance in the wallet.");

            address conduitAddress = addressProvider.addresses("CYAN_CONDUIT");
            if (erc20.allowance(address(this), conduitAddress) < payAmount) {
                erc20.approve(conduitAddress, type(uint256).max);
            }
            paymentPlanContract.pay(planId, false);
        }
    }
}
