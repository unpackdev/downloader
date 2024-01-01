// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract METRIA is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    uint256 public constant multiplier = (10 ** 18);

    function initialize(address adminAddress) public initializer {
        __ERC20_init("METRIA", "METR");
        __ERC20Burnable_init();
        __Ownable_init();
        __ERC20Permit_init("METRIA");
        __UUPSUpgradeable_init();
        _mint(adminAddress, 100000 * multiplier);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}
