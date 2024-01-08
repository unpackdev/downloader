// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Interface for a sweepable airdrop contract based on merkle tree
 *
 * The airdrop has an expiration time. Once this expiration time
 * is reached the contract owner can sweep all unclaimed funds.
 * As long as the contract has funds, claiming will continue to
 * work after expiration time.
 *
 * @author Michael Bauer <michael@m-bauer.org>
 */
interface IMerkleDistributor {
    /**
     * Returns the address of the token distributed by this contract.
     */
    function token() external view returns (address);

    /**
     * Returns the expiration time of the airdrop as unix timestamp
     * (Seconds since unix epoch)
     */
    function expireTimestamp() external view returns (uint256);

    /**
     * Returns the merkle root of the merkle tree containing
     * account balances available to claim.
     */
    function merkleRoot() external view returns (bytes32);

    /**
     * Returns true if the index has been marked as claimed.
     */
    function isClaimed(uint256 index) external view returns (bool);

    /**
     * @notice Claim and transfer tokens
     *
     * Verifies the provided proof and params
     * and transfers 'amount' of tokens to 'account'.
     *
     * @param index Index of claim
     * @param account Address of claim
     * @param amount Amount of claim
     * @param proof Merkle proof for (index, account, amount)
     *
     * Emits a {Claimed} event on success.
     */
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata proof
    ) external;

    /**
     * @notice Sweep any unclaimed funds
     *
     * Transfers the full tokenbalance from the distributor contract to `target` address.
     *
     * @param target Address that should receive the unclaimed funds
     */
    function sweep(address target) external;

    /**
     * @notice Sweep any unclaimed funds to owner address
     *
     * Transfers the full tokenbalance from the distributor contract to owner of contract.
     */
    function sweepToOwner() external;

    /**
     * @dev Emitted when an airdrop is claimed for an `account`. `index` is the index
     * in the merkle tree, `value` is the amount of tokens claimed and transferred.
     */
    event Claimed(uint256 indexed claimIndex, address indexed account, uint256 amount);
}
