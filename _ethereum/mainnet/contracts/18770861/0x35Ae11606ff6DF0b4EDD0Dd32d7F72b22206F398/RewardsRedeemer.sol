// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.19;

import "./IRewardsRedeemer.sol";

import "./SafeERC20.sol";
import "./BitMaps.sol";
import "./MerkleProof.sol";

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

/** See IRewardsRedeemer.sol */
contract RewardsRedeemer is IRewardsRedeemer, Ownable {
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;

    /// STORAGE
    uint256 public deployedAt; // Timestamp of when the contract was deployed
    IERC20 public rewardsToken; // Token used to reward users

    mapping(uint256 index => bytes32 rootHash) public roots; // Merkle tree roots for each time period
    mapping(address user => BitMaps.BitMap timePeriodBitmap) private claimedRoots; // Bitmaps to keep track of which time periods the user has already claimed

    /// INITIALIZER

    /* @inheritdoc IRewardsRedeemer */
    function initialize(address _owner, address _rewardsToken) external initializer {
        __Ownable_init();

        if (_rewardsToken == address(0)) {
            revert InvalidRewardsToken(_rewardsToken);
        }

        rewardsToken = IERC20(_rewardsToken);

        transferOwnership(_owner);

        deployedAt = block.timestamp;
    }

    /* @inheritdoc IRewardsRedeemer */
    function addRoot(uint256 index, bytes32 root) external onlyOwner {
        if (roots[index] != bytes32(0)) {
            revert RootAlreadyAdded(index, root);
        }
        roots[index] = root;
    }

    /* @inheritdoc IRewardsRedeemer */
    function removeRoot(uint256 index) external onlyOwner {
        delete roots[index];
    }

    /* @inheritdoc IRewardsRedeemer */
    function getRoot(uint256 index) external view returns (bytes32) {
        return roots[index];
    }

    /* @inheritdoc IRewardsRedeemer */
    function hasClaimed(address user, uint256 index) public view returns (bool) {
        return claimedRoots[user].get(index);
    }

    /* @inheritdoc IRewardsRedeemer */
    function canClaim(
        uint256 index,
        uint256 amount,
        bytes32[] memory proof
    ) external view returns (bool) {
        return _couldClaim(index, amount, proof) && !hasClaimed(_msgSender(), index);
    }

    /* @inheritdoc IRewardsRedeemer */
    function claim(uint256 index, uint256 amount, bytes32[] calldata proof) external {
        BitMaps.BitMap storage userClaimedRoots = claimedRoots[_msgSender()];

        _processClaim(index, amount, proof, userClaimedRoots);
        _sendRewards(_msgSender(), amount);
    }

    /* @inheritdoc IRewardsRedeemer */
    function claimMultiple(
        uint256[] calldata indices,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external {
        if (indices.length != amounts.length || amounts.length != proofs.length) {
            revert ClaimMultipleLengthMismatch(indices, amounts, proofs);
        }
        if (indices.length == 0) {
            revert ClaimMultipleEmpty(indices, amounts, proofs);
        }

        uint256 total;
        BitMaps.BitMap storage userClaimedRoots = claimedRoots[_msgSender()];

        for (uint256 i = 0; i < indices.length; i += 1) {
            _processClaim(indices[i], amounts[i], proofs[i], userClaimedRoots);

            total += amounts[i];
        }

        _sendRewards(_msgSender(), total);
    }

    /* @inheritdoc IRewardsRedeemer */
    function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /// INTERNALS

    /**
     * @notice Verifies that the user could claim the given amount for the given index
     *
     * @param proof Merkle tree proof for the given index and amount
     * @param index Index of the root to claim
     * @param amount Amount to claim
     *
     * @dev This function does not take into account whether the user has already claimed the given index
     */
    function _couldClaim(
        uint256 index,
        uint256 amount,
        bytes32[] memory proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), amount));
        return MerkleProof.verify(proof, roots[index], leaf);
    }

    /**
     * @notice Verifies that the user can claim the given amount for the given index
     *
     * @param index Index of the root to claim
     * @param amount Amount to claim
     * @param proof Merkle tree proof for the given index and amount
     *
     * @dev Reverts if the user cannot claim the given amount for the given index
     */
    function _verifyClaim(uint256 index, uint256 amount, bytes32[] memory proof) internal view {
        if (!_couldClaim(index, amount, proof)) {
            revert UserCannotClaim(_msgSender(), index, amount, proof);
        }

        if (hasClaimed(_msgSender(), index)) {
            revert UserAlreadyClaimed(_msgSender(), index, amount, proof);
        }
    }

    /**
     * @notice Processes the claim for the given index and amount, and stores the claim in local storage
     *
     * @param index Index of the root to claim
     * @param amount Amount to claim
     * @param proof Merkle tree proof for the given index and amount
     * @param userClaimedRoots Local storage with the already claimed roots for the user
     *
     * @dev Reverts if the user cannot claim the given amount for the given index, otherwise stores the claim in local storage
     *      and emits a Claimed event. No tokens are transferred.
     */
    function _processClaim(
        uint256 index,
        uint256 amount,
        bytes32[] calldata proof,
        BitMaps.BitMap storage userClaimedRoots
    ) internal {
        _verifyClaim(index, amount, proof);

        userClaimedRoots.set(index);

        emit Claimed(_msgSender(), index, amount);
    }

    /**
     * @notice Sends the given amount of the given token to the given address
     *
     * @param to Address to send the tokens to
     * @param amount Amount of tokens to send
     */
    function _sendRewards(address to, uint256 amount) internal {
        rewardsToken.safeTransfer(to, amount);
    }
}
