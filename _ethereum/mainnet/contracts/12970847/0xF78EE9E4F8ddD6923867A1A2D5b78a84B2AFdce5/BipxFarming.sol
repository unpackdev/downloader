// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

contract BipxFarming {
	using SafeERC20 for IERC20;

	// This event is triggered whenever a call to #claim succeeds.
	event Claimed(uint256 index, address account);

	address public immutable bipxToken;
	address public immutable usdtToken;

	bytes32 public bipxMerkleRoot;
	bytes32 public usdtMerkleRoot;
	address owner;
	bool isClaimingStopped;

	mapping(bytes32 => mapping(uint256 => uint256)) private claimedBitMap;

	constructor(address bipx_, address usdt_) public {
		bipxToken = bipx_;
		usdtToken = usdt_;
		owner = msg.sender;
		isClaimingStopped = true;
	}

	modifier _ownerOnly() {
		require(msg.sender == owner);
		_;
	}

	function setMerkleRoot(bytes32 bipxMerkleRoot_, bytes32 usdtMerkleRoot_) public _ownerOnly {
		bipxMerkleRoot = bipxMerkleRoot_;
		usdtMerkleRoot = usdtMerkleRoot_;
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
		uint256 claimedWord = claimedBitMap[bipxMerkleRoot][claimedWordIndex];
		uint256 mask = (1 << claimedBitIndex);
		return claimedWord & mask == mask;
	}

	function _setClaimed(uint256 index) private {
		uint256 claimedWordIndex = index / 256;
		uint256 claimedBitIndex = index % 256;
		claimedBitMap[bipxMerkleRoot][claimedWordIndex] = claimedBitMap[bipxMerkleRoot][claimedWordIndex] | (1 << claimedBitIndex);
	}

	function claim(uint256 index, address account, uint256 bipxAmount, bytes32[] calldata bipxMerkleProof, uint256 usdtAmount, bytes32[] calldata usdtMerkleProof) external {
		require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');
		require(!isClaimingStopped, 'Claim is not available currently.');

		// Verify the merkle proof.
		bytes32 bipxNode = keccak256(abi.encodePacked(index, account, bipxAmount));
		bytes32 usdtNode = keccak256(abi.encodePacked(index, account, usdtAmount));
		require(MerkleProof.verify(bipxMerkleProof, bipxMerkleRoot, bipxNode), 'MerkleDistributor: Invalid BIPX proof.');
		require(MerkleProof.verify(usdtMerkleProof, usdtMerkleRoot, usdtNode), 'MerkleDistributor: Invalid USDT proof.');

		// Mark it claimed and send the token.
		_setClaimed(index);
		require(IERC20(bipxToken).transfer(account, bipxAmount), 'MerkleDistributor: Transfer failed.');
		require(IERC20(usdtToken).transfer(account, usdtAmount), 'MerkleDistributor: Transfer failed.');

		emit Claimed(index, account);
	}
}