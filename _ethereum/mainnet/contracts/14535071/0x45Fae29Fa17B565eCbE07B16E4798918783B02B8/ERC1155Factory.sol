// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./AccessControl.sol";
import "./Clones.sol";
import "./MogulERC1155.sol";
import "./FactoryInterfaces.sol";

// ERC1155 Factory
contract ERC1155Factory is AccessControl, IERC1155Factory {
  address tokenImplementation;
  bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

  event ERC1155Created(address contractAddress, address owner);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(CREATOR_ROLE, msg.sender);

    tokenImplementation = address(new MogulERC1155());
  }

  function setTokenImplementation(address _tokenImplementation)
    public
    onlyRole(CREATOR_ROLE)
  {
    tokenImplementation = _tokenImplementation;
  }

  function createERC1155(address owner)
    external
    override
    onlyRole(CREATOR_ROLE)
  {
    address clone = Clones.clone(tokenImplementation);
    IInitializableERC1155(clone).init(owner);
    emit ERC1155Created(clone, owner);
  }
}
