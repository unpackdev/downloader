// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LibAsset.sol";
import "./LibOrder.sol";

// https://github.com/rarible/protocol-contracts/blob/822142af31e15c8f81f59b47a57d4923141498ae/exchange-v2/contracts/ExchangeV2Core.sol
interface IRaribleExchangeV2 {
    event Match(
        bytes32 leftHash,
        bytes32 rightHash,
        address leftMaker,
        address rightMaker,
        uint newLeftFill,
        uint newRightFill,
        LibAsset.AssetType leftAsset,
        LibAsset.AssetType rightAsset
    );

    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external payable;
}
