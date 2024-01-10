//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./AdminManager.sol";

contract Raks is
    Initializable,
    ERC20Upgradeable,
    AdminManagerUpgradable,
    PausableUpgradeable
{
    function initialize() public initializer {
        __ERC20_init("RAKS", "$RAKS");
        __AdminManager_init();
    }

    function mint(address account, uint256 amount)
        external
        whenNotPaused
        onlyAdmin
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        external
        whenNotPaused
        onlyAdmin
    {
        _burn(account, amount);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
}
