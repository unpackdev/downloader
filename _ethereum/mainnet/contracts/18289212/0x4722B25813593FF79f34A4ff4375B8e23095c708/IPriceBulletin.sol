// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title IPriceBulletin
 *
 * @notice Defines the common interfaces for PriceBulletin
 */

import "./IAggregatorV3.sol";
import "./IConnext.sol";

interface IPriceBulletin is IAggregatorV3, IXReceiver {
  /**
   * @notice Sets the authorized publisher of a `RoundData` as valid or not.
   *
   * @param publisher address
   * @param set true if allowed, false if not
   *
   * @dev Requirements:
   * - Must be restricted to an admin or owner role
   * - Must check a change is happening in state for the `set` argument
   */
  function setAuthorizedPublisher(address publisher, bool set) external;
}
