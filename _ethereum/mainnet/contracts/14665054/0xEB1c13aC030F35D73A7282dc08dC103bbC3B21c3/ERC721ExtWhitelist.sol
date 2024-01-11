// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @author: unimint.org

import "./MerkleProof.sol";

/**
 * @title ERC721ExtWhitelist
 * @notice It distributes ERC721 tokens with a Merkle-tree whitelist
 */
abstract contract ERC721ExtWhitelist {
    // ------------------------------------------------------------------------
    // private
    // ------------------------------------------------------------------------
    bool private isMerkleRootSet;
    bytes32 private merkleRoot;
    uint256 private endTimestamp;
    uint96 private maxClaimAmount;
    mapping(address => bool) private hasClaimed;

    // ------------------------------------------------------------------------
    // event
    // ------------------------------------------------------------------------
    event EvtAirdropClaim(address indexed user, uint256 amount);
    event EvtUpdateMerkleRoot(bytes32 merkleRoot);
    event EvtUpdateEndTimestamp(uint256 endTimestamp);
    event EvtUpdateMaxClaimAmount(uint96 amount);

    // ------------------------------------------------------------------------
    // internal
    // ------------------------------------------------------------------------
    /**
     * @notice Check whether it is possible to claim (it doesn't check orders)
     * @param user address of the user
     * @param amount amount to claim
     * @param merkleProof array containing the merkle proof
     */
    function canClaim(
        address user,
        uint256 amount,
        uint256 value,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        if (block.timestamp <= endTimestamp && isMerkleRootSet) {
            bytes32 node = keccak256(abi.encodePacked(user, amount, value));
            return MerkleProof.verify(merkleProof, merkleRoot, node);
        } else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // internal
    // ------------------------------------------------------------------------
    /**
     * @notice Claim tokens for airdrop
     * @param amount amount to claim for the airdrop
     * @param merkleProof array containing the merkle proof
     */
    function _setClaimed(
        address user,
        uint256 amount,
        uint256 value,
        bytes32[] calldata merkleProof
    ) internal returns (bool) {
        require(isMerkleRootSet, "Merkle root not set");
        require(
            maxClaimAmount == 0 || amount <= maxClaimAmount,
            "Amount > Max Amount"
        );
        require(block.timestamp <= endTimestamp, "Too late to claim");

        // Verify the user has claimed
        require(!hasClaimed[user], "Already claimed");

        // Compute the node and verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(user, amount, value));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        // Set as claimed
        hasClaimed[user] = true;

        emit EvtAirdropClaim(user, amount);
        // Mint Token if return true;
        return true;
    }

    /**
     * @notice Set merkle root for airdrop
     * @param _merkleRoot merkle root
     */
    function _updateMerkleRoot(bytes32 _merkleRoot) internal {
        isMerkleRootSet = true;
        merkleRoot = _merkleRoot;
        emit EvtUpdateMerkleRoot(_merkleRoot);
    }

    function _clearMerkleRoot() internal {
        isMerkleRootSet = false;
        emit EvtUpdateMerkleRoot(0x0);
    }

    /**
     * @notice Update end timestamp
     * @param newEndTimestamp new endtimestamp
     * @dev Must be within 30 days
     */
    function _updateEndTimestamp(uint256 newEndTimestamp) internal {
        require(
            block.timestamp + 30 days > newEndTimestamp,
            "endtime > 30 days"
        );
        endTimestamp = newEndTimestamp;
        emit EvtUpdateEndTimestamp(newEndTimestamp);
    }

    function _updateMaxClaimAmount(uint96 newAmount) internal {
        maxClaimAmount = newAmount;
        emit EvtUpdateMaxClaimAmount(maxClaimAmount);
    }

    // ------------------------------------------------------------------------
    // Owner
    // ------------------------------------------------------------------------
    function claim(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        virtual;

    function updateMerkleRoot(bytes32 _merkleRoot) external virtual;

    function clearMerkleRoot() external virtual;

    function updateEndTimestamp(uint256 newEndTimestamp) external virtual;

    function updateMaxClaimAmount(uint96 newAmount) external virtual;
}
