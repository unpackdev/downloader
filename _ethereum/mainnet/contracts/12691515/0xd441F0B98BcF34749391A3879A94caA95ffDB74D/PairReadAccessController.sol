// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./WriteAccessController.sol";
import "./EOAContext.sol";

/**
 * @title PairReadAccessController
 * @notice Extends WriteAccessController. Decodes the (asset, denomination) pair values of msg.data.
 * @notice Gives access to:
 * - any externally owned account (note that offchain actors can always read
 * any contract storage regardless of onchain access control measures, so this
 * does not weaken the access control while improving usability)
 * - accounts explicitly added to an access list
 * @dev PairReadAccessController is not suitable for access controlling writes
 * since it grants any externally owned account access! See
 * WriteAccessController for that.
 */
contract PairReadAccessController is WriteAccessController, EOAContext {
  /**
   * @notice Returns the access of an address to an asset/denomination pair
   * @param account The address to query
   * @param data The calldata to query
   */
  function hasAccess(
    address account,
    bytes calldata data
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    (
      address asset,
      address denomination
    ) = abi.decode(data[4:], (address, address));
    bytes memory pairData = abi.encode(asset, denomination); // Check access to pair (TKN / ETH)
    return super.hasAccess(account, pairData) || _isEOA(account);
  }
}
