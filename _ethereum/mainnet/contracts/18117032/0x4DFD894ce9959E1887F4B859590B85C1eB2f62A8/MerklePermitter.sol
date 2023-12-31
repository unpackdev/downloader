// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./OwnerTwoStep.sol";
import "./IPermitter.sol";

import "./MerkleProof.sol";

/**
 * @title MerklePermitter
 * @dev Allows permitting token ids only if valid merkle proofs that match the merkle root are provided.
 */
contract MerklePermitter is IPermitter, OwnerTwoStep {
    bytes32 private _merkleRoot;
    string private _merkleRootUri;
    bool private _initialized;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event MerklePermitterAdminUpdatedMerkleRoot(bytes32 newMerkleRoot);
    event MerklePermitterAdminUpdatedMerkleRootUri(string newMerkleRootUri);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error MerklePermitterAlreadyInitialized();
    error MerklePermitterArityMismatch();
    error MerklePermitterMerkleRootLocked();

    ///@inheritdoc IPermitter
    function initialize(bytes memory initializationData)
        external
        override
        returns (bytes memory data)
    {
        if (_initialized) {
            revert MerklePermitterAlreadyInitialized();
        }
        _initialized = true;

        address initialAdmin;
        (_merkleRoot, initialAdmin, _merkleRootUri) =
            abi.decode(initializationData, (bytes32, address, string ));

        data = abi.encode(_merkleRoot);

        emit MerklePermitterAdminUpdatedMerkleRoot(_merkleRoot);
        emit MerklePermitterAdminUpdatedMerkleRootUri(_merkleRootUri);

        _transferOwnership(initialAdmin);
    }

    /**
     * @inheritdoc IPermitter
     * @param rawMerkleProofs_ The array of bytes[] proofs encoded into bytes using abi.encode
     */
    function checkPermitterData(uint256[] calldata tokenIds_, bytes memory rawMerkleProofs_)
        external
        view
        returns (bool permitted)
    {
        bytes32[] memory tokenIdHashes = _hash(tokenIds_);
        bytes32[][] memory merkleProofs = abi.decode(rawMerkleProofs_, (bytes32[][]));

        uint256 countMerkleProofs = merkleProofs.length;

        if (tokenIdHashes.length != countMerkleProofs) {
            revert MerklePermitterArityMismatch();
        }

        bytes32 localMerkleRoot = _merkleRoot; // save gas

        for (uint256 i = 0; i < countMerkleProofs;) {
            if (!MerkleProof.verify(merkleProofs[i], localMerkleRoot, tokenIdHashes[i])) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    // ============================================================
    // ========================== ADMIN ===========================
    // ============================================================

    /**
     * @dev Allows the admin to update the Merkle root URI, 
     * updating the metadata describing a particular Merkle root.
     *
     * @param newMerkleRootUri_ The new merkle root uri.
     */
    function updateMerkleRootUri(string memory newMerkleRootUri_) external onlyOwner {
        _merkleRootUri = newMerkleRootUri_;

        emit MerklePermitterAdminUpdatedMerkleRootUri(newMerkleRootUri_);
    }


    // ============================================================
    // ========================== UTILS ===========================
    // ============================================================

    /*
     * @notice Hashes an array of numbers for use in a Merkle Proof
     * @param values The values to hash
     * @return result The hashed values
     */
    function _hash(uint256[] memory values) internal pure returns (bytes32[] memory result) {
        uint256 countValues = values.length;

        result = new bytes32[](countValues);

        for (uint256 i; i < countValues;) {
            result[i] = keccak256(bytes.concat(keccak256(abi.encode(values[i]))));

            unchecked {
                ++i;
            }
        }
    }

    // ============================================================
    // ================= EXTERNAL VIEW FUNCTIONS ==================
    // ============================================================

    /**
     * @notice Returns the current merkle root
     * @return merkleRoot The current merkle root
     */
    function merkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    /**
     * @notice Returns the current merkle root uri
     */
    function merkleRootUri() external view returns (string memory) {
        return _merkleRootUri;
    }

    ///@inheritdoc IPermitter
    function initialized() external view returns (bool) {
        return _initialized;
    }
}
