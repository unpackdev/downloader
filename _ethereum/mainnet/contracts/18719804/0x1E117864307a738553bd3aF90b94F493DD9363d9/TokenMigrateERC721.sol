// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./MerkleProof.sol";
import "./IERC721.sol";

interface INextId {
    function nextTokenIdToMint() external view returns (uint256);
}

abstract contract TokenMigrateERC721 {
    /// @dev The sender is not authorized to perform the action
    error TokenMigrateUnauthorized();

    /// @dev Token is not eligible for migration
    error TokenMigrateInvalidTokenId(uint256 tokenId);

    /// @dev Invalid proofs to claim the token ownership for id
    error TokenMigrateInvalidProof(address tokenOwner, uint256 tokenId);

    /// @dev Token is already migrated
    error TokenMigrateAlreadyMigrated(uint256 tokenId);

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The merkle root contianing token ownership information.
    bytes32 private ownershipMerkleRoot;

    /// @notice The address of the original token contract.
    address internal _originalContract;

    /// @notice A bit map of token IDs
    mapping(uint256 => bool) private _ownershipClaimed;

    /*///////////////////////////////////////////////////////////////
                        External/Public Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Migrates a token via proving inclusion in the merkle root.
    /// @dev Assumption: tokens on the original contract are non-transferrable.
    function migrate(address _tokenOwner, uint256 _tokenId, bytes32[] calldata _proof) external {
        // Check if the token ownership has already been claimed
        if (_ownershipClaimed[_tokenId]) {
            revert TokenMigrateAlreadyMigrated(_tokenId);
        }

        // if tokenId doesn't exist in the original contract, then revert
        // original contract is already frozen, no more new token will be minted after this migration has been setup
        if (_tokenId >= INextId(_originalContract).nextTokenIdToMint()) {
            revert TokenMigrateInvalidTokenId(_tokenId);
        }

        // Verify that the proof is valid
        bool isValidProof;
        (isValidProof, ) = MerkleProof.verify(
            _proof,
            _merkleRoot(),
            keccak256(abi.encodePacked(_tokenId, _tokenOwner))
        );
        if (!isValidProof) {
            revert TokenMigrateInvalidProof(_tokenOwner, _tokenId);
        }

        // Mark token ownership as claimed
        _ownershipClaimed[_tokenId] = true;

        // Mint token to token owner
        _mintMigratedTokens(_tokenOwner, _tokenId);
    }

    /// @notice Sets the merkle root containing token ownership information.
    function setMerkleRoot(bytes32 _merkleRoot) external virtual {
        if (!_canSetMerkleRoot()) {
            revert TokenMigrateUnauthorized();
        }
        _setupMerkleRoot(_merkleRoot);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the merkle root containing token ownership information.
    function _merkleRoot() internal view virtual returns (bytes32) {
        return ownershipMerkleRoot;
    }

    /// @notice Sets up the original token contract address.
    function _setupOriginalContract(address __originalContract) internal virtual {
        _originalContract = __originalContract;
    }

    /// @notice Sets up the merkle root containing token ownership information.
    function _setupMerkleRoot(bytes32 _merkleRoot) internal virtual {
        ownershipMerkleRoot = _merkleRoot;
    }

    function isOwnershipClaimed(uint256 _tokenId) internal view returns (bool) {
        return _ownershipClaimed[_tokenId];
    }

    /*///////////////////////////////////////////////////////////////
                        Unimplemented Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints migrated token to token owner.
    function _mintMigratedTokens(address _tokenOwner, uint256 _tokenId) internal virtual;

    /// @notice Returns whether merkle root can be set in the given execution context.
    function _canSetMerkleRoot() internal virtual returns (bool);
}
