// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./IdentifierWhitelistInterface.sol";
import "./Ownable.sol";

contract IdentifierWhitelist is IdentifierWhitelistInterface, Ownable {
  mapping(bytes32 => bool) private supportedIdentifiers;

  event SupportedIdentifierAdded(bytes32 indexed identifier);
  event SupportedIdentifierRemoved(bytes32 indexed identifier);

  function addSupportedIdentifier(bytes32 identifier)
    external
    override
    onlyOwner
  {
    if (!supportedIdentifiers[identifier]) {
      supportedIdentifiers[identifier] = true;
      emit SupportedIdentifierAdded(identifier);
    }
  }

  function removeSupportedIdentifier(bytes32 identifier)
    external
    override
    onlyOwner
  {
    if (supportedIdentifiers[identifier]) {
      supportedIdentifiers[identifier] = false;
      emit SupportedIdentifierRemoved(identifier);
    }
  }

  function isIdentifierSupported(bytes32 identifier)
    external
    view
    override
    returns (bool)
  {
    return supportedIdentifiers[identifier];
  }
}
