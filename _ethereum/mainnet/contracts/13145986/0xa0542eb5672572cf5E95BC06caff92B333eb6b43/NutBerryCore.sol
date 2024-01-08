// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./NutBerryEvents.sol";

/// @notice The Layer 2 core protocol.
// Audit-1: ok
contract NutBerryCore is NutBerryEvents {
  /// @dev Constant, the maximum size a single block can be.
  /// Default: 31744 bytes
  function MAX_BLOCK_SIZE () public view virtual returns (uint24) {
    return 31744;
  }

  /// @dev Constant, the inspection period defines how long it takes (in L1 blocks)
  /// until a submitted solution can be finalized.
  /// Default: 60 blocks ~ 14 minutes.
  function INSPECTION_PERIOD () public view virtual returns (uint16) {
    return 60;
  }

  /// Add multiplicator parameter that says:
  /// if any N blocks get flagged, then increase the INSPECTION_PERIOD times INSPECTION_PERIOD_MULTIPLIER
  /// that puts the possible inspection period for these blocks higher up so that
  /// operators and chain users can cooperate on any situation within a bigger timeframe.
  /// That means if someone wrongfully flags valid solutions for blocks,
  /// then this just increases the INSPECTION_PERIOD and operators are not forced into challenges.
  /// If no one challenges any blocks within the increased timeframe,
  /// then the block(s) can be finalized as usual after the elevated INSPECTION_PERIOD.
  function INSPECTION_PERIOD_MULTIPLIER () public view virtual returns (uint256) {
    return 3;
  }

  /// @dev The address of the contract that includes/handles the
  /// `onChallenge` and `onFinalizeSolution` logic.
  /// Default: address(this)
  function _CHALLENGE_IMPLEMENTATION_ADDRESS () internal virtual returns (address) {
    return address(this);
  }

  /// @dev Returns the storage key used for storing the number of the highest finalized block.
  function _FINALIZED_HEIGHT_KEY () internal pure returns (uint256) {
    return 0x777302ffa8e0291a142b7d0ca91add4a3635f6d74d564879c14a0a3f2c9d251c;
  }

  /// @dev Returns the highest finalized block.
  function finalizedHeight () public view returns (uint256 ret) {
    uint256 key = _FINALIZED_HEIGHT_KEY();
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `finalizedHeight`
  function _setFinalizedHeight (uint256 a) internal {
    uint256 key = _FINALIZED_HEIGHT_KEY();
    assembly {
      sstore(key, a)
    }
  }

  /// @dev Returns the storage key used for storing the number of the highest block.
  function _PENDING_HEIGHT_KEY () internal pure returns (uint256) {
    return 0x8171e809ec4f72187317c49280c722650635ce37e7e1d8ea127c8ce58f432b98;
  }

  /// @dev Highest not finalized block
  function pendingHeight () public view returns (uint256 ret) {
    uint256 key = _PENDING_HEIGHT_KEY();
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `pendingHeight`
  function _setPendingHeight (uint256 a) internal {
    uint256 key = _PENDING_HEIGHT_KEY();
    assembly {
      sstore(key, a)
    }
  }

  /// @dev Returns the storage key used for storing the (byte) offset in chunked challenges.
  function _CHALLENGE_OFFSET_KEY () internal pure returns (uint256) {
    return 0xd733644cc0b916a23c558a3a2815e430d2373e6f5bf71acb729373a0dd995878;
  }

  /// @dev tracks the block offset in chunked challenges.
  function _challengeOffset () internal view returns (uint256 ret) {
    uint256 key = _CHALLENGE_OFFSET_KEY();
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `_challengeOffset`
  function _setChallengeOffset (uint256 a) internal {
    uint256 key = _CHALLENGE_OFFSET_KEY();
    assembly {
      sstore(key, a)
    }
  }

  /// @dev Returns the storage key for storing a block hash given `height`.
  function _BLOCK_HASH_KEY (uint256 height) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x4d8e47aa6de2727816b4bbef070a604f701f0084f916418d1cdc240661f562e1)
      mstore(32, height)
      ret := keccak256(0, 64)
    }
  }

  /// @dev Returns the block hash for `height`.
  function _blockHashFor (uint256 height) internal view returns (bytes32 ret) {
    uint256 key = _BLOCK_HASH_KEY(height);
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `_blockHashFor`.
  function _setBlockHash (uint256 height, bytes32 hash) internal {
    uint256 key = _BLOCK_HASH_KEY(height);
    assembly {
      sstore(key, hash)
    }
  }

  /// @dev Returns the storage key for storing a block solution hash for block at `height`.
  function _BLOCK_SOLUTIONS_KEY (uint256 height) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x5ba08b0dee3c3262140f1dba0d9c002446260e37aab5f8128649d20f79d70c24)
      mstore(32, height)
      ret := keccak256(0, 64)
    }
  }

  /// @dev Returns the block solution hash for block at `height`, or zero.
  function _blockSolutionFor (uint256 height) internal view returns (bytes32 ret) {
    uint256 key = _BLOCK_SOLUTIONS_KEY(height);
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `_blockSolutionFor`.
  function _setBlockSolution (uint256 height, bytes32 hash) internal {
    uint256 key = _BLOCK_SOLUTIONS_KEY(height);
    assembly {
      sstore(key, hash)
    }
  }

  function _BLOCK_META_KEY (uint256 height) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xd2cb82084fde0be47b8bfd4b0990b9dd581ec724fb5aeb289572a3777b20326f)
      mstore(32, height)
      ret := keccak256(0, 64)
    }
  }

  /// @dev Holds metadata for blocks.
  /// | finalization target (blockNumber) | least significant bit is a dispute flag |
  function blockMeta (uint256 height) public view returns (uint256 ret) {
    uint256 key = _BLOCK_META_KEY(height);
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `blockMeta`.
  function _setBlockMeta (uint256 height, uint256 val) internal {
    uint256 key = _BLOCK_META_KEY(height);
    assembly {
      sstore(key, val)
    }
  }

  /// @dev Clears storage slots and moves `finalizedHeight` to `blockNumber`.
  /// @param blockNumber The number of the block to finalize.
  function _resolveBlock (uint256 blockNumber) internal {
    _setFinalizedHeight(blockNumber);
    _setChallengeOffset(0);

    _setBlockHash(blockNumber, 0);
    _setBlockSolution(blockNumber, 0);
    _setBlockMeta(blockNumber, 0);
  }

  constructor () {
    assembly {
      // created at block
      sstore(0x319a610c8254af7ecb1f669fb64fa36285b80cad26faf7087184ce1dceb114df, number())
    }
  }

  function _onlyEOA () internal view {
    assembly {
      // if caller is not tx sender, then revert.
      // Thus, we make sure that only regular accounts can submit blocks.

      if iszero(eq(origin(), caller())) {
        revert(0, 0)
      }
    }
  }

  /// @dev This can be used to import custom data into the chain.
  /// This will create a new Block with type=3 and includes
  /// every byte from calldata starting from byte offset 4.
  /// Only regular accounts are allowed to submit blocks.
  function _createBlockMessage () internal {
    _onlyEOA();

    uint256 blockNumber = pendingHeight() + 1;
    _setPendingHeight(blockNumber);

    bytes32 blockHash;
    uint24 maxBlockSize = MAX_BLOCK_SIZE();
    assembly {
      // Computes blockHash from calldata excluding function signature.

      let size := sub(calldatasize(), 4)
      if or(gt(size, maxBlockSize), iszero(size)) {
        // exceeded MAX_BLOCK_SIZE or zero-size block
        revert(0, 0)
      }
      // temporarily save the memory pointer
      let tmp := mload(64)

      // the block nonce / block number.
      mstore(0, blockNumber)
      // block type = 3
      mstore(32, 3)
      mstore(64, timestamp())

      // copy from calldata and hash
      calldatacopy(96, 4, size)
      blockHash := keccak256(0, add(size, 96))

      // restore memory pointer
      mstore(64, tmp)
      // zero the slot
      mstore(96, 0)
    }
    _setBlockHash(blockNumber, blockHash);

    emit CustomBlockBeacon();
  }

  /// @dev Submit a transaction blob (a block).
  /// The block data is expected right after the 4-byte function signature.
  /// Only regular accounts are allowed to submit blocks.
  function submitBlock () external {
    _onlyEOA();

    uint256 blockNumber = pendingHeight() + 1;
    _setPendingHeight(blockNumber);

    // a user submitted blockType = 2
    bytes32 blockHash;
    uint24 maxBlockSize = MAX_BLOCK_SIZE();
    assembly {
      // Computes blockHash from calldata excluding function signature.

      let size := sub(calldatasize(), 4)
      if or(gt(size, maxBlockSize), iszero(size)) {
        // exceeded MAX_BLOCK_SIZE or zero-size block
        revert(0, 0)
      }
      // temporarily save the memory pointer
      let tmp := mload(64)

      // the block nonce / block number.
      mstore(0, blockNumber)
      // block type = 2
      mstore(32, 2)
      mstore(64, timestamp())

      // copy from calldata and hash
      calldatacopy(96, 4, size)
      blockHash := keccak256(0, add(size, 96))

      // restore memory pointer
      mstore(64, tmp)
      // zero the slot
      mstore(96, 0)
    }
    _setBlockHash(blockNumber, blockHash);

    emit BlockBeacon();
  }

  /// @dev Register solution for given `blockNumber`.
  /// Up to 256 solutions can be registered ahead in time.
  /// calldata layout:
  /// <4 byte function sig>
  /// <32 bytes number of first block>
  /// <32 bytes for each solution for blocks starting at first block (increments by one)>
  /// Note: You can put `holes` in the layout by inserting a 32 byte zero value.
  /// Only regular accounts are allowed to submit solutions.
  function submitSolution () external {
    _onlyEOA();

    uint256 min = finalizedHeight() + 1;
    uint256 max = min + 255;

    {
      uint256 tmp = pendingHeight();
      if (max > tmp) {
        max = tmp;
      }
    }

    uint256 finalizationTarget = (block.number + INSPECTION_PERIOD()) << 1;
    assembly {
      // underflow ok
      let blockNum := sub(calldataload(4), 1)

      for { let i := 36 } lt(i, calldatasize()) { i := add(i, 32) } {
        blockNum := add(blockNum, 1)
        let solutionHash := calldataload(i)

        if or( iszero(solutionHash), or( lt(blockNum, min), gt(blockNum, max) ) ) {
          continue
        }

        // inline _BLOCK_SOLUTIONS_KEY
        mstore(0, 0x5ba08b0dee3c3262140f1dba0d9c002446260e37aab5f8128649d20f79d70c24)
        mstore(32, blockNum)
        let key := keccak256(0, 64)

        if iszero(sload(key)) {
          // store hash
          sstore(key, solutionHash)

          // store finalizationTarget
          // inline _BLOCK_META_KEY
          mstore(0, 0xd2cb82084fde0be47b8bfd4b0990b9dd581ec724fb5aeb289572a3777b20326f)
          key := keccak256(0, 64)
          sstore(key, finalizationTarget)
        }
      }

      // emit NewSolution();
      log1(0, 0, 0xd180748b1b0c35f46942acf30f64a94a79d303ffd18cce62cbbb733b436298cb)
      stop()
    }
  }

  /// @dev Flags up to 256 solutions. This will increase the inspection period for the block(s).
  /// @param blockNumber the starting point.
  /// @param bitmask Up to 256 solutions can be flagged.
  /// Thus, a solution will be flagged if the corresponding bit is `1`.
  /// LSB first.
  function dispute (uint256 blockNumber, uint256 bitmask) external {
    uint256 min = finalizedHeight();
    uint256 finalizationTarget = 1 | ((block.number + (INSPECTION_PERIOD() * INSPECTION_PERIOD_MULTIPLIER())) << 1);

    for (uint256 i = 0; i < 256; i++) {
      uint256 flag = (bitmask >> i) & 1;
      if (flag == 0) {
        continue;
      }

      uint256 blockN = blockNumber + i;

      if (blockN > min) {
        // if a solution exists and is not not already disputed
        uint256 v = blockMeta(blockN);
        if (v != 0 && v & 1 == 0) {
          // set dispute flag and finalization target
          _setBlockMeta(blockN, finalizationTarget);
        }
      }
    }
  }

  /// @dev Challenge the solution or just verify the next pending block directly.
  /// Expects the block data right after the function signature to be included in the call.
  /// calldata layout:
  /// < 4 bytes function sig >
  /// < 32 bytes size of block >
  /// < 32 bytes number of challenge rounds >
  /// < arbitrary witness data >
  /// < data of block >
  function challenge () external {
    uint256 blockSize;
    uint256 blockDataStart;
    assembly {
      blockSize := calldataload(4)
      blockDataStart := sub(calldatasize(), blockSize)
    }

    uint256 blockNumber = finalizedHeight() + 1;

    {
      // validate the block data
      bytes32 blockHash;
      assembly {
        let tmp := mload(64)
        calldatacopy(0, blockDataStart, blockSize)
        blockHash := keccak256(0, blockSize)
        mstore(64, tmp)
        mstore(96, 0)
      }
      // blockHash must match
      require(_blockHashFor(blockNumber) == blockHash);
    }

    uint256 challengeOffset = _challengeOffset();
    address challengeHandler = _CHALLENGE_IMPLEMENTATION_ADDRESS();
    assembly {
      // function onChallenge ()
      mstore(128, 0xc47c519d)
      // additional arguments
      mstore(160, challengeOffset)
      mstore(192, challengeHandler)
      // copy calldata
      calldatacopy(224, 4, calldatasize())

      // stay in this context
      let success := callcode(gas(), challengeHandler, 0, 156, add(calldatasize(), 64), 0, 32)
      if iszero(success) {
        // Problem:
        // If for whatever reason, the challenge never proceeds,
        // then using some kind of global timeout to determine
        // that the transactions in this block until the last challengeOffset are accepted
        // but everything else is discarded is one way to implement this recovery mechanism.
        // For simplicity, just revert now. This situation can be resolved via chain governance.
        revert(0, 0)
      }
      challengeOffset := mload(0)
    }

    bool complete = !(challengeOffset < blockSize);

    if (complete) {
      // if we are done, finalize this block
      _resolveBlock(blockNumber);
    } else {
      // not done yet, save offset
      _setChallengeOffset(challengeOffset);
    }

    assembly {
      // this helps chain clients to better estimate challenge costs.
      // this may change in the future and thus is not part of the function sig.
      mstore(0, complete)
      mstore(32, challengeOffset)
      return(0, 64)
    }
  }

  /// @dev Returns true if `blockNumber` can be finalized, else false.
  /// Helper function for chain clients.
  /// @param blockNumber The number of the block in question.
  /// @return True if the block can be finalized, otherwise false.
  function canFinalizeBlock (uint256 blockNumber) public view returns (bool) {
    // shift left by 1, the lsb is the dispute bit
    uint256 target = blockMeta(blockNumber) >> 1;
    // solution too young
    if (target == 0 || block.number < target) {
      return false;
    }

    // if there is no active challenge, then yes
    return _challengeOffset() == 0;
  }

  /// @dev Finalize solution and move to the next block.
  /// This must happen in block order.
  /// Nothing can be finalized if a challenge is still active.
  /// and cannot happen if there is an active challenge.
  /// calldata layout:
  /// < 4 byte function sig >
  /// < 32 byte block number >
  /// ---
  /// < 32 byte length of solution >
  /// < solution... >
  /// ---
  /// < repeat above (---) >
  function finalizeSolution () external {
    if (_challengeOffset() != 0) {
      revert();
    }

    address challengeHandler = _CHALLENGE_IMPLEMENTATION_ADDRESS();
    assembly {
      if lt(calldatasize(), 68) {
        revert(0, 0)
      }
      // underflow ok
      let blockNumber := sub(calldataload(4), 1)

      let ptr := 36
      for { } lt(ptr, calldatasize()) { } {
        blockNumber := add(blockNumber, 1)
        // this is going to be re-used
        mstore(32, blockNumber)

        let length := calldataload(ptr)
        ptr := add(ptr, 32)

        // being optimistic, clear all the storage values in advance

        // reset _BLOCK_HASH_KEY
        mstore(0, 0x4d8e47aa6de2727816b4bbef070a604f701f0084f916418d1cdc240661f562e1)
        sstore(keccak256(0, 64), 0)

        // inline _BLOCK_SOLUTIONS_KEY
        mstore(0, 0x5ba08b0dee3c3262140f1dba0d9c002446260e37aab5f8128649d20f79d70c24)
        let k := keccak256(0, 64)
        let solutionHash := sload(k)
        // reset - _BLOCK_SOLUTIONS_KEY
        sstore(k, 0)

        // _BLOCK_META_KEY
        mstore(0, 0xd2cb82084fde0be47b8bfd4b0990b9dd581ec724fb5aeb289572a3777b20326f)
        k := keccak256(0, 64)
        // check if the finalization target is reached,
        // else revert
        let finalizationTarget := shr(1, sload(k))
        if or( lt( number(), finalizationTarget ), iszero(finalizationTarget) ) {
          // can not be finalized yet
          revert(0, 0)
        }
        // clear the slot
        sstore(k, 0)

        // function onFinalizeSolution (uint256 blockNumber, bytes32 hash)
        mstore(0, 0xc8470b09)
        // blockNumber is still stored @ 32
        mstore(64, solutionHash)
        // witness
        calldatacopy(96, ptr, length)
        // call
        let success := callcode(gas(), challengeHandler, 0, 28, add(length, 68), 0, 0)
        if iszero(success) {
          revert(0, 0)
        }

        ptr := add(ptr, length)
      }

      if iszero(eq(ptr, calldatasize())) {
        // malformed calldata?
        revert(0, 0)
      }

      // inline _setFinalizedHeight and save the new height.
      // at this point, blockNumber is assumed to be validated inside the loop
      sstore(0x777302ffa8e0291a142b7d0ca91add4a3635f6d74d564879c14a0a3f2c9d251c, blockNumber)

      // done
      stop()
    }
  }

  /// @dev Loads storage for `key`. Only attempts a load if execution happens
  /// inside a challenge, otherwise returns zero.
  function _getStorageL1 (bytes32 key) internal view returns (uint256 v) {
    assembly {
      if origin() {
        v := sload(key)
      }
    }
  }

  /// @dev Reflect a storage slot `key` with `value` to Layer 1.
  /// Useful for propagating storage changes to the contract on L1.
  function _setStorageL1 (bytes32 key, uint256 value) internal {
    assembly {
      switch origin()
      case 0 {
        // emit a event on L2
        log3(0, 0, 1, key, value)
      }
      default {
        // apply the change directly on L1 (challenge)
        sstore(key, value)
      }
    }
  }

  /// @dev Reflect a delta for storage slot with `key` to Layer 1.
  /// Useful for propagating storage changes to the contract on L1.
  function _incrementStorageL1 (bytes32 key, uint256 value) internal {
    assembly {
      switch origin()
      case 0 {
        // emit a event on L2
        log3(0, 0, 2, key, value)
      }
      default {
        // apply the change directly on L1 (challenge)
        sstore(key, add(sload(key), value))
      }
    }
  }
}
