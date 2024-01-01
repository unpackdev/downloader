// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMpOwnable {
    struct OwnerMultisignature {
        uint quorum;
        address[] participants;
    }

    // @notice Returns OwnerMultisignature data
    function ownerMultisignature() external view returns (OwnerMultisignature memory);

    // @notice Returns address og the multiparty owner
    function mpOwner() external view returns (address);
}
