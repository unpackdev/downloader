// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


import "./IBebopSettlement.sol";
import "./IWETH.sol";
import "./IPermit2.sol";
import "./BebopSigning.sol";
import "./BebopTransfer.sol";
import "./Order.sol";
import "./Signature.sol";
import "./Transfer.sol";
import "./Commands.sol";
import "./BytesLib.sol";
import "./SafeCast160.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract BebopSettlement is IBebopSettlement, BebopSigning, BebopTransfer, ReentrancyGuard {

    using SafeERC20 for IERC20;

    constructor(address _wrapped_native_token_address, address _permit, address _dai_address)
        BebopTransfer(_wrapped_native_token_address, _permit, _dai_address){
    }

    receive() external payable {}

    function SettleAggregateOrder(
        Order.Aggregate memory order,
        Signature.TypedSignature memory takerSig,
        Signature.MakerSignatures[] memory makerSigs
    ) external nonReentrant payable override returns (bool) {
        bytes32 h = assertAndInvalidateAggregateOrder(order, takerSig, makerSigs);

        uint numMakerSigs = makerSigs.length;
        Transfer.NativeTokens memory nativeTokens = Transfer.NativeTokens({toTaker: 0, toMakers: 0});
        Transfer.Pending[] memory pendingNativeTokensToMakers = new Transfer.Pending[](numMakerSigs);
        uint commandsInd;
        for (uint i; i < numMakerSigs; ++i) {
            // Batch transfer from maker to taker and accumulate maker's number of native tokens
            nativeTokens.toTaker += makerTransferFunds(
                order.maker_addresses[i], order.receiver, order.maker_tokens[i], order.maker_amounts[i],
                makerSigs[i].usingPermit2, BytesLib.slice(order.commands, commandsInd, order.maker_tokens[i].length)
            );
            commandsInd += order.maker_tokens[i].length;

            for (uint k; k < order.taker_tokens[i].length; ++k) {
                bytes1 curCommand = order.commands[commandsInd + k];
                if (curCommand == Commands.SIMPLE_TRANSFER) {
                    // Transfer taker's token with standard approval
                    IERC20(order.taker_tokens[i][k]).safeTransferFrom(
                        order.taker_address, order.maker_addresses[i], order.taker_amounts[i][k]
                    );
                } else if (curCommand == Commands.NATIVE_TRANSFER) {
                    require(order.taker_tokens[i][k] == WRAPPED_NATIVE_TOKEN, "Taker's token is not native token");
                    // Accumulating taker's number of native tokens
                    nativeTokens.toMakers += order.taker_amounts[i][k];
                    pendingNativeTokensToMakers[i] = Transfer.Pending(
                        order.taker_tokens[i][k], order.maker_addresses[i], order.taker_amounts[i][k]
                    );
                } else if (curCommand == Commands.TRANSFER_FROM_CONTRACT) {
                    // If using contract as an intermediate recipient for tokens transferring
                    IERC20(order.taker_tokens[i][k]).safeTransfer(order.maker_addresses[i], order.taker_amounts[i][k]);
                } else {
                    revert("Unknown command");
                }
            }
            commandsInd += order.taker_tokens[i].length;
        }

        // Wrap taker's native token and transfer to Makers
        if (nativeTokens.toMakers != 0) {
            require(msg.value == nativeTokens.toMakers, "Taker doesn't have enough native tokens");
            IWETH(WRAPPED_NATIVE_TOKEN).deposit{value: nativeTokens.toMakers}();

            for (uint i; i < numMakerSigs; ++i) {
                if (pendingNativeTokensToMakers[i].amount != 0) {
                    IERC20(pendingNativeTokensToMakers[i].token).safeTransfer(
                        pendingNativeTokensToMakers[i].maker_address, pendingNativeTokensToMakers[i].amount
                    );
                }
            }
        }

        // Unwrap and transfer native token to receiver
        if (nativeTokens.toTaker != 0) {
            IWETH(WRAPPED_NATIVE_TOKEN).withdraw(nativeTokens.toTaker);
            (bool sent,) = order.receiver.call{value: nativeTokens.toTaker}("");
            require(sent, "Failed to send Ether to taker");
        }

        emit AggregateOrderExecuted(h);
        return true;
    }


    function SettleAggregateOrderWithTakerPermits(
        Order.Aggregate memory order,
        Signature.TypedSignature memory takerSig,
        Signature.MakerSignatures[] memory makerSigs,
        Signature.TakerPermitsInfo memory takerPermitsInfo
    ) external nonReentrant payable override returns (bool) {
        bytes32 h = assertAndInvalidateAggregateOrder(order, takerSig, makerSigs);

        uint totalTakersTransfers;
        for (uint i; i < order.taker_tokens.length; ++i) {
            totalTakersTransfers += order.taker_tokens[i].length;
        }

        IPermit2.AllowanceTransferDetails[] memory batchTransferDetails = new IPermit2.AllowanceTransferDetails[](totalTakersTransfers);
        IPermit2.PermitDetails[] memory batchToApprove = new IPermit2.PermitDetails[](takerPermitsInfo.noncesPermit2.length);

        Transfer.Pending[] memory pendingTransfersToMakers = new Transfer.Pending[](totalTakersTransfers);
        Transfer.NativeTokens memory nativeTokens = Transfer.NativeTokens({toTaker: 0, toMakers: 0});
        Transfer.Indices memory indices = Transfer.Indices(0, 0, 0, 0, 0);
        for (uint i; i < makerSigs.length; ++i) {
            // Batch transfer from maker to taker and accumulate maker's number of native tokens
            nativeTokens.toTaker += makerTransferFunds(
                order.maker_addresses[i], order.receiver, order.maker_tokens[i], order.maker_amounts[i],
                makerSigs[i].usingPermit2, BytesLib.slice(order.commands, indices.commandsInd, order.maker_tokens[i].length)
            );
            indices.commandsInd += order.maker_tokens[i].length;

            for (uint k; k < order.taker_tokens[i].length; ++k) {
                bytes1 curCommand = order.commands[indices.commandsInd + k];
                if (curCommand == Commands.SIMPLE_TRANSFER) {
                    batchTransferDetails[indices.batchLen++] = IPermit2.AllowanceTransferDetails({
                        from: order.taker_address,
                        to: order.maker_addresses[i],
                        amount: SafeCast160.toUint160(order.taker_amounts[i][k]),
                        token: order.taker_tokens[i][k]
                    });
                } else if (curCommand == Commands.TRANSFER_WITH_PERMIT) {
                    // Transfer taker's token with Permit signature
                    IERC20(order.taker_tokens[i][k]).safeTransferFrom(
                        order.taker_address, order.maker_addresses[i], order.taker_amounts[i][k]
                    );
                    assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
                } else if (curCommand == Commands.PERMIT_THEN_TRANSFER) {
                    permitToken(
                        order.taker_address, order.taker_tokens[i][k],
                        takerPermitsInfo.deadline, takerPermitsInfo.permitSignatures[indices.permitSignaturesInd++]
                    );

                    IERC20(order.taker_tokens[i][k]).safeTransferFrom(
                        order.taker_address, order.maker_addresses[i], order.taker_amounts[i][k]
                    );
                    assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
                } else if (curCommand == Commands.PERMIT2_THEN_TRANSFER) {
                    batchToApprove[indices.batchToApproveInd++] = IPermit2.PermitDetails({
                        token: order.taker_tokens[i][k],
                        amount: type(uint160).max,
                        expiration: takerPermitsInfo.deadline,
                        nonce: takerPermitsInfo.noncesPermit2[indices.batchToApproveInd]
                    });
                    batchTransferDetails[indices.batchLen++] = IPermit2.AllowanceTransferDetails({
                        from: order.taker_address,
                        to: order.maker_addresses[i],
                        amount: SafeCast160.toUint160(order.taker_amounts[i][k]),
                        token: order.taker_tokens[i][k]
                    });
                } else if (curCommand == Commands.NATIVE_TRANSFER) {
                    require(order.taker_tokens[i][k] == WRAPPED_NATIVE_TOKEN, "Taker's token is not native token");
                    // Accumulating taker's number of native tokens
                    nativeTokens.toMakers += order.taker_amounts[i][k];
                    pendingTransfersToMakers[indices.pendingTransfersLen++] = Transfer.Pending(
                        order.taker_tokens[i][k], order.maker_addresses[i], order.taker_amounts[i][k]
                    );
                    // Shortening Permit2 batch arrays
                    assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
                } else if (curCommand == Commands.TRANSFER_FROM_CONTRACT) {
                    // If using contract as an intermediate recipient for tokens transferring
                    pendingTransfersToMakers[indices.pendingTransfersLen++] = Transfer.Pending(
                        order.taker_tokens[i][k], order.maker_addresses[i], order.taker_amounts[i][k]
                    );
                    assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
                } else {
                    revert("Unknown command");
                }
            }
            indices.commandsInd += order.taker_tokens[i].length;
        }

        require(indices.permitSignaturesInd == takerPermitsInfo.permitSignatures.length, "Unexpected number of Permit signatures");
        require(indices.batchToApproveInd == batchToApprove.length, "Unexpected number of tokens to approve");
        if (batchToApprove.length != 0) {
            // Update approvals for new taker's tokens
            PERMIT2.permit({
                owner: order.taker_address,
                permitBatch: IPermit2.PermitBatch({
                    details: batchToApprove,
                    spender: address(this),
                    sigDeadline: takerPermitsInfo.deadline
                }),
                signature: takerPermitsInfo.signatureBytesPermit2
            });
        }

        require(indices.batchLen == batchTransferDetails.length, "Unexpected number of tokens");
        if (indices.batchLen != 0) {
            // Transfer taker's tokens with Permit2 batch
            PERMIT2.transferFrom(batchTransferDetails);
        }

        // Wrap taker's native token
        if (nativeTokens.toMakers != 0) {
            require(msg.value == nativeTokens.toMakers, "Taker doesn't have enough native tokens");
            IWETH(WRAPPED_NATIVE_TOKEN).deposit{value: nativeTokens.toMakers}();
        }

        // Send all pending transfers to makers
        for (uint i; i < indices.pendingTransfersLen; ++i) {
            IERC20(pendingTransfersToMakers[i].token).safeTransfer(
                pendingTransfersToMakers[i].maker_address, pendingTransfersToMakers[i].amount
            );
        }

        // Unwrap and transfer native token to receiver
        if (nativeTokens.toTaker != 0) {
            IWETH(WRAPPED_NATIVE_TOKEN).withdraw(nativeTokens.toTaker);
            (bool sent,) = order.receiver.call{value: nativeTokens.toTaker}("");
            require(sent, "Failed to send Ether to taker");
        }

        emit AggregateOrderExecuted(h);
        return true;
    }
}
