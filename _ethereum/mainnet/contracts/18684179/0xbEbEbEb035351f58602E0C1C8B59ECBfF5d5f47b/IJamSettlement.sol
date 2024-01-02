// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./JamInteraction.sol";
import "./JamOrder.sol";
import "./JamHooks.sol";
import "./Signature.sol";
import "./ExecInfo.sol";

interface IJamSettlement {

    /// @dev Event emitted when a settlement is executed successfully
    event Settlement(uint256 indexed nonce);

    /// @dev Settle a jam order.
    /// Pulls sell tokens into the contract and ensures that after running interactions receiver has the minimum of buy
    /// @param order user signed order
    /// @param signature user signature
    /// @param interactions list of interactions to settle the order
    /// @param hooks pre and post interactions
    /// @param solverData solver specifies this data by itself
    function settle(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def calldata hooks,
        ExecInfo.SolverData calldata solverData
    ) external payable;

    /// @dev Settle a jam order using taker's Permit/Permit2 signatures
    /// Pulls sell tokens into the contract and ensures that after running interactions receiver has the minimum of buy
    /// @param order user signed order
    /// @param signature user signature
    /// @param takerPermitsInfo taker information about permit and permit2
    /// @param interactions list of interactions to settle the order
    /// @param hooks pre and post interactions
    /// @param solverData solver specifies this data by itself
    function settleWithPermitsSignatures(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        Signature.TakerPermitsInfo calldata takerPermitsInfo,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def calldata hooks,
        ExecInfo.SolverData calldata solverData
    ) external payable;

    /// @dev Settle a jam order.
    /// Pulls sell tokens into the contract and ensures that after running interactions receiver has the minimum of buy
    /// @param order user signed order
    /// @param signature user signature
    /// @param hooks pre and post interactions
    /// @param makerData maker specifies this data by itself
    function settleInternal(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        JamHooks.Def calldata hooks,
        ExecInfo.MakerData calldata makerData
    ) external payable;

    /// @dev Settle a jam order using taker's Permit/Permit2 signatures
    /// Pulls sell tokens into the contract and ensures that after running interactions receiver has the minimum of buy
    /// @param order user signed order
    /// @param signature user signature
    /// @param takerPermitsInfo taker information about permit and permit2
    /// @param hooks pre and post interactions
    /// @param makerData maker specifies this data by itself
    function settleInternalWithPermitsSignatures(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        Signature.TakerPermitsInfo calldata takerPermitsInfo,
        JamHooks.Def calldata hooks,
        ExecInfo.MakerData calldata makerData
    ) external payable;

    /// @dev Settle a batch of orders.
    /// Pulls sell tokens into the contract and ensures that after running interactions receivers have the minimum of buy
    /// @param orders takers signed orders
    /// @param signatures takers signatures
    /// @param takersPermitsInfo takers information about permit and permit2
    /// @param interactions list of interactions to settle the order
    /// @param hooks pre and post takers interactions
    /// @param solverData solver specifies this data by itself
    function settleBatch(
        JamOrder.Data[] calldata orders,
        Signature.TypedSignature[] calldata signatures,
        Signature.TakerPermitsInfo[] calldata takersPermitsInfo,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def[] calldata hooks,
        ExecInfo.BatchSolverData calldata solverData
    ) external payable;
}