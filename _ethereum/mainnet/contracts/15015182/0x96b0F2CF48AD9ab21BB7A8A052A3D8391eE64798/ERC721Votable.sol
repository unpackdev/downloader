// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// ERC721Votable.sol is a modification of Nouns DAO's ERC721Checkpointable.sol.
///
/// Copyright licensing is under the BSD-3-Clause license, as the above contract
/// is itself a modification of Compound Lab's Comp.sol (3-Clause BSD Licensed).
///
/// The following major changes were made from the original Nouns DAO contract:
/// - Numerous safety checks were removed (assumption is max supply < 2^32 - 1)
/// - Voting units were changed: `uint96` -> `uint32` (due to above assumption)
/// - `Checkpoint` struct was modified to pack 4 checkpoints per storage slot
/// - Signing was modularized to abstract away EIP-712 details (see ERC721.sol)

import "./Errors.sol";
import "./IERC721Votable.sol";

import "./ERC721.sol";

/// @title Dopamine ERC-721 Voting Contract
/// @notice This voting contract allows any ERC-721 with a maximum supply of
///  under `type(uint32).max` which inherits the contract to be integrated under
///  its Governor Bravo governance framework. This contract is to be inherited
///  by the Dopamine ERC-721 membership tab, allowing tabs to act as governance
///  tokens to be used for proposals, voting, and membership delegation.
contract ERC721Votable is ERC721, IERC721Votable {

    /// @notice Maps an address to a list of all of its created checkpoints.
    mapping(address => Checkpoint[]) public checkpoints;

    /// @dev Maps an address to its currently assigned voting delegate.
    mapping(address => address) internal _delegates;

    /// @notice Typehash used for EIP-712 vote delegation (see `delegateBySig`).
    bytes32 internal constant DELEGATION_TYPEHASH = keccak256('Delegate(address delegator,address delegatee,uint256 nonce,uint256 expiry)');

    /// @notice Instantiates a new ERC-721 voting contract.
    /// @param name_ The name of the ERC-721 NFT collection.
    /// @param symbol_ The abbreviated name of the ERC-721 NFT collection.
    /// @param maxSupply_ The maximum supply of the ERC-721 NFT collection.
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_)
        ERC721(name_, symbol_, maxSupply_) {}

    /// @inheritdoc IERC721Votable
    function delegate(address delegatee) external {
        _delegate(msg.sender, delegatee);
    }

    /// @inheritdoc IERC721Votable
    function delegateBySig(
        address delegator,
        address delegatee,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > expiry) {
            revert SignatureExpired();
        }
        address signatory = ecrecover(
            _hashTypedData(keccak256(
                abi.encode(
                    DELEGATION_TYPEHASH,
                    delegator,
                    delegatee,
                    nonces[delegator]++,
                    expiry
                )
            )),
            v,
            r,
            s
        );
        if (signatory == address(0) || signatory != delegator) {
            revert SignatureInvalid();
        }
        _delegate(signatory, delegatee);
    }

    /// @inheritdoc IERC721Votable
    function totalCheckpoints(address voter) external view returns (uint256) {
        return checkpoints[voter].length;
    }

    /// @inheritdoc IERC721Votable
    function currentVotes(address voter) external view returns (uint32) {
        uint256 numCheckpoints = checkpoints[voter].length;
        return numCheckpoints == 0 ?
            0 : checkpoints[voter][numCheckpoints - 1].votes;
    }

    /// @inheritdoc IERC721Votable
    function priorVotes(address voter, uint256 blockNumber)
        external
        view
        returns (uint32)
    {
        if (blockNumber >= block.number) {
            revert BlockInvalid();
        }

        uint256 numCheckpoints = checkpoints[voter].length;
        if (numCheckpoints == 0) {
            return 0;
        }

        // Check common case of `blockNumber` being ahead of latest checkpoint.
        if (checkpoints[voter][numCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[voter][numCheckpoints - 1].votes;
        }

        // Check case of `blockNumber` being behind first checkpoint (0 votes).
        if (checkpoints[voter][0].fromBlock > blockNumber) {
            return 0;
        }

        // Run binary search to find 1st checkpoint at or before `blockNumber`.
        uint256 lower = 0;
        uint256 upper = numCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[voter][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[voter][lower].votes;
    }

    /// @inheritdoc IERC721Votable
    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];
        return current == address(0) ? delegator : current;
    }

    /// @notice Delegate voting power of `delegator` to `delegatee`.
    /// @param delegator The address of the delegator.
    /// @param delegatee The address of the delegatee.
    function _delegate(address delegator, address delegatee) internal {
        if (delegatee == address(0)) {
            delegatee = delegator;
        }

        address currentDelegate = delegates(delegator);
        uint256 amount = balanceOf[delegator];

        _delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _transferDelegates(currentDelegate, delegatee, amount);
    }

    /// @notice Transfer `amount` voting power from `srcRep` to `dstRep`.
    /// @param srcRep The delegate whose votes are being transferred away from.
    /// @param dstRep The delegate who is being transferred new votes.
    /// @param amount The number of votes being transferred.
    function _transferDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep == dstRep || amount == 0) {
            return;
        }

        if (srcRep != address(0)) {
            (uint256 oldVotes, uint256 newVotes) =
                _writeCheckpoint(
                    checkpoints[srcRep],
                    _sub,
                    amount
                );
            emit DelegateVotesChanged(srcRep, oldVotes, newVotes);
        }

        if (dstRep != address(0)) {
            (uint256 oldVotes, uint256 newVotes) =
                _writeCheckpoint(
                    checkpoints[dstRep],
                    _add,
                    amount
                );
            emit DelegateVotesChanged(dstRep, oldVotes, newVotes);
        }
    }

    /// @notice Override pre-transfer hook to account for voting power transfer.
    /// @dev By design, a governance NFT corresponds to a single voting unit.
    /// @param from The address from which the gov NFT is being transferred.
    /// @param to The receiving address of the gov NFT.
    /// @param id The identifier of the gov NFT being transferred.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, id);
        _transferDelegates(delegates(from), delegates(to), 1);
    }

    /// @notice Adds a new checkpoint to `ckpts` by performing `op` of amount
    ///  `delta` on the last known checkpoint of `ckpts` (if it exists).
    /// @param ckpts Storage pointer to the Checkpoint array being modified
    /// @param op Binary operator, either add or subtract.
    /// @param delta Amount in voting units to be added to or subtracted from.
    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldVotes, uint256 newVotes) {
        uint256 numCheckpoints = ckpts.length;
        oldVotes = numCheckpoints == 0 ? 0 : ckpts[numCheckpoints - 1].votes;
        newVotes = op(oldVotes, delta);

        if ( // If latest checkpoint belonged to current block, just reassign.
             numCheckpoints > 0 &&
            ckpts[numCheckpoints - 1].fromBlock == block.number
        ) {
            ckpts[numCheckpoints - 1].votes = _safe32(newVotes);
        } else { // Otherwise, a new Checkpoint must be created.
            ckpts.push(Checkpoint({
                fromBlock: _safe32(block.number),
                votes: _safe32(newVotes)
            }));
        }
    }

    /// @notice Safely downcasts a uint256 `n` into a uint32.
    function _safe32(uint256 n) private  pure returns (uint32) {
        if (n > type(uint32).max) {
            revert Uint32ConversionInvalid();
        }
        return uint32(n);
    }

    /// @notice Binary operator for adding operand `a` to operand `b`.
    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    /// @notice Binary operator for subtracting operand `b` from operand `a`.
    function _sub(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

}
