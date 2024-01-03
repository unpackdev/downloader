pragma solidity ^0.6.12;

import "./ERC721.sol";

contract ERC721Mintable is ERC721UpgradeSafe {

  function mint(
    address account,
    uint256 id
  ) external {
    _mint(account, id);
  }

}