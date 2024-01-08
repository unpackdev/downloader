// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";

import "./IBasicController.sol";
import "./IRegistrar.sol";

contract BasicController is
  IBasicController,
  ContextUpgradeable,
  ERC165Upgradeable,
  ERC721HolderUpgradeable
{
  IRegistrar private registrar;

  modifier authorized(uint256 domain) {
    require(
      registrar.ownerOf(domain) == _msgSender(),
      "Zer0 Controller: Not Authorized"
    );
    _;
  }

  function initialize(IRegistrar _registrar) public initializer {
    __ERC165_init();
    __Context_init();
    __ERC721Holder_init();

    registrar = _registrar;
  }

  function registerSubdomainExtended(
    uint256 parentId,
    string memory label,
    address owner,
    string memory metadata,
    uint256 royaltyAmount,
    bool lockOnCreation
  ) external override authorized(parentId) returns (uint256) {
    address minter = _msgSender();

    uint256 id = registrar.registerDomain(
      parentId,
      label,
      minter,
      metadata,
      royaltyAmount,
      lockOnCreation
    );

    emit RegisteredDomain(label, id, parentId, owner, minter);

    return id;
  }
}
