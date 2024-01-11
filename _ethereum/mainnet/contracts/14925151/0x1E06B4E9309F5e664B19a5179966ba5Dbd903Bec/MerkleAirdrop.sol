// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract MerkleAirdrop is Ownable {

  event Claim(address indexed to, uint256 amount);

  using SafeERC20 for IERC20;
  IERC20 public token;
  bytes32 public immutable merkleRoot;
  uint256 public airdropOpens  = 0;
  uint256 public airdropCloses = 1;
  mapping(address => bool) public hasClaimed;

  constructor(
    address _tokenAddress,
    bytes32 _merkleRoot
  ) {
    token = IERC20(_tokenAddress);
    merkleRoot = _merkleRoot;
  }

  function claim(address to, uint256 amount, bytes32[] calldata proof) external {
    require(to == msg.sender, "claim: no permission");
    require(block.timestamp >= airdropOpens && block.timestamp <= airdropCloses, "claim: window closed");

    if (hasClaimed[to]) {
      revert("claim: Already claimed");
    }

    bytes32 leaf = keccak256(abi.encodePacked(to, amount));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
    if (!isValidLeaf) {
      revert("claim: invalid leaf");
    }

    hasClaimed[to] = true;
    token.safeTransfer(to, amount);
    emit Claim(to, amount);
  }

  function getTokenBalance() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function withdraw(uint256 amount) external onlyOwner {
    token.safeTransfer(msg.sender, amount);
  }

  function editWindow(
    uint256 _airdropOpens,
    uint256 _airdropCloses
  ) external onlyOwner {
    require(
      _airdropCloses > _airdropOpens,
      "Time combination not allowed"
    );

    airdropOpens = _airdropOpens;
    airdropCloses = _airdropCloses;
  }
}
