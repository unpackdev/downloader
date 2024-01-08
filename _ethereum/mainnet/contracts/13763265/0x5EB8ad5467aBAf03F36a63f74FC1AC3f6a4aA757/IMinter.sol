// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IMinter {
    error AlreadyClaimed(address msgSender);
    error InvalidProof();

    /**
     * @notice This event is triggered whenever a call to `claim()` succeeds
     */
    event Claimed(uint256 index, address account, uint256 amount);

    /**
     * @notice Claims tokens according the merkle proof
     * @dev Tokens should be previously transferred to this contract
     *
     * @param index Index of the account in the merkle tree
     * @param account Account willing to claim tokens
     * @param amount Amount of tokens to be claimed
     * @param merkleProof Array of hashed combining merkle proof
     *
     * Requirements:
     *
     * - Can be called once per `index`
     */
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    /**
     * @notice Sets new merkle tree root
     * @param merkleRoot_ New merkle tree root
     *
     * Requirements:
     *
     * - can be called by the owner
     */
    function setMerkleRoot(bytes32 merkleRoot_) external;

    /**
     * @notice Returns token contract address
     */
    function token() external view returns (address);

    /**
     * @notice Returns the merkle root of the merkle tree
     */
    function merkleRoot() external view returns (bytes32);

    /**
     * @param index Index of the account in the merkle tree
     * @notice Returns whether the index has been used to claim tokens
     */
    function isClaimed(uint256 index) external view returns (bool);
}
