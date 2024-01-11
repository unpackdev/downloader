// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "IERC20.sol";
import "Ownable.sol";
import "MerkleProof.sol";
import "IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor, Ownable {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    uint256 public immutable startTime;
    uint256 public immutable endTime;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_, uint256 startTime_, uint256 endTime_) public {
        require(token_ != address(0), 'Invalid token address');
        require(startTime_ > block.timestamp, 'Invalid start time');
        require(endTime_ > startTime_, 'Invalid end time');
        token = token_;
        merkleRoot = merkleRoot_;
        startTime = startTime_;
        endTime = endTime_;
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
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(block.timestamp >= startTime, 'Drop not yet available.');
        require(block.timestamp <= endTime, 'Drop already expired.');
        require(!isClaimed(index), 'Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'Transfer failed.');

        emit Claimed(index, account, amount);
    }

    function withdrawRemaining(address recipient) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(recipient, balance), 'Withdraw remaining failed.');
    }
}
