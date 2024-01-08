// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "./Initializable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ContextUpgradeable.sol";

import "./IChocoFactory.sol";

import "./Revocable.sol";
import "./TxValidatable.sol";

abstract contract ChocoFactoryBase is
  Initializable,
  ERC165Upgradeable,
  ContextUpgradeable,
  EIP712Upgradeable,
  Revocable,
  TxValidatable
{
  function initialize(string memory name, string memory version) public initializer {
    __EIP712_init_unchained(name, version);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IChocoFactory).interfaceId || super.supportsInterface(interfaceId);
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}
