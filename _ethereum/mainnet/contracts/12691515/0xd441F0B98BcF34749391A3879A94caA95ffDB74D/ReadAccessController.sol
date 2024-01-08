// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./WriteAccessController.sol";
import "./EOAContext.sol";

/**
 * @title ReadAccessController
 * @notice Gives access to:
 * - any externally owned account (note that offchain actors can always read
 * any contract storage regardless of onchain access control measures, so this
 * does not weaken the access control while improving usability)
 * - accounts explicitly added to an access list
 * @dev ReadAccessController is not suitable for access controlling writes
 * since it grants any externally owned account access! See
 * WriteAccessController for that.
 */
contract ReadAccessController is WriteAccessController, EOAContext {
  /**
   * @notice Returns the access of an address
   * @param account The address to query
   * @param data The calldata to query
   */
  function hasAccess(
    address account,
    bytes memory data
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    return super.hasAccess(account, data) || _isEOA(account);
  }
}
