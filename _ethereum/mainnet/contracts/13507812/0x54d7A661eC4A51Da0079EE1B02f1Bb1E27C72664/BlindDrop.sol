// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title BlindDrop
 * @author the-torn
 *
 * @notice Securely generate a random seed for use in a random NFT distribution.
 *
 *  Inspired by Hashmasks.
 */
abstract contract BlindDrop {
  bytes32 public immutable GUARDIAN_HASH;
  uint256 public immutable GUARDIAN_WINDOW_DURATION_SECONDS;
  uint256 public immutable DISTRIBUTION_AUTO_END_TIMESTAMP;

  uint256 private _automaticSeedBlockNumber;
  bytes32 private _automaticSeed;
  uint256 private _guardianWindowEndTimestamp;
  bytes32 private _guardianOrFallbackSeed;
  uint256 private _fallbackSeedBlockNumber;
  bytes32 private _finalSeed;

  event SetSeedBlockNumber(uint256 blockNumber);
  event SetSeed(bytes32 seed);
  event SetFinalSeed(bytes32 seed);

  constructor(
    bytes32 guardianHash,
    uint256 guardianWindowDurationSeconds,
    uint256 maxDistributionDurationSeconds
  ) {
    GUARDIAN_HASH = guardianHash;
    GUARDIAN_WINDOW_DURATION_SECONDS = guardianWindowDurationSeconds;
    DISTRIBUTION_AUTO_END_TIMESTAMP = block.timestamp + maxDistributionDurationSeconds;
  }

  function _setAutomaticSeedBlockNumber(
    bool maxSupplyWasReached
  )
    internal
  {
    require(
      _automaticSeedBlockNumber == 0,
      "Seed block number already set"
    );

    // Anyone can finalize the automatic seed block number once either of the following is true:
    //   1. all tokens were claimed; or
    //   2. we reached the auto-end timestamp.
    require(
      (
        maxSupplyWasReached ||
        block.timestamp >= DISTRIBUTION_AUTO_END_TIMESTAMP
      ),
      "Distribution not over"
    );

    uint256 automaticSeedBlockNumber = block.number + 1;
    _automaticSeedBlockNumber = automaticSeedBlockNumber;
    emit SetSeedBlockNumber(automaticSeedBlockNumber);
  }

  function setAutomaticSeed()
    external
  {
    require(
      _automaticSeed == bytes32(0),
      "Automatic seed already set"
    );

    bytes32 automaticSeed = _getSeedFromBlockNumber(_automaticSeedBlockNumber);
    _automaticSeed = automaticSeed;
    emit SetSeed(automaticSeed);

    // Mark the start of the guardian window, during which the guardian can provide their seed.
    _guardianWindowEndTimestamp = block.timestamp + GUARDIAN_WINDOW_DURATION_SECONDS;
  }

  function setGuardianSeed(
    bytes32 guardianSeed
  )
    external
  {
    require(
      _guardianOrFallbackSeed == bytes32(0),
      "Seed already set"
    );
    require(
      _automaticSeed != bytes32(0),
      "Automatic seed not set"
    );
    require(
      block.timestamp < _guardianWindowEndTimestamp,
      "Guardian window elapsed"
    );
    require(
      keccak256(abi.encodePacked(guardianSeed)) == GUARDIAN_HASH,
      "Guardian seed invalid"
    );
    _guardianOrFallbackSeed = guardianSeed;
    emit SetSeed(guardianSeed);
  }

  function setFallbackSeedBlockNumber()
    external
  {
    require(
      _fallbackSeedBlockNumber == 0,
      "Seed block number already set"
    );
    require(
      _automaticSeed != bytes32(0),
      "Automatic seed not set"
    );
    require(
      block.timestamp >= _guardianWindowEndTimestamp,
      "Guardian window has not ended"
    );

    uint256 fallbackSeedBlockNumber = block.number + 1;
    _fallbackSeedBlockNumber = fallbackSeedBlockNumber;
    emit SetSeedBlockNumber(fallbackSeedBlockNumber);
  }

  function setFallbackSeed()
    external
  {
    require(
      _guardianOrFallbackSeed == bytes32(0),
      "Seed already set"
    );

    bytes32 fallbackSeed = _getSeedFromBlockNumber(_fallbackSeedBlockNumber);
    _guardianOrFallbackSeed = fallbackSeed;
    emit SetSeed(fallbackSeed);
  }

  function setFinalSeed()
    external
  {
    require(
      _finalSeed == bytes32(0),
      "Final seed already set"
    );
    require(
      _guardianOrFallbackSeed != bytes32(0),
      "Guardian/fallback seed not set"
    );

    bytes32 finalSeed = _automaticSeed ^ _guardianOrFallbackSeed;
    _finalSeed = finalSeed;
    emit SetFinalSeed(finalSeed);
  }

  function _getSeedFromBlockNumber(
    uint256 targetBlockNumber
  )
    internal
    view
    returns (bytes32)
  {
    require(
      targetBlockNumber != 0,
      "Block number not set"
    );
    // Important: blockhash(targetBlockNumber) will return zero if the block was not yet mined.
    require(
      targetBlockNumber < block.number,
      "Block number not mined"
    );

    // If the hash for the desired block is unavailable, fall back to the most recent block.
    if (block.number - targetBlockNumber > 256) {
      targetBlockNumber = block.number - 1;
    }

    return blockhash(targetBlockNumber);
  }

  /**
   * @notice Get the blind drop seed which is securely determined after the end of the distribution.
   *
   *  Revert if the seed has not been set.
   */
  function getFinalSeed()
    public
    view
    returns (bytes32)
  {
    bytes32 finalSeed = _finalSeed;
    require(
      finalSeed != bytes32(0),
      "Final seed not set"
    );
    return finalSeed;
  }
}
