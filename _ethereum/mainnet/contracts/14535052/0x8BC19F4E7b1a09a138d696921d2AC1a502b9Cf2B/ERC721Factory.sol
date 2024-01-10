// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./AccessControl.sol";
import "./Clones.sol";
import "./MogulERC721.sol";
import "./FactoryInterfaces.sol";

// ERC721 Factory
contract ERC721Factory is AccessControl, IERC721Factory {
  address tokenImplementation;
  bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

  event ERC721Created(address contractAddress, address owner);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(CREATOR_ROLE, msg.sender);

    tokenImplementation = address(new MogulERC721());
  }

  function setTokenImplementation(address _tokenImplementation)
    public
    onlyRole(CREATOR_ROLE)
  {
    tokenImplementation = _tokenImplementation;
  }

  function createERC721(address owner)
    external
    override
    onlyRole(CREATOR_ROLE)
  {
    address clone = Clones.clone(tokenImplementation);
    IInitializableERC721(clone).init(owner);
    emit ERC721Created(clone, owner);
  }
}
