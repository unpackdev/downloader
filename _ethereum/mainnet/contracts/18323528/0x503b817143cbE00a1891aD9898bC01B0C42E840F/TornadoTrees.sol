// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableMerkleTree.sol";
import "./ITornadoTrees.sol";
import "./IHasher.sol";

contract TornadoTrees is ITornadoTrees {
  OwnableMerkleTree public immutable depositTree;
  OwnableMerkleTree public immutable withdrawalTree;
  IHasher public immutable hasher;
  address public pgRouter;

  event DepositData(address instance, bytes32 indexed hash, uint256 block, uint256 index);
  event WithdrawalData(address instance, bytes32 indexed hash, uint256 block, uint256 index);

  struct TreeLeaf {
    address instance;
    bytes32 hash;
    uint256 block;
  }

  modifier onlyPgRouter {
    require(msg.sender == pgRouter, "Not authorized");
    _;
  }

  constructor(
    address _pgRouter,
    address _hasher2,
    address _hasher3,
    uint32 _levels
  ) {
    pgRouter = _pgRouter;
    hasher = IHasher(_hasher3);
    depositTree = new OwnableMerkleTree(_levels, IHasher(_hasher2));
    withdrawalTree = new OwnableMerkleTree(_levels, IHasher(_hasher2));
  }

  function registerDeposit(address _instance, bytes32 _commitment) external override onlyPgRouter {
    bytes32 leaf = hasher.poseidon([bytes32(uint256(uint160(_instance))), _commitment, bytes32(blockNumber())]);
    uint32 index = depositTree.insert(leaf);
    emit DepositData(_instance, _commitment, blockNumber(), uint256(index));
  }

  function registerWithdrawal(address _instance, bytes32 _nullifier) external override onlyPgRouter {
    bytes32 leaf = hasher.poseidon([bytes32(uint256(uint160(_instance))), _nullifier, bytes32(blockNumber())]);
    uint32 index = withdrawalTree.insert(leaf);
    emit WithdrawalData(_instance, _nullifier, blockNumber(), uint256(index));
  }

  function validateRoots(bytes32 _depositRoot, bytes32 _withdrawalRoot) public view {
    require(depositTree.isKnownRoot(_depositRoot), "Incorrect deposit tree root");
    require(withdrawalTree.isKnownRoot(_withdrawalRoot), "Incorrect withdrawal tree root");
  }

  function depositRoot() external view returns (bytes32) {
    return depositTree.getLastRoot();
  }

  function withdrawalRoot() external view returns (bytes32) {
    return withdrawalTree.getLastRoot();
  }

  function withdrawalTreeSize() external view returns (uint32) {
    return withdrawalTree.nextIndex();
  }

  function depositTreeSize() external view returns (uint32) {
    return depositTree.nextIndex();
  }

  function blockNumber() public view virtual returns (uint256) {
    return block.number;
  }
}
