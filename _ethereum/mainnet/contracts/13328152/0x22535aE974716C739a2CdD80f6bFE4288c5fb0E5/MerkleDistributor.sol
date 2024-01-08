// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IMerkleDistributor.sol";
import "./console.sol";

/**
 * @title Sweepable Airdrop contract based on merkle tree
 *
 * The airdrop has an expiration time. Once this expiration time
 * is reached the contract owner can sweep all unclaimed funds.
 * As long as the contract has funds, claiming will continue to
 * work after expiration time.
 *
 * @author Michael Bauer <michael@m-bauer.org>
 */
contract MerkleDistributor is IMerkleDistributor, Ownable {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    uint256 public immutable override expireTimestamp;

    // Packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    /**
     * @dev sets values for associated token (ERC20), merkleRoot and expiration time
     *
     * @param token_ Contract address of the ERC20 token that is being dropped
     * @param merkleRoot_ Root of the token distribution merkle tree
     * @param expireTimestamp_ Timestamp when sweeping gets enabled (seconds since unix epoch)
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address token_, bytes32 merkleRoot_, uint256 expireTimestamp_) {
        token = token_;
        merkleRoot = merkleRoot_;
        expireTimestamp = expireTimestamp_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
        claimedBitMap[claimedWordIndex] |
        (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf),
                "MerkleDistributor: Invalid proof.");

        // Mark it claimed.
        _setClaimed(index);

        // Transfer token
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Failed token transfer');

        emit Claimed(index, account, amount);
    }

    /**
     * @dev Sweep any unclaimed funds to arbitrary destination. Can only be called by owner.
     */
    function sweep(address target) external override onlyOwner {
        require(block.timestamp >= expireTimestamp, "MerkleDistributor: Drop not expired");
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(target, balance);
    }

    /**
     * @dev Sweep any unclaimed funds to contract owner. Can be called by anyone.
     */
    function sweepToOwner() external override {
        require(block.timestamp >= expireTimestamp, "MerkleDistributor: Drop not expired");
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), balance);
    }
}
