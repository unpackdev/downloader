// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ERC20.sol";
import "./AccessControl.sol";

contract vcUSDToken is ERC20, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        // Sets `DEFAULT_ADMIN_ROLE` as ``ADMIN_ROLE``'s admin role.
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setupDecimals(_decimals);
    }

    function mint(address to, uint256 amount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not an minter");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not an burner");
        _burn(from, amount);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override(ERC20) {
        ERC20._beforeTokenTransfer(_from, _to, _amount);
    }
}
