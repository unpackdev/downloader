// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./GovernanceToken.sol";

contract Delegator is Ownable {
  /// @notice Governance token.
  GovernanceToken public token;

  /**
   * @param _token Governance token.
   * @param governor Governor.
   */
  constructor(address _token, address governor) {
    require(governor != address(0), "Delegator::constructor: cannot delegate to the zero address");
    token = GovernanceToken(_token);
    token.delegate(governor);
  }

  /**
   * @notice Unlock tokens and transfer to recipient.
   * @param recipient Recipient address.
   * @param amount Amount token.
   */
  function unlock(address recipient, uint256 amount) external onlyOwner {
    require(recipient != address(0), "Delegator::unlock: cannot transfer to the zero address");
    token.transfer(recipient, amount);
  }
}
