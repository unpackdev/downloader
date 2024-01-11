// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IManifestNFTManager {
  event VaultSet(address indexed prevVault, address indexed newVault);
  event DropWhitelisted(address indexed drop, uint256[] ids);
  event DropBlacklisted(address indexed drop);
  event Burned(address indexed user, address drop, uint256 id, uint256 amount, address vault);

  struct Drop {
    address drop;
    uint256[] ids;
  }

  struct UserDrop {
    address drop;
    uint256[] ids;
    uint256[] amounts;
    string[] uris;
  }

  struct Burn {
    address drop;
    uint256 id;
    uint256 amount;
  }

  function setVault(address _vault) external;
  function togglePause() external;
  function whitelistDrop(address _drop, uint256[] calldata _ids) external;
  function blacklistDrop(uint256 _idx) external;

  function burn(address _drop, uint256 _id, uint256 _amount) external;

  function getUserDrops(address _user) external view returns (UserDrop[] memory);
  function checkDrop(address _drop, uint256 _id) external view returns (bool);
  function checkBurn(address _user, address _drop, uint256 _id) external view returns (uint256);
}