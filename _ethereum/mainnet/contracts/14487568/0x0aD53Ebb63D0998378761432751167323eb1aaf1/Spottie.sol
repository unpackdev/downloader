// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;
pragma abicoder v2;

import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";

contract Spottie is ERC721PresetMinterPauserAutoIdUpgradeable {
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
      "https://spottie.mypinata.cloud/ipfs/QmYNB7BKQFqeFzpa5rGJnMA5foTh6U84f7QHdk7go6GLuS/"; // TODO
  }
}
