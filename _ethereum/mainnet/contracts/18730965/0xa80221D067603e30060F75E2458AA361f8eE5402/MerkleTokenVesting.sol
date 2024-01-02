// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable2Step.sol";

import "./TokenVesting.sol";
import "./MerkleDistributor.sol";

/**
 * @title MerkleTokenVesting
 * @notice Vesting contract that allows configuring periodic vesting with start tokens and cliff time.
 * @dev Vestings are initialized by the users from Merkle proofs. Users can initialize their vestings at any time.
 * Periods are based on the 30 days time frame as a equivalent of a month. The contract owner can add vesting
 * schedules and Merkle roots and deposit vested tokens.
 *
 * This contract is a combination of two existing contracts: TokenVesting and MerkleDistributor.
 * TokenVesting is a contract for vesting tokens over time with a start date, cliff period, and duration.
 * MerkleDistributor is a contract for validation of token distribution according to a Merkle tree.
 *
 * The contract uses the OpenZeppelin libraries for ERC20 tokens and access control.
 */
contract MerkleTokenVesting is TokenVesting, MerkleDistributor, Ownable2Step {
    // -----------------------------------------------------------------------
    // Library usage
    // -----------------------------------------------------------------------

    using SafeERC20 for IERC20;

    // -----------------------------------------------------------------------
    // Errors
    // -----------------------------------------------------------------------

    error Error_InvalidProof();
    error Error_NothingToVest();
    error Error_IdZero();
    error Error_RootZero();
    error Error_RootAdded();
    error Error_InvalidData();

    // -----------------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------------

    /**
     * @dev Emitted when a user's tokens are vested.
     * @param id The id of the vesting schedule.
     * @param user The address of the user whose tokens have been vested.
     * @param index The index of the vesting in the merkle proofs.
     * @param amount The amount of tokens vested.
     */
    event Vested(
        uint256 indexed id,
        address indexed user,
        uint256 index,
        uint256 amount
    );

    // -----------------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------------

    constructor(
        address _vestedToken
    ) TokenVesting(_vestedToken) Ownable(msg.sender) {}

    // -----------------------------------------------------------------------
    // User actions
    // -----------------------------------------------------------------------

    /**
     * @notice Allows initializing vesting by the user.
     *
     * @dev This function allows the user to add new vestings to their account.
     * It validates that all the data provided is valid against the Merkle root.
     * If the data is valid, it calculates the total vested amount and updates
     * the user's vested balance accordingly. If the user tries to perform a transaction
     * without adding any new vestings, the transaction will be reverted.
     *
     * @dev Validations:
     * - The length of the indexes, amounts, and proofs arrays must be the same.
     * - Each provided Merkle proof must be valid against the Merkle root.
     * - The user cannot perform a transaction without adding any new vesting.
     *
     * @param id The id of the vesting schedule for which vestings are added.
     * @param user The address of the user for which vestings are added.
     * @param indexes Array of merkle proof data indexes.
     * @param amounts Array of tokens to vest for each user vesting.
     * @param proofs Array of arrays of all user Merkle proofs.
     *
     * Emits a Vested event for each successfully claimed vesting.
     */
    function initVestings(
        uint256 id,
        address user,
        uint256[] calldata indexes,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external {
        uint256 _vested = 0;

        if (
            indexes.length != amounts.length || indexes.length != proofs.length
        ) {
            revert Error_InvalidData();
        }

        for (uint256 i = 0; i < indexes.length; i++) {
            if (!isClaimed(id, indexes[i])) {
                if (
                    !_verify(id, proofs[i], _leaf(indexes[i], user, amounts[i]))
                ) {
                    revert Error_InvalidProof();
                }

                _vested += amounts[i];

                _setClaimed(id, indexes[i]);
                emit Vested(id, user, indexes[i], amounts[i]);
            }
        }

        if (_vested == 0) {
            revert Error_NothingToVest();
        }

        vested[id][user] += _vested;
    }

    // -----------------------------------------------------------------------
    // Owner actions
    // -----------------------------------------------------------------------

    /**
     * @notice Allows the owner to add a vesting schedule with a Merkle root and
     * deposit the vested tokens
     *
     * @dev Validations:
     * - Only the owner of the contract can call this function
     * - The Merkle root has not been set before for the given id
     * - The allowance on the vested token has been properly set
     * - The id is not zero
     * - The Merkle root is not zero
     *
     * @param id Unique identifier for the vesting schedule
     * @param start Timestamp of the starting date of the vesting schedule
     * @param cliff Duration of the cliff of the vesting schedule (in seconds)
     * @param recurrences Number of vesting recurrences in the schedule (30 days each)
     * @param startBPS Percentage of tokens that will be vested initially
     * @param merkleRoot The Merkle root of the proof tree for the vesting schedule
     * @param totalAmount The total amount of tokens to be vested for the schedule
     */
    function addVestingSchedule(
        uint256 id,
        uint40 start,
        uint32 cliff,
        uint16 recurrences,
        uint16 startBPS,
        bytes32 merkleRoot,
        uint256 totalAmount
    ) external onlyOwner {
        if (id == 0) {
            revert Error_IdZero();
        }

        if (merkleRoot == bytes32(0)) {
            revert Error_RootZero();
        }

        if (merkleRoots[id] != bytes32(0)) {
            revert Error_RootAdded();
        }

        _addVestingSchedule(id, start, cliff, recurrences, startBPS);
        _addMerkleRoot(id, merkleRoot);

        vestedToken.safeTransferFrom(msg.sender, address(this), totalAmount);
    }

    // -----------------------------------------------------------------------
    // Internal functions
    // -----------------------------------------------------------------------

    /**
     * @dev Internal function for calculating the hash of Merkle tree leaf
     * from provided parameters. Uses double-hash Merkle tree leafs to prevent
     * second preimage attacks.
     *
     * @param index Index of vesting in Merkle tree data
     * @param account Address of user
     * @param amount Amount of tokens vested for user
     *
     * @return bytes32 Hashed Merkle tree leaf
     */
    function _leaf(
        uint256 index,
        address account,
        uint256 amount
    ) private pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(keccak256(abi.encode(index, account, amount)))
            );
    }
}
