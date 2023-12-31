// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./MerkleProofUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract Staking is AccessControl {
  struct UserRewardsLeaf {
    address user;
    uint256 amount;
  }

  mapping(address => uint256) public claimed;

  bytes32 public constant REWARDS_UPDATER_ROLE =
    keccak256("REWARDS_UPDATER_ROLE");

  bytes32 public merkleRoot;
  uint256 public totalRewards;
  uint256 public lastBlockSnapshot;

  event UpdateRewards(
    bytes32 indexed _merkeRoot,
    uint256 addAmount,
    uint256 blockSnapshot
  );
  event ClaimRewards(
    address indexed caller,
    address indexed user,
    uint256 amount
  );

  constructor() {
    _disableInitializers();
  }

  function initialize() external initializer {
    __AccessControl_init();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(REWARDS_UPDATER_ROLE, msg.sender);
  }

  function updateRewards(
    bytes32 newMerkleRoot,
    uint256 addAmount,
    uint256 blockSnapshot
  ) external payable onlyRole(REWARDS_UPDATER_ROLE) {
    require(msg.value == addAmount, "S: invalid value");
    require(blockSnapshot > lastBlockSnapshot, "S: invalid blockSnapshot");
    require(newMerkleRoot != bytes32(0), "S: invalid root");

    lastBlockSnapshot = blockSnapshot;
    totalRewards += addAmount;
    merkleRoot = newMerkleRoot;

    emit UpdateRewards(newMerkleRoot, addAmount, blockSnapshot);
  }

  function claimRewards(
    UserRewardsLeaf calldata leaf,
    bytes32[] calldata proof
  ) external {
    uint256 _claimed = claimed[leaf.user];
    require(leaf.amount > _claimed, "S: no rewards");

    _verifyProof(leaf, proof);

    uint256 toClaim = leaf.amount - _claimed;

    claimed[leaf.user] = leaf.amount;

    payable(leaf.user).transfer(toClaim);

    emit ClaimRewards(msg.sender, leaf.user, toClaim);
  }

  function withdraw(
    address payable withdrawTo,
    uint256 amount
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    withdrawTo.transfer(amount);
  }

  function _verifyProof(
    UserRewardsLeaf calldata leaf,
    bytes32[] calldata proof
  ) private view {
    bytes32 encodedLeaf = keccak256(
      bytes.concat(keccak256(abi.encode(leaf.user, leaf.amount)))
    );

    require(
      MerkleProof.verify(proof, merkleRoot, encodedLeaf),
      "S: invalid proof"
    );
  }
}
