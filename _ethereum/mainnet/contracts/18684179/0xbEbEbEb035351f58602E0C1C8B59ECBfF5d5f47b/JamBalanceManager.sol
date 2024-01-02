// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IJamBalanceManager.sol";
import "./IPermit2.sol";
import "./IDaiLikePermit.sol";
import "./JamOrder.sol";
import "./Signature.sol";
import "./SafeCast160.sol";
import "./BMath.sol";
import "./JamTransfer.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";

/// @title JamBalanceManager
/// @notice The reason a balance manager exists is to prevent interaction to the settlement contract draining user funds
/// By having another contract that allowances are made to, we can enforce that it is only used to draw in user balances to settlement and not sent out
contract JamBalanceManager is IJamBalanceManager {
    address private immutable operator;

    using SafeERC20 for IERC20;

    IPermit2 private immutable PERMIT2;
    address private immutable DAI_TOKEN;
    uint256 private immutable _chainId;

    constructor(address _operator, address _permit2, address _daiAddress) {
        // Operator can be defined at creation time with `msg.sender`
        // Pass in the settlement - and that can be the only caller.
        operator = _operator;
        _chainId = block.chainid;
        PERMIT2 = IPermit2(_permit2);
        DAI_TOKEN = _daiAddress;
    }

    modifier onlyOperator(address account) {
        require(account == operator, "INVALID_CALLER");
        _;
    }

    /// @inheritdoc IJamBalanceManager
    function transferTokens(
        TransferData calldata data
    ) onlyOperator(msg.sender) external {
        IPermit2.AllowanceTransferDetails[] memory batchTransferDetails;
        uint nftsInd;
        uint batchLen;
        for (uint i; i < data.tokens.length; ++i) {
            if (data.tokenTransferTypes[i] == Commands.SIMPLE_TRANSFER) {
                IERC20(data.tokens[i]).safeTransferFrom(
                    data.from, data.receiver, BMath.getPercentage(data.amounts[i], data.fillPercent)
                );
            } else if (data.tokenTransferTypes[i] == Commands.PERMIT2_TRANSFER) {
                if (batchLen == 0){
                    batchTransferDetails = new IPermit2.AllowanceTransferDetails[](data.tokens.length - i);
                }
                batchTransferDetails[batchLen++] = IPermit2.AllowanceTransferDetails({
                    from: data.from,
                    to: data.receiver,
                    amount: SafeCast160.toUint160(BMath.getPercentage(data.amounts[i], data.fillPercent)),
                    token: data.tokens[i]
                });
                continue;
            } else if (data.tokenTransferTypes[i] == Commands.NATIVE_TRANSFER) {
                require(data.tokens[i] == JamOrder.NATIVE_TOKEN, "INVALID_NATIVE_TOKEN_ADDRESS");
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                if (data.receiver != operator){
                    JamTransfer(operator).transferNativeFromContract(
                        data.receiver, BMath.getPercentage(data.amounts[i], data.fillPercent)
                    );
                }
            } else if (data.tokenTransferTypes[i] == Commands.NFT_ERC721_TRANSFER) {
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                require(data.amounts[i] == 1, "INVALID_ERC721_AMOUNT");
                IERC721(data.tokens[i]).safeTransferFrom(data.from, data.receiver, data.nftIds[nftsInd++]);
            } else if (data.tokenTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER) {
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                IERC1155(data.tokens[i]).safeTransferFrom(data.from, data.receiver, data.nftIds[nftsInd++], data.amounts[i], "");
            } else {
                revert("INVALID_TRANSFER_TYPE");
            }
            if (batchLen != 0){
                assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
            }
        }
        require(nftsInd == data.nftIds.length, "INVALID_NFT_IDS_LENGTH");
        require(batchLen == batchTransferDetails.length, "INVALID_BATCH_PERMIT2_LENGTH");

        if (batchLen != 0){
            PERMIT2.transferFrom(batchTransferDetails);
        }
    }

    /// @inheritdoc IJamBalanceManager
    function transferTokensWithPermits(
        TransferData calldata data,
        Signature.TakerPermitsInfo calldata takerPermitsInfo
    ) onlyOperator(msg.sender) external {
        IPermit2.AllowanceTransferDetails[] memory batchTransferDetails;
        IPermit2.PermitDetails[] memory batchToApprove = new IPermit2.PermitDetails[](takerPermitsInfo.noncesPermit2.length);
        Indices memory indices = Indices(0, 0, 0, 0);
        for (uint i; i < data.tokens.length; ++i) {
            if (data.tokenTransferTypes[i] == Commands.SIMPLE_TRANSFER || data.tokenTransferTypes[i] == Commands.CALL_PERMIT_THEN_TRANSFER) {
                if (data.tokenTransferTypes[i] == Commands.CALL_PERMIT_THEN_TRANSFER){
                    permitToken(
                        data.from, data.tokens[i], takerPermitsInfo.deadline, takerPermitsInfo.permitSignatures[indices.permitSignaturesInd++]
                    );
                }
                IERC20(data.tokens[i]).safeTransferFrom(
                    data.from, data.receiver, BMath.getPercentage(data.amounts[i], data.fillPercent)
                );
            } else if (data.tokenTransferTypes[i] == Commands.PERMIT2_TRANSFER || data.tokenTransferTypes[i] == Commands.CALL_PERMIT2_THEN_TRANSFER) {
                if (data.tokenTransferTypes[i] == Commands.CALL_PERMIT2_THEN_TRANSFER){
                    batchToApprove[indices.batchToApproveInd] = IPermit2.PermitDetails({
                        token: data.tokens[i],
                        amount: type(uint160).max,
                        expiration: takerPermitsInfo.deadline,
                        nonce: takerPermitsInfo.noncesPermit2[indices.batchToApproveInd]
                    });
                    ++indices.batchToApproveInd;
                }

                if (indices.batchLen == 0){
                    batchTransferDetails = new IPermit2.AllowanceTransferDetails[](data.tokens.length - i);
                }
                batchTransferDetails[indices.batchLen++] = IPermit2.AllowanceTransferDetails({
                    from: data.from,
                    to: data.receiver,
                    amount: SafeCast160.toUint160(BMath.getPercentage(data.amounts[i], data.fillPercent)),
                    token: data.tokens[i]
                });
                continue;
            } else if (data.tokenTransferTypes[i] == Commands.NATIVE_TRANSFER) {
                require(data.tokens[i] == JamOrder.NATIVE_TOKEN, "INVALID_NATIVE_TOKEN_ADDRESS");
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                if (data.receiver != operator){
                    JamTransfer(operator).transferNativeFromContract(
                        data.receiver, BMath.getPercentage(data.amounts[i], data.fillPercent)
                    );
                }
            } else if (data.tokenTransferTypes[i] == Commands.NFT_ERC721_TRANSFER) {
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                require(data.amounts[i] == 1, "INVALID_ERC721_AMOUNT");
                IERC721(data.tokens[i]).safeTransferFrom(data.from, data.receiver, data.nftIds[indices.nftsInd++]);
            } else if (data.tokenTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER) {
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                IERC1155(data.tokens[i]).safeTransferFrom(data.from, data.receiver, data.nftIds[indices.nftsInd++], data.amounts[i], "");
            } else {
                revert("INVALID_TRANSFER_TYPE");
            }

            // Shortening array
            if (indices.batchLen != 0){
                assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
            }
        }
        require(indices.batchToApproveInd == batchToApprove.length, "INVALID_NUMBER_OF_TOKENS_TO_APPROVE");
        require(indices.batchLen == batchTransferDetails.length, "INVALID_BATCH_PERMIT2_LENGTH");
        require(indices.permitSignaturesInd == takerPermitsInfo.permitSignatures.length, "INVALID_NUMBER_OF_PERMIT_SIGNATURES");
        require(indices.nftsInd == data.nftIds.length, "INVALID_NFT_IDS_LENGTH");

        if (batchToApprove.length != 0) {
            // Update approvals for new taker's data.tokens
            PERMIT2.permit({
                owner: data.from,
                permitBatch: IPermit2.PermitBatch({
                    details: batchToApprove,
                    spender: address(this),
                    sigDeadline: takerPermitsInfo.deadline
                }),
                signature: takerPermitsInfo.signatureBytesPermit2
            });
        }

        // Batch transfer
        if (indices.batchLen != 0){
            PERMIT2.transferFrom(batchTransferDetails);
        }
    }

    /// @dev Call permit function on token contract, supports both ERC20Permit and DaiPermit formats
    /// @param takerAddress address
    /// @param tokenAddress address
    /// @param deadline timestamp when the signature expires
    /// @param permitSignature signature
    function permitToken(
        address takerAddress, address tokenAddress, uint deadline, bytes calldata permitSignature
    ) private {
        (bytes32 r, bytes32 s, uint8 v) = Signature.getRsv(permitSignature);

        if (tokenAddress == DAI_TOKEN){
            if (_chainId == 137){
                IDaiLikePermit(tokenAddress).permit(
                    takerAddress, address(this), IDaiLikePermit(tokenAddress).getNonce(takerAddress), deadline, true, v, r, s
                );
            } else {
                IDaiLikePermit(tokenAddress).permit(
                    takerAddress, address(this), IERC20Permit(tokenAddress).nonces(takerAddress), deadline, true, v, r, s
                );
            }
        } else {
            IERC20Permit(tokenAddress).permit(takerAddress, address(this), type(uint).max, deadline, v, r, s);
        }

    }
}