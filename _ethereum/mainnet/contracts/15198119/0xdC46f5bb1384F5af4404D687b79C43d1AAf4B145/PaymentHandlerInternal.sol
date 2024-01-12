/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./PaymentHandlerStorage.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
library PaymentHandlerInternal {

    bytes32 constant public WEI_PAYMENT_METHOD_HASH = keccak256(abi.encode("WEI"));

    event WeiPayment(address payer, address dest, uint256 amountWei);
    event ERC20Payment(
        string paymentMethodName,
        address payer,
        address dest,
        uint256 amountWei,
        uint256 amountTokens
    );
    event TransferTo(address to, uint256 amount, string data);
    event TransferETH20To(string paymentMethodName, address to, uint256 amount, string data);

    function _getPaymentSettings() internal view returns (address, address) {
        return (__s().payoutAddress, __s().wethAddress);
    }

    function _setPaymentSettings(
        address payoutAddress,
        address wethAddress
    ) internal {
        __s().payoutAddress = payoutAddress;
        __s().wethAddress = wethAddress;
    }

    function _getERC20PaymentMethods() internal view returns (string[] memory) {
        return __s().erc20PaymentMethodNames;
    }

    function _getERC20PaymentMethodInfo(
        string memory paymentMethodName
    ) internal view returns (address, address, bool) {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PH:NEM");
        return (
            __s().erc20PaymentMethods[nameHash].addr,
            __s().erc20PaymentMethods[nameHash].wethPair,
            __s().erc20PaymentMethods[nameHash].enabled
        );
    }

    function _addOrUpdateERC20PaymentMethod(
        string memory paymentMethodName,
        address addr,
        address wethPair
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        __s().erc20PaymentMethods[nameHash].addr = addr;
        __s().erc20PaymentMethods[nameHash].wethPair = wethPair;
        address token0 = IUniswapV2Pair(wethPair).token0();
        address token1 = IUniswapV2Pair(wethPair).token1();
        require(token0 == __s().wethAddress || token1 == __s().wethAddress, "PH:IPC");
        bool reverseIndices = (token1 == __s().wethAddress);
        __s().erc20PaymentMethods[nameHash].reverseIndices = reverseIndices;
        __s().erc20PaymentMethodNames.push(paymentMethodName);
    }

    function _enableERC20TokenPayment(
        string memory paymentMethodName,
        bool enabled
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PH:NEM");
        __s().erc20PaymentMethods[nameHash].enabled = enabled;
    }

    function _transferTo(
        string memory paymentMethodName,
        address to,
        uint256 amount,
        string memory data
    ) internal {
        require(to != address(0), "PH:TTZ");
        require(amount > 0, "PH:ZAM");
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH || _paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            require(amount <= address(this).balance, "PH:MTB");
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = to.call{value: amount}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:TF");
            emit TransferTo(to, amount, data);
        } else {
            PaymentHandlerStorage.ERC20PaymentMethodInfo memory paymentMethod =
                __s().erc20PaymentMethods[nameHash];
            require(
                amount <= IERC20(paymentMethod.addr).balanceOf(address(this)),
                "PH:MTB"
            );
            IERC20(paymentMethod.addr).transfer(to, amount);
            emit TransferETH20To(paymentMethodName, to, amount, data);
        }
    }

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        uint256 totalWei =
            nrOfItems1 * priceWeiPerItem1 +
            nrOfItems2 * priceWeiPerItem2;
        if (totalWei == 0) {
            return;
        }
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH ||
                _paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            _handleWeiPayment(totalWei);
        } else {
            _handleERC20Payment(totalWei, paymentMethodName);
        }
    }

    function _paymentMethodExists(bytes32 paymentMethodNameHash) private view returns (bool) {
        return __s().erc20PaymentMethods[paymentMethodNameHash].addr != address(0) &&
               __s().erc20PaymentMethods[paymentMethodNameHash].wethPair != address(0) &&
               __s().erc20PaymentMethods[paymentMethodNameHash].enabled;
    }

    function _handleWeiPayment(
        uint256 priceWeiToPay
    ) private {
        require(msg.value >= priceWeiToPay, "PH:IF");
        uint256 remainder = msg.value - priceWeiToPay;
        if (__s().payoutAddress != address(0)) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = __s().payoutAddress.call{value: priceWeiToPay}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:TF");
            emit WeiPayment(msg.sender, __s().payoutAddress, priceWeiToPay);
        } else {
            emit WeiPayment(msg.sender, address(this), priceWeiToPay);
        }
        if (remainder > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = msg.sender.call{value: remainder}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:RTF");
        }
    }

    function _handleERC20Payment(
        uint256 priceWeiToPay,
        string memory paymentMethodName
    ) private {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        PaymentHandlerStorage.ERC20PaymentMethodInfo memory paymentMethod =
            __s().erc20PaymentMethods[nameHash];
        (uint112 amount0, uint112 amount1,) = IUniswapV2Pair(paymentMethod.wethPair).getReserves();
        uint256 reserveWei = amount0;
        uint256 reserveTokens = amount1;
        if (paymentMethod.reverseIndices) {
            reserveWei = amount1;
            reserveTokens = amount0;
        }
        require(reserveWei > 0, "PH:NWR");
        uint256 amountTokens = (priceWeiToPay * reserveTokens) / reserveWei;
        address dest = address(this);
        if (__s().payoutAddress != address(0)) {
            dest = __s().payoutAddress;
        }
        // this contract must have already been approved by the msg.sender
        IERC20(paymentMethod.addr).transferFrom(msg.sender, dest, amountTokens);
        emit ERC20Payment(paymentMethodName, msg.sender, dest, priceWeiToPay, amountTokens);
    }

    function __s() private pure returns (PaymentHandlerStorage.Layout storage) {
        return PaymentHandlerStorage.layout();
    }
}
