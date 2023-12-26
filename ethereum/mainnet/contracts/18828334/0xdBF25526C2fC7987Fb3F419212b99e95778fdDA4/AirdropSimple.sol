// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./IAirdropSimple.sol";

error AlreadyClaimed();
error InvalidProof();

contract AirdropSimple is IAirdropSimple {
    using SafeERC20 for IERC20;

    address public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 public immutable totalAirdroppedAmount;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;
    uint256 public totalClaimed;

    event Claimed(uint256 index, address account, uint256 amount);

    constructor(AirdropConfig memory cfg) {
        token = cfg.token;
        merkleRoot = cfg.merkleRoot;
        totalAirdroppedAmount = cfg.totalAirdroppedAmount;
    }

    function isClaimed(uint256 index) public view returns (bool) {
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

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external {
        if (isClaimed(index)) revert AlreadyClaimed();

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();

        // Mark it claimed and send the token.
        _setClaimed(index);
        totalClaimed = totalClaimed + amount;
        IERC20(token).safeTransfer(account, amount);

        emit Claimed(index, account, amount);
    }

}
