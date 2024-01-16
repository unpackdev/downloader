// SPDX-License-Identifier: Apache-2.0

/*
    Copyright 2022 0xPlasma Alliance
*/

/***
 *      ______             _______   __                                             
 *     /      \           |       \ |  \                                            
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______  
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \ 
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *                                                                                  
 *                                                                                  
 *                                                                                  
 */

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./LibRichErrorsV06.sol";
import "./LibSafeMathV06.sol";
import "./LibMathV06.sol";
import "./LibNativeOrdersRichErrors.sol";
import "./FixinCommon.sol";
import "./FixinEIP712.sol";
import "./LibMigrate.sol";
import "./IFeature.sol";
import "./IBatchFillNativeOrdersFeature.sol";
import "./INativeOrdersFeature.sol";
import "./LibNativeOrder.sol";
import "./LibSignature.sol";


/// @dev Feature for batch/market filling limit and RFQ orders.
contract BatchFillNativeOrdersFeature is
    IFeature,
    IBatchFillNativeOrdersFeature,
    FixinCommon,
    FixinEIP712
{
    using LibSafeMathV06 for uint128;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "BatchFill";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 1, 0);

    constructor(address zeroXPAddress)
        public
        FixinEIP712(zeroXPAddress)
    {
        // solhint-disable no-empty-blocks
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate()
        external
        returns (bytes4 success)
    {
        _registerFeatureFunction(this.batchFillLimitOrders.selector);
        _registerFeatureFunction(this.batchFillRfqOrders.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Fills multiple limit orders.
    /// @param orders Array of limit orders.
    /// @param signatures Array of signatures corresponding to each order.
    /// @param takerTokenFillAmounts Array of desired amounts to fill each order.
    /// @param revertIfIncomplete If true, reverts if this function fails to
    ///        fill the full fill amount for any individual order.
    /// @return takerTokenFilledAmounts Array of amounts filled, in taker token.
    /// @return makerTokenFilledAmounts Array of amounts filled, in maker token.
    function batchFillLimitOrders(
        LibNativeOrder.LimitOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures,
        uint128[] calldata takerTokenFillAmounts,
        bool revertIfIncomplete
    )
        external
        payable
        override
        returns (
            uint128[] memory takerTokenFilledAmounts,
            uint128[] memory makerTokenFilledAmounts
        )
    {
        require(
            orders.length == signatures.length && orders.length == takerTokenFillAmounts.length,
            'BatchFillNativeOrdersFeature::batchFillLimitOrders/MISMATCHED_ARRAY_LENGTHS'
        );
        takerTokenFilledAmounts = new uint128[](orders.length);
        makerTokenFilledAmounts = new uint128[](orders.length);
        uint256 protocolFee = uint256(INativeOrdersFeature(address(this)).getProtocolFeeMultiplier())
            .safeMul(tx.gasprice);
        uint256 ethProtocolFeePaid;
        for (uint256 i = 0; i != orders.length; i++) {
            try
                INativeOrdersFeature(address(this))._fillLimitOrder
                    (
                        orders[i],
                        signatures[i],
                        takerTokenFillAmounts[i],
                        msg.sender,
                        msg.sender
                    )
                returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount)
            {
                // Update amounts filled.
                (takerTokenFilledAmounts[i], makerTokenFilledAmounts[i]) =
                    (takerTokenFilledAmount, makerTokenFilledAmount);
                ethProtocolFeePaid = ethProtocolFeePaid.safeAdd(protocolFee);
            } catch {}

            if (
                revertIfIncomplete &&
                takerTokenFilledAmounts[i] < takerTokenFillAmounts[i]
            ) {
                bytes32 orderHash = _getEIP712Hash(
                    LibNativeOrder.getLimitOrderStructHash(orders[i])
                );
                // Did not fill the amount requested.
                LibNativeOrdersRichErrors.BatchFillIncompleteError(
                    orderHash,
                    takerTokenFilledAmounts[i],
                    takerTokenFillAmounts[i]
                ).rrevert();
            }
        }
        LibNativeOrder.refundExcessProtocolFeeToSender(ethProtocolFeePaid);
    }

    /// @dev Fills multiple RFQ orders.
    /// @param orders Array of RFQ orders.
    /// @param signatures Array of signatures corresponding to each order.
    /// @param takerTokenFillAmounts Array of desired amounts to fill each order.
    /// @param revertIfIncomplete If true, reverts if this function fails to
    ///        fill the full fill amount for any individual order.
    /// @return takerTokenFilledAmounts Array of amounts filled, in taker token.
    /// @return makerTokenFilledAmounts Array of amounts filled, in maker token.
    function batchFillRfqOrders(
        LibNativeOrder.RfqOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures,
        uint128[] calldata takerTokenFillAmounts,
        bool revertIfIncomplete
    )
        external
        override
        returns (
            uint128[] memory takerTokenFilledAmounts,
            uint128[] memory makerTokenFilledAmounts
        )
    {
        require(
            orders.length == signatures.length && orders.length == takerTokenFillAmounts.length,
            'BatchFillNativeOrdersFeature::batchFillRfqOrders/MISMATCHED_ARRAY_LENGTHS'
        );
        takerTokenFilledAmounts = new uint128[](orders.length);
        makerTokenFilledAmounts = new uint128[](orders.length);
        for (uint256 i = 0; i != orders.length; i++) {
            try
                INativeOrdersFeature(address(this))._fillRfqOrder
                    (
                        orders[i],
                        signatures[i],
                        takerTokenFillAmounts[i],
                        msg.sender,
                        false,
                        msg.sender
                    )
                returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount)
            {
                // Update amounts filled.
                (takerTokenFilledAmounts[i], makerTokenFilledAmounts[i]) =
                    (takerTokenFilledAmount, makerTokenFilledAmount);
            } catch {}

            if (
                revertIfIncomplete &&
                takerTokenFilledAmounts[i] < takerTokenFillAmounts[i]
            ) {
                // Did not fill the amount requested.
                bytes32 orderHash = _getEIP712Hash(
                    LibNativeOrder.getRfqOrderStructHash(orders[i])
                );
                LibNativeOrdersRichErrors.BatchFillIncompleteError(
                    orderHash,
                    takerTokenFilledAmounts[i],
                    takerTokenFillAmounts[i]
                ).rrevert();
            }
        }
    }
}
