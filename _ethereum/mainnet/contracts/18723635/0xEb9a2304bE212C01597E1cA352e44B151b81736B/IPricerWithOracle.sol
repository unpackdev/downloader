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

import "./IPricer.sol";

interface IPricerWithOracle is IPricer {
  /**
   * @dev Deletes a price from the contract.
   * @param priceId The ID of the price to be deleted.
   * Emits a {PriceDeleted} event.
   * Requirements:
   * - The caller must have the `DEFAULT_ADMIN_ROLE`.
   * - The price ID must exist.
   */
  function deletePrice(uint256 priceId) external;

  /**
   * @dev Checks if the given priceIds are valid by verifying that their corresponding prices were updated
   * within the last `maxTimestampDiff` seconds.
   * @param priceIds An array of priceIds to check validity for.
   * @return A boolean indicating whether all the given priceIds are valid or not.
   */
  function isValid(uint256[] calldata priceIds) external view returns (bool);

  /**
   * @dev Adds a new price and timestamp to the price history, subject to certain conditions.
   * Only callable by an account with the `ADD_PRICE_OPS_ROLE` role.
   * @param price The new price to add.
   * @param timestamp The timestamp at which the price was recorded.
   * Emits a {PriceChangeTooLarge}, {TimeStampInFuture}, {TimeStampTooOld}, or {StaleOraclePrice} error if the conditions are not met.
   */
  function addPriceOps(uint256 price, uint256 timestamp) external;
}
