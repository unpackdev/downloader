// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./JamBalanceManager.sol";
import "./JamSigning.sol";
import "./JamTransfer.sol";
import "./IJamBalanceManager.sol";
import "./IJamSettlement.sol";
import "./JamInteraction.sol";
import "./JamOrder.sol";
import "./JamHooks.sol";
import "./ExecInfo.sol";
import "./BMath.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";

/// @title JamSettlement
/// @notice The settlement contract executes the full lifecycle of a trade on chain.
/// Solvers figure out what "interactions" to pass to this contract such that the user order is fulfilled.
/// The contract ensures that only the user agreed price can be executed and otherwise will fail to execute.
/// As long as the trade is fulfilled, the solver is allowed to keep any potential excess.
contract JamSettlement is IJamSettlement, ReentrancyGuard, JamSigning, JamTransfer, ERC721Holder, ERC1155Holder {

    IJamBalanceManager public immutable balanceManager;

    constructor(address _permit2, address _daiAddress) {
        balanceManager = new JamBalanceManager(address(this), _permit2, _daiAddress);
    }

    receive() external payable {}

    function runInteractions(JamInteraction.Data[] calldata interactions) internal returns (bool result) {
        for (uint i; i < interactions.length; ++i) {
            // Prevent calls to balance manager
            require(interactions[i].to != address(balanceManager));
            bool execResult = JamInteraction.execute(interactions[i]);

            // Return false only if interaction was meant to succeed but failed.
            if (!execResult && interactions[i].result) return false;
        }
        return true;
    }

    /// @inheritdoc IJamSettlement
    function settle(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def calldata hooks,
        ExecInfo.SolverData calldata solverData
    ) external payable nonReentrant {
        validateOrder(order, hooks, signature, solverData.curFillPercent);
        require(runInteractions(hooks.beforeSettle), "BEFORE_SETTLE_HOOKS_FAILED");
        balanceManager.transferTokens(
            IJamBalanceManager.TransferData(
                order.taker, solverData.balanceRecipient, order.sellTokens, order.sellAmounts,
                order.sellNFTIds, order.sellTokenTransfers, solverData.curFillPercent
            )
        );
        _settle(order, interactions, hooks, solverData.curFillPercent);
    }

    /// @inheritdoc IJamSettlement
    function settleWithPermitsSignatures(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        Signature.TakerPermitsInfo calldata takerPermitsInfo,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def calldata hooks,
        ExecInfo.SolverData calldata solverData
    ) external payable nonReentrant {
        validateOrder(order, hooks, signature, solverData.curFillPercent);
        require(runInteractions(hooks.beforeSettle), "BEFORE_SETTLE_HOOKS_FAILED");
        balanceManager.transferTokensWithPermits(
            IJamBalanceManager.TransferData(
                order.taker, solverData.balanceRecipient, order.sellTokens, order.sellAmounts,
                order.sellNFTIds, order.sellTokenTransfers, solverData.curFillPercent
            ), takerPermitsInfo
        );
        _settle(order, interactions, hooks, solverData.curFillPercent);
    }

    /// @inheritdoc IJamSettlement
    function settleInternal(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        JamHooks.Def calldata hooks,
        ExecInfo.MakerData calldata makerData
    ) external payable nonReentrant {
        validateOrder(order, hooks, signature, makerData.curFillPercent);
        require(runInteractions(hooks.beforeSettle), "BEFORE_SETTLE_HOOKS_FAILED");
        balanceManager.transferTokens(
            IJamBalanceManager.TransferData(
                order.taker, msg.sender, order.sellTokens, order.sellAmounts,
                order.sellNFTIds, order.sellTokenTransfers, makerData.curFillPercent
            )
        );
        _settleInternal(order, hooks, makerData);
    }

    /// @inheritdoc IJamSettlement
    function settleInternalWithPermitsSignatures(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        Signature.TakerPermitsInfo calldata takerPermitsInfo,
        JamHooks.Def calldata hooks,
        ExecInfo.MakerData calldata makerData
    ) external payable nonReentrant {
        validateOrder(order, hooks, signature, makerData.curFillPercent);
        require(runInteractions(hooks.beforeSettle), "BEFORE_SETTLE_HOOKS_FAILED");
        balanceManager.transferTokensWithPermits(
            IJamBalanceManager.TransferData(
                order.taker, msg.sender, order.sellTokens, order.sellAmounts,
                order.sellNFTIds, order.sellTokenTransfers, makerData.curFillPercent
            ), takerPermitsInfo
        );
        _settleInternal(order, hooks, makerData);
    }

    /// @inheritdoc IJamSettlement
    function settleBatch(
        JamOrder.Data[] calldata orders,
        Signature.TypedSignature[] calldata signatures,
        Signature.TakerPermitsInfo[] calldata takersPermitsInfo,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def[] calldata hooks,
        ExecInfo.BatchSolverData calldata solverData
    ) external payable nonReentrant {
        validateBatchOrders(orders, hooks, signatures, takersPermitsInfo, solverData.takersPermitsUsage, solverData.curFillPercents);
        bool isMaxFill = solverData.curFillPercents.length == 0;
        bool executeHooks = hooks.length != 0;
        uint takersPermitsInd;
        for (uint i; i < orders.length; ++i) {
            if (executeHooks){
                require(runInteractions(hooks[i].beforeSettle), "BEFORE_SETTLE_HOOKS_FAILED");
            }
            if (solverData.takersPermitsUsage.length != 0 && solverData.takersPermitsUsage[i]){
                balanceManager.transferTokensWithPermits(
                    IJamBalanceManager.TransferData(
                        orders[i].taker, solverData.balanceRecipient, orders[i].sellTokens, orders[i].sellAmounts,
                        orders[i].sellNFTIds, orders[i].sellTokenTransfers, isMaxFill ? BMath.HUNDRED_PERCENT : solverData.curFillPercents[i]
                    ), takersPermitsInfo[takersPermitsInd++]
                );
            } else {
                balanceManager.transferTokens(
                    IJamBalanceManager.TransferData(
                        orders[i].taker, solverData.balanceRecipient, orders[i].sellTokens, orders[i].sellAmounts,
                        orders[i].sellNFTIds, orders[i].sellTokenTransfers, isMaxFill ? BMath.HUNDRED_PERCENT : solverData.curFillPercents[i]
                    )
                );
            }
        }
        require(runInteractions(interactions), "INTERACTIONS_FAILED");
        for (uint i; i < orders.length; ++i) {
            uint256[] memory curBuyAmounts = solverData.transferExactAmounts ?
                orders[i].buyAmounts : calculateNewAmounts(i, orders, solverData.curFillPercents);
            transferTokensFromContract(
                orders[i].buyTokens, curBuyAmounts, orders[i].buyNFTIds, orders[i].buyTokenTransfers,
                orders[i].receiver, isMaxFill ? BMath.HUNDRED_PERCENT : solverData.curFillPercents[i], true
            );
            if (executeHooks){
                require(runInteractions(hooks[i].afterSettle), "AFTER_SETTLE_HOOKS_FAILED");
            }
            emit Settlement(orders[i].nonce);
        }
    }

    function _settle(
        JamOrder.Data calldata order,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def calldata hooks,
        uint16 curFillPercent
    ) private {
        require(runInteractions(interactions), "INTERACTIONS_FAILED");
        transferTokensFromContract(
            order.buyTokens, order.buyAmounts, order.buyNFTIds, order.buyTokenTransfers, order.receiver, curFillPercent, false
        );
        if (order.receiver == address(this)){
            require(!hasDuplicate(order.buyTokens, order.buyNFTIds, order.buyTokenTransfers), "DUPLICATE_TOKENS");
            require(hooks.afterSettle.length > 0, "AFTER_SETTLE_HOOKS_REQUIRED");
            for (uint i; i < hooks.afterSettle.length; ++i){
                require(hooks.afterSettle[i].result, "POTENTIAL_TOKENS_LOSS");
            }
        }
        require(runInteractions(hooks.afterSettle), "AFTER_SETTLE_HOOKS_FAILED");
        emit Settlement(order.nonce);
    }

    function _settleInternal(
        JamOrder.Data calldata order,
        JamHooks.Def calldata hooks,
        ExecInfo.MakerData calldata makerData
    ) private {
        uint256[] calldata buyAmounts = validateIncreasedAmounts(makerData.increasedBuyAmounts, order.buyAmounts);
        balanceManager.transferTokens(
            IJamBalanceManager.TransferData(
                msg.sender, order.receiver, order.buyTokens, buyAmounts,
                order.buyNFTIds, order.buyTokenTransfers, makerData.curFillPercent
            )
        );
        require(runInteractions(hooks.afterSettle), "AFTER_SETTLE_HOOKS_FAILED");
        emit Settlement(order.nonce);
    }
}