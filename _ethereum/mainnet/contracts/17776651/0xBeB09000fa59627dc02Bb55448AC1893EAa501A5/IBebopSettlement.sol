// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Order.sol";
import "./Signature.sol";

interface IBebopSettlement {
    event AggregateOrderExecuted(bytes32 order_hash);

    function SettleAggregateOrder(
        Order.Aggregate memory order,
        Signature.TypedSignature memory takerSig,
        Signature.MakerSignatures[] memory makerSigs
    ) external payable returns (bool);

    function SettleAggregateOrderWithTakerPermits(
        Order.Aggregate memory order,
        Signature.TypedSignature memory takerSig,
        Signature.MakerSignatures[] memory makerSigs,
        Signature.TakerPermitsInfo memory takerPermitInfo
    ) external payable returns (bool);

}