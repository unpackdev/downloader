// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./CoreStructs.sol";
import "./IStargateRouter.sol";

interface ICore {
    /*
     * @dev Only Stargate Router can perform this operation.
     */
    error OnlyStargateRouter();

    /**
     * @dev Swaps currency from the incoming to the outgoing token and executes a transaction with payment.
     * @param target The address of the target contract for the payment transaction.
     * @param paymentOperator The operator address for payment transfers requiring erc20 approvals.
     * @param tokenData The token swap data and payment transaction payload
     */
    function swapAndExecute(address target, address paymentOperator, TokenData calldata tokenData) external payable;

    /**
     * @dev Bridges funds in native or erc20 and a payment transaction payload to the destination chain
     * @param lzBridgeData The configuration for the cross bridge transaction
     * @param tokenData The token swap data and payment transaction payload
     * @param lzTxObj The configuration of gas and dust for post bridge execution
     */
    function bridgeAndExecute(
        LzBridgeData calldata lzBridgeData,
        TokenData calldata tokenData,
        IStargateRouter.lzTxObj calldata lzTxObj
    ) external payable;
}
