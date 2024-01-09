// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract Token is ERC20Upgradeable, AccessControlUpgradeable {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) public virtual initializer {
        __AccessControl_init();
        __ERC20_init(_name, _symbol);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(_msgSender(), _initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    uint256[50] private __gap;
}
