//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor, ERC1155Holder {
  using SafeMath for uint256;
  address public immutable override erc1155Token;
  uint256 public immutable override tokenId;
  bytes32 public immutable override merkleRoot;
  // This is a packed array of booleans.
  mapping(uint256 => uint256) private claimedBitMap;

  uint256 public immutable emergencyTimeout;
  address public immutable emergencyReceiver;

  constructor(
    address erc1155Token_,
		uint256 tokenId_,
    bytes32 merkleRoot_,
    uint256 _emergencyTimeout,
    address _emergencyReceiver
  ) {
		erc1155Token = erc1155Token_;
		tokenId = tokenId_;
    merkleRoot = merkleRoot_;
    emergencyTimeout = _emergencyTimeout;
    emergencyReceiver = _emergencyReceiver;
    require(_emergencyTimeout > block.timestamp, "WRONG_EMERGENCY_TIMEOUT");
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
    require(msg.sender == account, "Only owner can claim");
    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(
      MerkleProof.verify(merkleProof, merkleRoot, node),
      "MerkleDistributor: Invalid proof."
    );
    // Mark it claimed and send the token.
    _setClaimed(index);

		IERC1155(erc1155Token).safeTransferFrom(address(this), account, tokenId, amount, new bytes(0));

    emit Claimed(index, account, amount);
  }

  function emergencyWithdrawal() public {
    require(block.timestamp > emergencyTimeout, "TIMEOUT_NOT_EXPIRED");

		IERC1155(erc1155Token).safeTransferFrom(
			address(this),
			emergencyReceiver,
			tokenId,
			IERC1155(erc1155Token).balanceOf(address(this), tokenId),
			new bytes(0)
		);
  }
}
