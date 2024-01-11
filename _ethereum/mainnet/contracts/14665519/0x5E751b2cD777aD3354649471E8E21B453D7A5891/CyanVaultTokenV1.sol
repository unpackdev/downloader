// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./AccessControl.sol";
import "./ERC20.sol";

contract CyanVaultTokenV1 is AccessControl, ERC20 {
    bytes32 public constant CYAN_VAULT_ROLE = keccak256('CYAN_VAULT_ROLE');

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address cyanSuperAdmin
    ) ERC20(name, symbol) {
        _mint(cyanSuperAdmin, initialSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, cyanSuperAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount)
        external
        onlyRole(CYAN_VAULT_ROLE)
    {
        require(to != address(0), 'Mint to the zero address');
        _mint(to, amount);
    }

    function burn(address from, uint256 amount)
        external
        onlyRole(CYAN_VAULT_ROLE)
    {
        require(balanceOf(from) >= amount, 'Balance not enough');
        _burn(from, amount);
    }

    function burnAdminToken(uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(balanceOf(msg.sender) >= amount, 'Balance not enough');
        _burn(msg.sender, amount);
    }
}
