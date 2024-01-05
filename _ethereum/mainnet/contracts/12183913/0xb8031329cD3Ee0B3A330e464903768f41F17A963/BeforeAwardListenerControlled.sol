// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import "./BeforeAwardListenerControlledInterface.sol";
import "./Constants.sol";
import "./BeforeAwardListenerControlledLibrary.sol";

abstract contract BeforeAwardListenerControlled is BeforeAwardListenerControlledInterface {
  function supportsInterface(bytes4 interfaceId) external override view returns (bool) {
    return (
      interfaceId == Constants.ERC165_INTERFACE_ID_ERC165 || 
      interfaceId == BeforeAwardListenerControlledLibrary.ERC165_INTERFACE_ID_BEFORE_AWARD_LISTENER
    );
  }
}