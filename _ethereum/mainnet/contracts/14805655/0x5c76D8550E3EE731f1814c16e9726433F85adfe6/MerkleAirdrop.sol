//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC165.sol";
import "./MerkleProof.sol";

/// @notice Simple merkle airdrop contract. Claimed tokens come from reserves
/// held by the contract
contract MerkleAirdrop is Ownable {
    // ---
    // Events
    // ---

    /// @notice Tokens were claimed for a recipient
    event TokensClaimed(address recipient, uint256 amount);

    // ---
    // Errors
    // ---

    /// @notice The contract has already been set up
    error AlreadySetup();

    /// @notice A claim was attempted with an invalid claim list proof.
    error InvalidClaim();

    /// @notice A claim on behalf of another address came from an account with no allowance.
    error NotApproved();

    // ---
    // Storage
    // ---

    /// @notice The merkle root of the claim list tree.
    bytes32 public claimListRoot;

    /// @notice The airdropped token
    IERC20 public token;

    // tokens claimed so far
    mapping(address => uint256) private _claimed;

    // ---
    // Admin
    // ---

    /// @notice Set the airdropped token, merkle root, and do an initial
    /// deposit. Only callable by owner, only callable once.
    function setup(
        IERC20 token_,
        uint256 deposit,
        bytes32 root
    ) external onlyOwner {
        if (token != IERC20(address(0))) revert AlreadySetup();

        token = token_;
        claimListRoot = root;

        // reverts if contract not approved to spend msg.sender tokens
        // reverts if insufficient balance in msg.sender
        // reverts if invalid token reference
        // reverts if deposit = 0
        token_.transferFrom(msg.sender, address(this), deposit);
    }

    /// @notice Set the merkle root of the claim tree. Only callable by owner.
    function setClaimListRoot(bytes32 root) external onlyOwner {
        claimListRoot = root;
    }

    // ---
    // End users
    // ---

    /// @notice Claim msg.sender's airdropped tokens.
    function claim(uint256 maxClaimable, bytes32[] calldata proof)
        external
        returns (uint256)
    {
        return _claimFor(msg.sender, maxClaimable, proof);
    }

    /// @notice Permissionlessly claim tokens on behalf of another account.
    function claimFor(
        address recipient,
        uint256 maxClaimable,
        bytes32[] calldata proof
    ) external returns (uint256) {
        return _claimFor(recipient, maxClaimable, proof);
    }

    function _claimFor(
        address recipient,
        uint256 maxClaimable,
        bytes32[] calldata proof
    ) internal returns (uint256) {
        bool isValid = MerkleProof.verify(
            proof,
            claimListRoot,
            keccak256(abi.encodePacked(recipient, maxClaimable))
        );

        if (!isValid) revert InvalidClaim();

        uint256 claimed = _claimed[recipient];
        uint256 toClaim = claimed < maxClaimable ? maxClaimable - claimed : 0;

        // allow silent / non-reverting nop
        if (toClaim == 0) return 0;

        _claimed[recipient] = maxClaimable;
        emit TokensClaimed(recipient, toClaim);

        // reverts if insufficient reserve balance
        token.transfer(recipient, toClaim);

        return toClaim;
    }

    // ---
    // Views
    // ---

    /// @notice Returns the total amount of tokens claimed for an account
    function totalClaimed(address account) external view returns (uint256) {
        return _claimed[account];
    }
}
