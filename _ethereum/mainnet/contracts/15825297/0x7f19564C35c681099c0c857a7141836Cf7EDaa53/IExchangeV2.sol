// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

import "./ExchangeV2.sol";

import "./RoyaltiesRegistry.sol";
import "./TransferProxy.sol";
import "./ERC20TransferProxy.sol";

interface IExchangeV2 {
    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external payable;

    function directPurchase(
        LibDirectTransfer.Purchase calldata direct
    ) external payable;
}