//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC20PausableUpgradeable.sol";
import "./Ownable.sol";
import "./AdminsControllerUpgradeable.sol";
import "./IAdmins.sol";

contract Faction is ERC20PausableUpgradeable, AdminsControllerUpgradeable {    
    function initialize(string memory _name, string memory _symbol, IAdmins admin_) public initializer {
        __ERC20Pausable_init();
        __ERC20_init(_name, _symbol);
        __AdminController_init(admin_);
    }

    function mint(address account, uint256 amount) external onlyAdmins {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyAdmins {
        _burn(account, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20PausableUpgradeable) onlyAdmins {
        super._beforeTokenTransfer(from, to, amount);
    }

    function pause() external onlyAdmins {
        _pause();
    }

    function unpause() external onlyAdmins {
        _unpause();
    }
}