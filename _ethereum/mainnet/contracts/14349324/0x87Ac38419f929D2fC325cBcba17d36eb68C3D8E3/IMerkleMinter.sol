// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

/**
 * Allows accounts to mint a token if they exist in a merkle root.
 */
interface IMerkleMinter {
    /**
     * Returns the address of the token minted by this contract.
     */
    function mintableToken() external view returns (address);

    /**
     * Returns the address of the payment token required by this contract.
     */
    function paymentToken() external view returns (address);

    /**
     * Returns the merkle root of the merkle tree containing account balances
     * available to claim.
     */
    function merkleRoot() external view returns (bytes32);

    /**
     * Returns true if the index has been marked claimed.
     */
    function isClaimed(uint256 index) external view returns (bool);

    /**
     * @dev Returns an array of booleans indicated if each index is claimed.
     */
    function claimedList() external view returns (bool[] memory);

    /**
     * @dev Claim the given token to the given address. Reverts if the inputs
     * are invalid.
     */
    function claim(uint256 index, address account, uint256 tokenID, uint256 price, bytes32[] calldata merkleProof) external;

    /**
     * @dev This event is triggered whenever a call to #claim succeeds.
     */
    event Claimed(uint256 index, address account, uint256 tokenId, uint256 price);
}
