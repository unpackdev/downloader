// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20Upgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./Initializable.sol";

/// @custom:security-contact info@cryptopila.com
contract CryptoPila is Initializable, ERC20Upgradeable, ERC20PausableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("CryptoPila", "PILA");
        __ERC20Pausable_init();
        __Ownable_init(address(0x3942f767C20Ae590A18D23871794950e2d127600));
        __ERC20Permit_init("CryptoPila");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Overrides the default(18) of OpenZepelin to 6.
    function decimals() public view override virtual returns (uint8) {
        return 6;
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256 value)
        internal override (ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._update(from, to, value);
    }
}
