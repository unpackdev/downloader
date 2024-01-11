// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract BadgeDagenItems is
  ERC1155,
  Ownable,
  AccessControl,
  Pausable,
  ERC1155Burnable,
  ERC1155Supply
{
  using SafeMath for uint256;
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  string public name = "BadgeGen";
  mapping(uint256 => uint256) public preset;

  constructor() ERC1155("https://dagen.io/badge/{id}.json") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  function setupPreset(uint256[] calldata ids, uint256[] calldata amounts)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    for (uint256 i = 0; i < ids.length; i++) {
      preset[ids[i]] = amounts[i];
    }
  }

  function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setURI(newuri);
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public onlyRole(MINTER_ROLE) {
    require(totalSupply(id) + amount <= preset[id], "exceed preset");
    _mint(account, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyRole(MINTER_ROLE) {
    for (uint256 i = 0; i < ids.length; i++) {
      require(totalSupply(ids[i]) + amounts[i] <= preset[ids[i]], "exceed preset");
    }
    _mintBatch(to, ids, amounts, data);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  // The following functions are overrides required by Solidity.
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
