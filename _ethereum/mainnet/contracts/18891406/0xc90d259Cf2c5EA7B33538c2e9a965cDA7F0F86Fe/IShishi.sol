// SPDX-License-Identifier: AGPL-3.0-only+VPL
pragma solidity ^0.8.16;

interface IShishi {
    struct Phases {
        uint64 startOne; // timestamp start of phase one
        uint64 startTwo; // timestamp start of phase two
        uint64 startThree; // timestamp start of phase three
    }

    struct Claimed {
        uint8 paid; // paid mints
        uint8 free; // free mints
    }

    struct Roots {
        bytes32 rootOne; // root of the first whitelist merkle tree
        bytes32 rootTwo; // root of the second whitelist merkle tree
    }

    /// Thrown if the base token metadata URI is locked to updates.
    error BaseURILocked();

    /// Thrown if an invalid proof is being supplied by the caller.
    error CannotClaimInvalidProof();

    /// Thrown if the mint phase has not yet started.
    error NotStartedYet();

    /// Thrown if the caller did not supply enough payment.
    error NotEnoughPayment();

    /// Thrown if there are no more Shishis left to mint.
    error OutOfStock();

    /**
     * This is thrown if a particular `msg.sender` (or, additionally, a `tx.origin`
     *   acting on behalf of smart contract caller) has run out of permitted mints.
     *   This does not and is not meant to protect against Sybil attacks originated by
     *   multiple different accounts.
     */
    error OutOfMints();

    // Thrown if sweeping funds from this contract fails.
    error SweepingTransferFailed();

    /// Emitted when user mints during phase one.
    event PhaseOneMinted(address indexed account, uint8 paid, uint8 free);

    /// Emitted when user mints during phase two.
    event PhaseTwoMinted(address indexed account, uint8 paid, uint8 free);

    /// Emitted when user mints during phase three.
    event PhaseThreeMinted(address indexed account, uint8 paid);
}
