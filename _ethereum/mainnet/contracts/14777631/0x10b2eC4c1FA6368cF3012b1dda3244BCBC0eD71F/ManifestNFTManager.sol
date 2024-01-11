// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155MetadataURI.sol";

import "./IManifestNFTManager.sol";

contract ManifestNFTManager is IManifestNFTManager, AccessControlEnumerable, Pausable, ReentrancyGuard {
  bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");
  bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

  address public vault;
  Drop[] public drops;
  mapping(address => Burn[]) public burns;

  constructor(address _vault) {
    require(_vault != address(0), "ManifestNFTManager: vault address must not be 0");

    vault = _vault;

    _grantRole(DEFAULT_ADMIN_ROLE, _vault);
    _grantRole(TEAM_ROLE, _vault);
    _grantRole(VAULT_ROLE, _vault);
  }

  function setVault(address _vault) external override onlyRole(VAULT_ROLE) {
    require(_vault != address(0), "ManifestNFTManager: vault address must not be 0");

    address oldVault = vault;
    vault = _vault;

    _grantRole(DEFAULT_ADMIN_ROLE, _vault);
    _grantRole(TEAM_ROLE, _vault);
    _grantRole(VAULT_ROLE, _vault);
    _revokeRole(DEFAULT_ADMIN_ROLE, oldVault);
    _revokeRole(TEAM_ROLE, oldVault);
    _revokeRole(VAULT_ROLE, oldVault);

    emit VaultSet(oldVault, _vault);
  }

  function togglePause() external override onlyRole(TEAM_ROLE) {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function whitelistDrop(address _drop, uint256[] calldata _ids) external override onlyRole(TEAM_ROLE) {
    require(_drop != address(0), "ManifestNFTManager: drop address must not be 0");

    drops.push(Drop(_drop, _ids));

    emit DropWhitelisted(_drop, _ids);
  }

  function blacklistDrop(uint256 _idx) external override onlyRole(TEAM_ROLE) {
    require(_idx < drops.length, "ManifestNFTManager: index must be less than size of drops array");

    Drop memory drop = drops[_idx];

    drops[_idx] = drops[drops.length - 1];
    drops.pop();

    emit DropBlacklisted(drop.drop);
  }

  function burn(address _drop, uint256 _id, uint256 _amount) external override whenNotPaused nonReentrant {
    require(checkDrop(_drop, _id), "ManifestNFTManager: drop and/or ID not found");
    require(_amount > 0, "ManifestNFTManager: amount must be greater than 0");

    IERC1155MetadataURI dropNFT = IERC1155MetadataURI(_drop);
    dropNFT.safeTransferFrom(msg.sender, vault, _id, _amount, "");

    burns[msg.sender].push(Burn(_drop, _id, _amount));
    emit Burned(msg.sender, _drop, _id, _amount, vault);
  }

  function getUserDrops(address _user) public view override returns (UserDrop[] memory) {
    require(_user != address(0), "ManifestNFTManager: user address must not be 0");

    UserDrop[] memory userDrops = new UserDrop[](drops.length);

    for (uint256 i = 0; i < drops.length; i++) {
      userDrops[i].drop = drops[i].drop;
      userDrops[i].ids = drops[i].ids;
      userDrops[i].uris = new string[](drops[i].ids.length);

      address[] memory accounts = new address[](drops[i].ids.length);
      for (uint256 j = 0; j < accounts.length; j++) {
        accounts[j] = _user;
      }

      IERC1155MetadataURI dropNFT = IERC1155MetadataURI(drops[i].drop);
      userDrops[i].amounts = dropNFT.balanceOfBatch(accounts, drops[i].ids);

      for (uint256 j = 0; j < drops[i].ids.length; j++) {
        userDrops[i].uris[j] = dropNFT.uri(drops[i].ids[j]);
      }
    }

    return userDrops;
  }

  function checkDrop(address _drop, uint256 _id) public override view returns (bool) {
    require(_drop != address(0), "ManifestNFTManager: drop address must not be 0");

    for (uint256 i = 0; i < drops.length; i++) {
      if (drops[i].drop != _drop) {
        continue;
      }

      for (uint256 j = 0; j < drops[i].ids.length; j++) {
        if (drops[i].ids[j] == _id) {
          return true;
        }
      }
    }

    return false;
  }

  function checkBurn(address _user, address _drop, uint256 _id) public override view returns (uint256) {
    require(_user != address(0), "ManifestNFTManager: user address must not be 0");
    require(_drop != address(0), "ManifestNFTManager: drop address must not be 0");

    Burn[] memory userBurns = burns[_user];
    if (userBurns.length == 0) {
      return 0;
    }

    for (uint256 i = 0; i < userBurns.length; i++) {
      if (userBurns[i].drop == _drop && userBurns[i].id == _id) {
        return userBurns[i].amount;
      }
    }

    return 0;
  }
}