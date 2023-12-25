// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./LibBitmap.sol";
import "./MerkleProof.sol";

/**
 * @title Allowlist
 * @author fx(hash)
 * @notice Extension for claiming tokens through merkle trees
 */
abstract contract Allowlist {
    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when allowlist slot is claimed
     * @param _token Address of the token
     * @param _reserveId ID of the reserve
     * @param _claimer Address of the claimer
     * @param _index Index of purchase info inside the BitMap
     */
    event SlotClaimed(address indexed _token, uint256 indexed _reserveId, address indexed _claimer, uint256 _index);

    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Error thrown when the merkle proof for an index is invalid
     */
    error InvalidProof();

    /**
     * @notice Error thrown when an index in the merkle tree has already been claimed
     */
    error SlotAlreadyClaimed();

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Claims a merkle tree slot
     * @param _token Address of the token contract
     * @param _reserveId ID of the reserve
     * @param _index Index in the merkle tree
     * @param _claimer Address of allowlist slot claimer
     * @param _proof Merkle proof used for validating claim
     * @param _bitmap Bitmap used for checking if index is already claimed
     */
    function _claimSlot(
        address _token,
        uint256 _reserveId,
        uint256 _index,
        address _claimer,
        bytes32[] memory _proof,
        LibBitmap.Bitmap storage _bitmap
    ) internal {
        if (LibBitmap.get(_bitmap, _index)) revert SlotAlreadyClaimed();
        bytes32 root = _getMerkleRoot(_token, _reserveId);
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_index, _claimer))));
        if (!MerkleProof.verify(_proof, root, leaf)) revert InvalidProof();
        LibBitmap.set(_bitmap, _index);

        emit SlotClaimed(_token, _reserveId, _claimer, _index);
    }

    /**
     * @dev Gets the merkle root of a token reserve
     * @param _token Address of the token contract
     * @param _reserveId ID of the reserve
     */
    function _getMerkleRoot(address _token, uint256 _reserveId) internal view virtual returns (bytes32);
}
