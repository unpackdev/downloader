// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMathUint.sol";

/**
 * @dev Distributes ERC20 token in batches.
 */
contract SimpleDistribution is Context, Ownable {
  using SafeMathUint for uint256;

  IERC20 _token;
  
  /**
   * @dev Sets the ERC20 'token' which will be distributed through the {SimpleDistribution}.
   */
  constructor(IERC20 token) {
    _token = token;
  }

  /**
   * @dev Sends 'values' tokens to each of 'to' accounts.
   */
  function distribute(address[] calldata to, uint256 value)
    external onlyOwner
  {
    uint256 i = 0;
    while (i < to.length) {
      _token.transfer(to[i], value);
      i++;
    }
  }
}
