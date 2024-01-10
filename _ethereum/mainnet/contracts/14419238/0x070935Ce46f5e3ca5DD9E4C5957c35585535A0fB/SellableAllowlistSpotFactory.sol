// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Clones.sol";
import "./Pausable.sol";
import "./SellableAllowlistSpot.sol";

contract SellableAllowlistSpotFactory is Ownable, Pausable {
    uint256 public vaultCount;
    mapping (uint256 => address) public vaults;
    address public immutable logic;
    address public immutable settings;

    constructor(address _settings) {
        logic = address(new SellableAllowlistSpot(_settings));
        settings = _settings;
    }

    event AllowlistSpot(uint256 vaultId, address vault, address vaultOwner);

    function makeSellableSpot(uint256 _fee) external whenNotPaused returns (uint256) {
        SellableAllowlistSpot vault = SellableAllowlistSpot(
            payable(Clones.clone(logic))
        );
        vault.initializeVault(msg.sender, _fee);

        emit AllowlistSpot(vaultCount, address(vault), msg.sender);
        
        vaults[vaultCount++] = address(vault);
        return vaultCount - 1;
    }

    function setPaused(bool _shouldPause) external onlyOwner {
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }
}