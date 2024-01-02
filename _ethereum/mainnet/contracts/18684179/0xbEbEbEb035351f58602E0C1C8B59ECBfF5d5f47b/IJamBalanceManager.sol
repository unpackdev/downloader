// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Signature.sol";

/// @title IJamBalanceManager
/// @notice User approvals are made here. This handles the complexity of multiple allowance types. 
interface IJamBalanceManager {

    /// @dev All information needed to transfer tokens
    struct TransferData {
        address from;
        address receiver;
        address[] tokens;
        uint256[] amounts;
        uint256[] nftIds;
        bytes tokenTransferTypes;
        uint16 fillPercent;
    }

    /// @dev indices for transferTokensWithPermits function
    struct Indices {
        uint64 batchToApproveInd; // current `batchToApprove` index
        uint64 permitSignaturesInd; // current `takerPermitsInfo.permitSignatures` index
        uint64 nftsInd; // current `data.nftIds` index
        uint64 batchLen; // current length of `batchTransferDetails`
    }

    /// @notice Transfer tokens from taker to solverContract/settlementContract/makerAddress.
    /// Or transfer tokens directly from maker to taker for settleInternal case
    /// @param transferData data for transfer
    function transferTokens(
        TransferData calldata transferData
    ) external;

    /// @notice Transfer tokens from taker to solverContract/settlementContract
    /// @param transferData data for transfer
    /// @param takerPermitsInfo taker permits info
    function transferTokensWithPermits(
        TransferData calldata transferData,
        Signature.TakerPermitsInfo calldata takerPermitsInfo
    ) external;
}