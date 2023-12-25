// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./MerkleProof.sol";
import "./IERC1155.sol";

interface INextId {
    function nextTokenIdToMint() external view returns (uint256);
}

abstract contract TokenMigrateERC1155 {
    /// @dev The sender is not authorized to perform the action
    error TokenMigrateUnauthorized();

    /// @dev Token is not eligible for migration
    error TokenMigrateInvalidTokenId(uint256 tokenId);

    /// @dev Invalid proofs to claim the token ownership for id
    error TokenMigrateInvalidProof(address tokenOwner, uint256 tokenId);

    /// @dev Token is already migrated
    error TokenMigrateAlreadyMigrated(address owner, uint256 tokenId);

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The merkle root contianing token ownership information.
    bytes32 private ownershipMerkleRoot;

    /// @notice The address of the original token contract.
    address internal _originalContract;

    /// @notice A mapping from ownership id to the amount claimed.
    mapping(uint256 => uint256) private _amountClaimed;

    /*///////////////////////////////////////////////////////////////
                        External/Public Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Migrates a token via proving inclusion in the merkle root.
    /// @dev Assumption: tokens on the original contract are non-transferrable.
    function migrate(
        address _tokenOwner,
        uint256 _tokenId,
        uint256 _proofMaxQuantity,
        bytes32[] calldata _proof
    ) external {
        // if tokenId doesn't exist in the original contract, then revert
        // original contract is already frozen, no more new token will be minted after this migration has been setup
        if (_tokenId >= INextId(_originalContract).nextTokenIdToMint()) {
            revert TokenMigrateInvalidTokenId(_tokenId);
        }

        uint256 id = _ownershipId(_tokenOwner, _tokenId);
        // Check if the total tokens owed have not already been claimed
        if (_amountClaimed[id] >= _proofMaxQuantity) {
            revert TokenMigrateAlreadyMigrated(_tokenOwner, _tokenId);
        }

        // Verify that the proof is valid
        bool isValidProof;
        (isValidProof, ) = MerkleProof.verify(
            _proof,
            _merkleRoot(),
            keccak256(abi.encodePacked(_tokenId, _tokenOwner, _proofMaxQuantity))
        );
        if (!isValidProof) {
            revert TokenMigrateInvalidProof(_tokenOwner, _tokenId);
        }

        // Send the difference to the token owner
        uint256 _amount = _proofMaxQuantity - _amountClaimed[id];
        // Mark token ownership as claimed
        _amountClaimed[id] = _proofMaxQuantity;

        // Mint token to token owner
        _mintMigratedTokens(_tokenOwner, _tokenId, _amount);
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

    /// @notice Returns bitmap id for a particular token ownership claim.
    function _ownershipId(address _tokenOwner, uint256 _tokenId) internal pure virtual returns (uint256) {
        return uint(keccak256(abi.encodePacked(_tokenOwner, _tokenId)));
    }

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

    /*///////////////////////////////////////////////////////////////
                        Unimplemented Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints migrated token to token owner.
    function _mintMigratedTokens(address _tokenOwner, uint256 _tokenId, uint256 _amount) internal virtual;

    /// @notice Returns whether merkle root can be set in the given execution context.
    function _canSetMerkleRoot() internal virtual returns (bool);
}
