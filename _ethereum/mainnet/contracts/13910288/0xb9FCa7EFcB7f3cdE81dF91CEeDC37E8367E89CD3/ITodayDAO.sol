// SPDX-License-Identifier: GPL

pragma solidity ^0.8.6;

interface ITodayDAO {
    /// @notice An event emitted when a proposal has been vetoed by vetoAddress
    event ProposalVetoed(uint256 proposalId);

    /// @notice Emitted when vetoer is changed
    event NewVetoer(address oldVetoer, address newVetoer);
}
