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

import "./AccessControlEnumerable.sol";
import "./Pricer.sol";
import "./IRWAOracleSetter.sol";

contract PricerWithOracle is Pricer {
  // Pointer to rwaOracle
  IRWAOracleSetter public immutable rwaOracle;

  // Helper constant that allows us to specify basis points in calculations
  int256 public constant BPS_DENOMINATOR = 10_000;

  /**
   * @dev OPS_MAX_CHANGE_DIFF_BPS is a constant that represents the maximum percentage change allowed in the price of an asset
   * in a single oracle update. It is set to 20 basis points (0.2%).
   */
  uint256 public constant OPS_MAX_CHANGE_DIFF_BPS = 1000; // Edited for staging

  /**
   * @dev The maximum allowed difference between the current timestamp and the timestamp of the oracle price update.
   */
  uint256 public maxTimestampDiff = 30 days;

  bytes32 public constant ADD_PRICE_OPS_ROLE = keccak256("ADD_PRICE_OPS_ROLE");

  constructor(
    address admin,
    address priceSetter,
    address _rwaOracle
  ) Pricer(admin, priceSetter) {
    rwaOracle = IRWAOracleSetter(_rwaOracle);

    // Set initial priceId data
    uint256 priceId = ++currentPriceId;
    (uint256 latestOraclePrice, uint256 timestamp) = rwaOracle.getPriceData();
    prices[priceId] = PriceInfo(latestOraclePrice, timestamp);
    priceIds.push(priceId);
    latestPriceId = priceId;
    emit PriceAdded(priceId, latestOraclePrice, timestamp);
  }

  /**
   * @dev Checks if the given priceIds are valid by verifying that their corresponding prices were updated
   * within the last `maxTimestampDiff` seconds.
   * @param priceIds An array of priceIds to check validity for.
   * @return A boolean indicating whether all the given priceIds are valid or not.
   */
  function isValid(uint256[] calldata priceIds) external view returns (bool) {
    for (uint256 i = 0; i < priceIds.length; i++) {
      // timestamp is more than maxTimestampDiff in the past
      if (prices[priceIds[i]].timestamp < block.timestamp - maxTimestampDiff) {
        return false;
      }
    }
    return true;
  }

  /**
   * @dev Adds a new price and timestamp to the price history, subject to certain conditions.
   * Only callable by an account with the `ADD_PRICE_OPS_ROLE` role.
   * @param price The new price to add.
   * @param timestamp The timestamp at which the price was recorded.
   * Emits a {PriceChangeTooLarge}, {TimeStampInFuture}, {TimeStampTooOld}, or {StaleOraclePrice} error if the conditions are not met.
   */
  function addPriceOps(
    uint256 price,
    uint256 timestamp
  ) external onlyRole(ADD_PRICE_OPS_ROLE) {
    (uint256 latestOraclePrice, uint256 latestPriceTimestamp) = rwaOracle
      .getPriceData();

    if (
      _getPriceChangeBps(int256(price), int256(latestOraclePrice)) >
      OPS_MAX_CHANGE_DIFF_BPS
    ) {
      revert PriceChangeTooLarge();
    }

    if (timestamp > block.timestamp) {
      revert TimeStampInFuture(); // timestamp is in the future
    }

    if (timestamp < block.timestamp - maxTimestampDiff) {
      revert TimeStampTooOld(); // timestamp is more than maxTimestampDiff in the past
    }

    if (latestPriceTimestamp < block.timestamp - maxTimestampDiff) {
      revert StaleOraclePrice(); // latest oracle price is more than maxTimestampDiff in the past
    }

    _addPrice(price, timestamp);
  }

  /**
   * @dev Deletes a price from the contract.
   * @param priceId The ID of the price to be deleted.
   * Emits a {PriceDeleted} event.
   * Requirements:
   * - The caller must have the `DEFAULT_ADMIN_ROLE`.
   * - The price ID must exist.
   */
  function deletePrice(uint256 priceId) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (prices[priceId].price == 0) {
      revert PriceIdDoesNotExist();
    }

    PriceInfo memory oldPriceInfo = prices[priceId];
    delete prices[priceId];
    // we dont delete the priceId from the array since it would be too expensive to shift the entire array

    emit PriceDeleted(priceId, oldPriceInfo.price, oldPriceInfo.timestamp);
  }

  /**
   * @notice Set the maximum timestamp difference allowed for adding a price
   *
   * @param diff The maximum timestamp difference allowed
   */
  function setMaxTimestampDiff(
    uint256 diff
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 oldMaxTimestampDiff = maxTimestampDiff;
    maxTimestampDiff = diff;
    emit MaxTimestampDiffSet(oldMaxTimestampDiff, diff);
  }

  /**
   * @notice Compute the price change in basis points
   *
   * @param previousPrice Previous price
   * @param newPrice      New price
   *
   * @dev The price change can be negative.
   */
  function _getPriceChangeBps(
    int256 previousPrice,
    int256 newPrice
  ) public pure returns (uint256) {
    int256 change = newPrice - previousPrice;
    int changeBps = (change * BPS_DENOMINATOR) / previousPrice;
    return _abs_unsigned(changeBps);
  }

  /**
   * @notice returns the absolute value of the input.
   *
   * @param x the number to return absolute value of.
   */
  function _abs_unsigned(int256 x) private pure returns (uint256) {
    return x >= 0 ? uint256(x) : uint256(-x);
  }

  event PriceDeleted(uint256 indexed priceId, uint256 price, uint256 timestamp);

  event MaxTimestampDiffSet(uint256 olfdDiff, uint256 newDiff);

  // Errors
  error TimeStampTooOld();
  error TimeStampInFuture();
  error PriceChangeTooLarge();
  error StaleOraclePrice();
}
