// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Governable.sol";

error NothingToClaim();
error InvalidProof();
error NewMerkleRootSameAsCurrent();
error ProofsFileIsNull();

/**
 * @title Generic Recurring Airdrop contract
 */
contract RecurringAirdrop is ReentrancyGuard, Governable {
    using SafeERC20 for IERC20;

    /// @notice The token to distribute
    IERC20 public immutable token;

    /// @notice The merkle root for the current distribution
    bytes32 public merkleRoot;

    /// @notice The proofs file's IPFS hash
    bytes32 public proofsFileHash;

    /// @notice The timestamp of the latest merkle root update
    uint256 public updatedAt;

    /// @notice The Accumulated amount claimed for a given account
    mapping(address => uint256) public claimed;

    /// @notice Emitted when an account claims reward
    event RewardClaimed(address indexed to, uint256 amount);

    /// @notice Emitted when the merkle root is updated
    event MerkleRootUpdated(bytes32 merkleRoot, uint256 createdAt);

    constructor(IERC20 token_) {
        token = token_;
    }

    /**
     * @notice Claim reward
     * @dev Every tree leaf is a `[account, amount]` tuple, we assume that the `msg.sender` is the account
     * @param amount_ The amount to claim
     * @param proof_ The merkle tree proof for the given leaf
     */
    function claim(uint256 amount_, bytes32[] calldata proof_) external nonReentrant {
        if (merkleRoot == bytes32(0)) revert NothingToClaim();

        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, amount_));
        if (!MerkleProof.verify(proof_, merkleRoot, _leaf)) revert InvalidProof();

        uint256 _claimable = amount_ - claimed[msg.sender];
        if (_claimable == 0) revert NothingToClaim();

        claimed[msg.sender] += _claimable;

        _transferReward(msg.sender, _claimable);

        emit RewardClaimed(msg.sender, _claimable);
    }

    /**
     * @notice Transfer reward to the user
     * @param to_ The claim account
     * @param amount_ The reward amount
     */
    function _transferReward(address to_, uint256 amount_) internal virtual {
        token.safeTransfer(to_, amount_);
    }

    /**
     * @notice Update merkle tree root
     * @param merkleRoot_ The merkle root
     */
    function updateMerkleRoot(bytes32 merkleRoot_, bytes32 proofsFileHash_) external onlyGovernor {
        if (merkleRoot_ == merkleRoot) revert NewMerkleRootSameAsCurrent();
        if (proofsFileHash_ == bytes32(0)) revert ProofsFileIsNull();

        merkleRoot = merkleRoot_;
        updatedAt = block.timestamp;
        proofsFileHash = proofsFileHash_;

        emit MerkleRootUpdated(merkleRoot_, block.timestamp);
    }
}
