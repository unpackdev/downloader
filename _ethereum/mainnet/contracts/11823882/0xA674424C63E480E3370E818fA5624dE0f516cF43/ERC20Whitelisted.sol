// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./Initializable.sol";
import "./Ownable.sol";
import "./ERC20.sol";

import "./WhitelistVault.sol";

abstract contract ERC20Whitelisted is Initializable, ERC20UpgradeSafe, OwnableUpgradeSafe {
  WhitelistVault internal _vault;
  bool internal _vaultLoaded = false;

  event BlockedByWhitelist(address _address);
  event UpdatedVault(address _address);

  function __ERC20Whitelisted_init() internal initializer {
    __Context_init_unchained();
    __Ownable_init();
  }

  function updateVault(address vaultAddress) public onlyOwner {
    _vault = WhitelistVault(vaultAddress);
    emit UpdatedVault(vaultAddress);
    _vaultLoaded = true;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    require(_vaultLoaded, "WhitelistVault NOT linked" );
    if (from != address(0)) { // When minting tokens
      _checkWhitelisted(from);
    }
    _checkWhitelisted(to);
  }

  function _checkWhitelisted(address _address) internal {
    if (_address != owner() && !_vault.isWhitelisted(_address)) {
      emit BlockedByWhitelist(_address);
      revert("Address NOT whitelisted");
    }
  }

  uint256[50] private __gap;
}
