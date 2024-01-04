// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./MultiRole.sol";
import "./ExpandedIERC20.sol";

contract ExpandedERC20 is ExpandedIERC20, ERC20, MultiRole {
  enum Roles {Owner, Minter, Burner}

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint8 _tokenDecimals
  ) public ERC20(_tokenName, _tokenSymbol) {
    _setupDecimals(_tokenDecimals);
    _createExclusiveRole(
      uint256(Roles.Owner),
      uint256(Roles.Owner),
      msg.sender
    );
    _createSharedRole(
      uint256(Roles.Minter),
      uint256(Roles.Owner),
      new address[](0)
    );
    _createSharedRole(
      uint256(Roles.Burner),
      uint256(Roles.Owner),
      new address[](0)
    );
  }

  function mint(address recipient, uint256 value)
    external
    override
    onlyRoleHolder(uint256(Roles.Minter))
    returns (bool)
  {
    _mint(recipient, value);
    return true;
  }

  function burn(uint256 value)
    external
    override
    onlyRoleHolder(uint256(Roles.Burner))
  {
    _burn(msg.sender, value);
  }

  function addMinter(address account) external virtual override {
    addMember(uint256(Roles.Minter), account);
  }

  function addBurner(address account) external virtual override {
    addMember(uint256(Roles.Burner), account);
  }

  function resetOwner(address account) external virtual override {
    resetMember(uint256(Roles.Owner), account);
  }
}
