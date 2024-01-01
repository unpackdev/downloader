/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

/**
 * @title InstantMintTimeBasedRateLimiter
 *
 * @notice This abstract contract implements two rate limiters: one for minting
 *         and one for redeeming. Each limit is completely independent: mints
 *         and redemption don't offset each other. Each limit is associated
 *         with a duration, after which the tracked amount is reset. The
 *         amounts tracked are agnostic to a specific token; the usage is
 *         determined by the inheriting contracts.
 *
 * @dev Although this contract has all of its functions implemented, this
 *      contract is marked abstract to prevent an accidental deployment and to
 *      signify that we would never deploy this contract standalone.
 *
 */
abstract contract MintTimeBasedRateLimiter {
  // `currentMintAmount` resets after this interval (in seconds)
  uint256 public resetMintDuration;
  // timestamp when `currentMintAmount` was last reset
  uint256 public lastResetMintTime;

  // maximum amount that can be minted during a `resetMintDuration` window
  uint256 public mintLimit;
  // amount already minted during the current `resetMintDuration` window
  uint256 public currentMintAmount;

  /**
   * @notice In the constructor, we initialize the variables for the mint and
   *         redemption rate limiters.
   *
   * @param _mintResetDuration   `currentMintAmount` resets after this interval
   *                                    (in seconds)
   * @param _instantMintLimit           maximum amount that can be minted during a
   *                                    `resetMintDuration` window
   *
   * @dev If a duration is zero, the limit resets before each mint/redemption.
   * @dev If a limit is zero, the relevant check always fails.
   */
  constructor(uint256 _mintResetDuration, uint256 _instantMintLimit) {
    resetMintDuration = _mintResetDuration; // can be zero for per-block limit
    mintLimit = _instantMintLimit; // can be zero to disable minting

    lastResetMintTime = block.timestamp;
  }

  /**
   * @notice Checks the requested mint amount against the rate limiter (and
   *         updates the remaining amount)
   *
   * @param amount The requested mint amount
   *
   * @dev Reverts if the requested mint amount exceeds the current limit
   */
  function _checkAndUpdateInstantMintLimit(uint256 amount) internal {
    require(amount > 0, "RateLimit: mint amount can't be zero");

    if (block.timestamp >= lastResetMintTime + resetMintDuration) {
      // time has passed, reset
      currentMintAmount = 0;
      lastResetMintTime = block.timestamp;
    }
    require(
      amount <= mintLimit - currentMintAmount,
      "RateLimit: Mint exceeds rate limit"
    );

    currentMintAmount += amount;
  }

  /**
   * @notice Update the amount of token that can be minted during one duration
   *
   * @param _mintLimit The token amount
   *
   * @dev If a limit is zero, the relevant check always fails.
   */
  function _setMintLimit(uint256 _mintLimit) internal {
    mintLimit = _mintLimit;
    emit MintLimitSet(_mintLimit);
  }

  /**
   * @notice Update the duration for the mint rate limiter
   *
   * @param _mintResetDuration The duration in seconds
   *
   * @dev If a duration is zero, the limit resets before each mint/redemption
   */
  function _setMintLimitDuration(uint256 _mintResetDuration) internal {
    resetMintDuration = _mintResetDuration;
    emit MintLimitDurationSet(_mintResetDuration);
  }

  /**
   * @notice Event emitted when mint limit is set
   *
   * @param mintLimit How much of some token can be minted within
   *                  an interval of length `resetMintDuration`
   *
   * @dev See inheriting contract for representation
   */
  event MintLimitSet(uint256 mintLimit);

  /**
   * @notice Event emitted when mint limit duration is set
   *
   * @param instantMintLimitDuration The time window in which `mintLimit`
   *                          of some token can be minted
   *
   * @dev instantMintLimitDuration is specified in seconds
   */
  event MintLimitDurationSet(uint256 instantMintLimitDuration);
}
