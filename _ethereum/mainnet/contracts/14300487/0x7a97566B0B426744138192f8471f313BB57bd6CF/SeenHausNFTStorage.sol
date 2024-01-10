// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";

/**
 * @title SeenHausNFTStorage
 * @notice Splits storage away from the logic in SeenHausNFT.sol for maintainability
 */
contract SeenHausNFTStorage is SeenTypes {

  address internal _owner;

  /// @dev token id => Token struct
  mapping (uint256 => Token) internal tokens;

  // Next token number
  uint256 internal nextToken;

}