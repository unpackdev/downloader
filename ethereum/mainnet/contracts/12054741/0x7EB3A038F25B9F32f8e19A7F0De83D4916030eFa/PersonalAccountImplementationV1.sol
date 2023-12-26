// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./AccountImplementationV1.sol";


/**
 * @title Personal account implementation (version 1)
 *
 * @author Stanisław Głogowski <stan@pillarproject.io>
 */
contract PersonalAccountImplementationV1 is AccountImplementationV1 {

  /**
   * @dev Public constructor
   */
  constructor() public AccountImplementationV1() {}
}
