// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.0;

import "./IERC20.sol";
import "./MerkleProof.sol";

contract HubDistributor {
	// This event is triggered whenever a call to #claim succeeds.
	event Claimed(uint256 index, address account, uint256 amount);

	address public immutable token;
	bytes32 public merkleRoot;
	address owner;
	bool isClaimingStopped;

	mapping(bytes32 => mapping(uint256 => uint256)) private claimedBitMap;

	constructor(address token_) public {
		token = token_;
		owner = msg.sender;
		isClaimingStopped = true;
	}

	modifier _ownerOnly() {
		require(msg.sender == owner);
		_;
	}

	function setMerkleRoot(bytes32 merkleRoot_) public _ownerOnly {
		merkleRoot = merkleRoot_;
	}

	function stopClaiming() public _ownerOnly {
		isClaimingStopped = true;
	}

	function startClaiming() public _ownerOnly {
		isClaimingStopped = false;
	}

	function isClaimed(uint256 index) public view returns (bool) {
		uint256 claimedWordIndex = index / 256;
		uint256 claimedBitIndex = index % 256;
		uint256 claimedWord = claimedBitMap[merkleRoot][claimedWordIndex];
		uint256 mask = (1 << claimedBitIndex);
		return claimedWord & mask == mask;
	}

	function _setClaimed(uint256 index) private {
		uint256 claimedWordIndex = index / 256;
		uint256 claimedBitIndex = index % 256;
		claimedBitMap[merkleRoot][claimedWordIndex] = claimedBitMap[merkleRoot][claimedWordIndex] | (1 << claimedBitIndex);
	}

	function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external {
		require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');
		require(!isClaimingStopped, 'Claim is not available currently.');

		// Verify the merkle proof.
		bytes32 node = keccak256(abi.encodePacked(index, account, amount));
		require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

		// Mark it claimed and send the token.
		_setClaimed(index);
		require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

		emit Claimed(index, account, amount);
	}
}