// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Base.sol";

contract PrimeAnchor is Base {
  // struct
  struct Proofs {
    uint256 startBlock;
    uint256 endBlock;
    bytes32 txnRoot;
    bytes32 stateRoot;
    bytes32 cid;
  }

  // vars
  mapping(uint256 => Proofs) public proofs;
  uint256 public currentIndex;

  // events
  event ProofPublished(uint256 indexed idx, Proofs proofsBatch);

  function publishProof(
    uint256 _startBlock,
    uint256 _endBlock,
    bytes32 _txnRoot,
    bytes32 _stateRoot,
    bytes32 _cid
  ) public onlyRole("publishProof") {
    require(_endBlock >= _startBlock, "Invalid blocks range");
    if (currentIndex > 0) {
      uint256 previousEndBlock = proofs[currentIndex - 1].endBlock;
      require(_startBlock == previousEndBlock + 1, "Blocks range mismatch");
    }

    Proofs memory proofsBatch = Proofs({
      startBlock: _startBlock, //
      endBlock: _endBlock,
      txnRoot: _txnRoot,
      stateRoot: _stateRoot,
      cid: _cid
    });

    proofs[currentIndex] = proofsBatch;
    emit ProofPublished(currentIndex, proofsBatch);
    currentIndex++;
  }

  function publishProofs(
    uint256[] calldata _startBlocks,
    uint256[] calldata _endBlocks,
    bytes32[] calldata _txnRoots,
    bytes32[] calldata _stateRoots,
    bytes32[] calldata _cids
  ) public onlyRole("publishProofs") {
    require(_txnRoots.length == _stateRoots.length, "Input mismatch");
    require(_txnRoots.length == _cids.length, "Input mismatch");

    uint256 size = _txnRoots.length;
    for (uint256 i; i < size; i++) {
      publishProof(_startBlocks[i], _endBlocks[i], _txnRoots[i], _stateRoots[i], _cids[i]);
    }
  }
}
