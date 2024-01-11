// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "./IERC721VotableEvents.sol";

/// @title Dopamine ERC-721 Voting Contract Interface
interface IERC721Votable is IERC721VotableEvents {

    /// @notice Checkpoints hold the vote balance of addresses at given blocks.
    struct Checkpoint {

        /// @notice The block number that the checkpoint was created.
        uint32 fromBlock;

        /// @notice The assigned voting balance.
        uint32 votes;

    }

    /// @notice Delegate assigned votes to `msg.sender` to `delegatee`.
    /// @param delegatee Address of the delegatee being delegated to.
    function delegate(address delegatee) external;

    /// @notice Delegate to `delegatee` on behalf of `delegator` via signature.
    /// @dev Refer to EIP-712 on signature and hashing details. This function
    ///  will revert if the provided signature is invalid or has expired.
    /// @param delegator The address to perform delegation on behalf of.
    /// @param delegatee The address being delegated to.
    /// @param expiry The timestamp at which this signature is set to expire.
    /// @param v Transaction signature recovery identifier.
    /// @param r Transaction signature output component #1.
    /// @param s Transaction signature output component #2.
    function delegateBySig(
        address delegator,
        address delegatee,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Get the total number of checkpoints created for address `voter`.
    /// @param voter Address of the voter being queried.
    /// @return The number of checkpoints tied to `voter`.
    function totalCheckpoints(address voter) external view returns (uint256);

    /// @notice Retrieves the voting weight `votes` and block `fromBlock`
    ///  corresponding to the checkpoint at index `index` of address `voter`.
    /// @param voter The address whose checkpoint we want to query.
    /// @param index The index to query among the voter's list of checkpoints.
    /// @return fromBlock The block number that the checkpoint was created.
    /// @return votes The voting balance assigned to the queried checkpoint.
    function checkpoints(address voter, uint256 index)
        external returns (uint32 fromBlock, uint32 votes);

    /// @notice Get the current number of votes allocated for address `voter`.
    /// @param voter The address of the voter being queried.
    /// @return The number of votes currently tied to address `voter`.
    function currentVotes(address voter) external view returns (uint32);

    /// @notice Get number of votes for `voter` at block number `blockNumber`.
    /// @param voter Address of the voter being queried.
    /// @param blockNumber Block number to tally votes from.
    /// @dev This function reverts if the current or future block is specified.
    /// @return The total tallied votes of `voter` at `blockNumber`.
    function priorVotes(address voter, uint256 blockNumber)
        external view returns (uint32);

    /// @notice Retrieves the currently assigned delegate of `delegator`.
    /// @dev Having no delegate assigned indicates self-delegation.
    /// @param delegator The address of the delegator.
    /// @return Assigned delegate address if it exists, `delegator` otherwise.
    function delegates(address delegator) external view returns (address);

}
