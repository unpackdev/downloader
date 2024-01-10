// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;
pragma abicoder v2;

import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";

import "./ERC2981.sol";

contract Spottie is ERC721PresetMinterPauserAutoIdUpgradeable, ERC2981 {
  function initialize(
    string memory name_,
    string memory symbol_,
    string memory baseTokenURI_
  ) public override initializer {
    super.initialize(name_, symbol_, baseTokenURI_);

    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
  }

  function _baseURI() internal pure override returns (string memory) {
    return
      "https://spottie.mypinata.cloud/ipfs/QmYNB7BKQFqeFzpa5rGJnMA5foTh6U84f7QHdk7go6GLuS/";
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721PresetMinterPauserAutoIdUpgradeable, ERC2981Base)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function setRoyalties(address recipient, uint256 value)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setRoyalties(recipient, value);
  }

  function owner() external view returns (address) {
    return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
  }
}
