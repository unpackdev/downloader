// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract GhostMarketToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable {
    uint8 private _decimals;

    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 __decimals
    ) public virtual initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init(name, symbol);
        _mint(_msgSender(), initialSupply);
        _decimals = __decimals;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
