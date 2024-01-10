//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IGambitClubNFT {
    enum SaleState {
        Paused,    // 0
        Whitelist, // 1
        Presale,   // 2
        Public     // 3
    }

    event SaleStateChanged(
        SaleState newSaleState
    );

    error SalePhaseNotActive();
    error InvalidMerkleProof();
    error IncorrectPaymentAmount();
    error ExceedsMintPhaseAllocation();
    error ExceedsMaxSupply();
    error ExceedsMaxMintPerTransaction();
    error FailedToWithdraw();
    error TokenDoesNotExist();
    error AlreadyRevokedRegistryApproval();
    error ExceedsMaxRoyaltiesPercentage();
    error ProvenanceHashAlreadyLocked();
}
