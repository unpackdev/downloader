// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";

contract MerkleDistributor is Ownable {
    uint256 public constant BPS_DENOMINATOR = 10_000;

    IERC20 public immutable token;

    bytes32 public merkleRoot;
    /// @notice A percentage of the amount that is claimable
    uint256 public claimBps;
    /// @notice A percentage of the claim amount that must be held by the user to claim
    uint256 public minBalanceBps;
    /// @notice The max number of tokens that can be claimed per user
    uint256 public maxTokensClaimable;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    event Claimed(
        uint256 index,
        address account,
        uint256 amount,
        uint256 actualAmount
    );
    event MerkleRootChanged(bytes32 oldRoot, bytes32 newRoot);
    event ClaimBpsChanged(uint256 oldBps, uint256 newBps);
    event MinBalanceBpsChanged(uint256 oldBps, uint256 newBps);
    event MaxTokensClaimableChanged(uint256 oldMax, uint256 newMax);

    constructor(
        IERC20 token_,
        bytes32 merkleRoot_,
        uint256 claimBps_,
        uint256 minBalanceBps_,
        uint256 maxTokensClaimable_
    ) {
        token = token_;
        merkleRoot = merkleRoot_;
        claimBps = claimBps_;
        minBalanceBps = minBalanceBps_;
        maxTokensClaimable = maxTokensClaimable_;
    }

    /// @notice Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /// @notice Marks index as claimed.
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /// @notice Claims an airdrop
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        // Users must have at least minBalanceBps of their claim
        uint256 actualAmount = amount * claimBps / BPS_DENOMINATOR;
        if (actualAmount > maxTokensClaimable) {
            actualAmount = maxTokensClaimable;
        }
        uint256 minBalance = (actualAmount * minBalanceBps) / BPS_DENOMINATOR;
        require(
            token.balanceOf(account) >= minBalance,
            "MerkleDistributor: Insufficient balance"
        );

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(
            token.transfer(account, actualAmount),
            "MerkleDistributor: Transfer failed."
        );

        emit Claimed(index, account, amount, actualAmount);
    }

    /// @notice Changes the merkle root
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        emit MerkleRootChanged(merkleRoot, merkleRoot);
        merkleRoot = merkleRoot_;
    }

    /// @notice Changes the claim bps
    function setClaimBps(uint256 claimBps_) external onlyOwner {
        emit ClaimBpsChanged(claimBps, claimBps_);
        claimBps = claimBps_;
    }

    /// @notice Changes the min balance bps
    function setMinTokenBps(uint256 minBalanceBps_) external onlyOwner {
        emit MinBalanceBpsChanged(minBalanceBps, minBalanceBps_);
        minBalanceBps = minBalanceBps_;
    }

    /// @notice Changes the max tokens claimable
    function setMaxTokensClaimable(uint256 maxTokensClaimable_)
        external
        onlyOwner
    {
        emit MaxTokensClaimableChanged(maxTokensClaimable, maxTokensClaimable_);
        maxTokensClaimable = maxTokensClaimable_;
    }

    /// @notice Burns remaining tokens in the contract
    function end() external onlyOwner {
        token.transfer(address(0), token.balanceOf(address(this)));
    }
}
