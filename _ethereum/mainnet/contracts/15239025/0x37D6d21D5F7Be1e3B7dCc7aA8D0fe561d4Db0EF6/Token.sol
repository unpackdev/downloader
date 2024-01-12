// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";

/// @custom:security-contact security@tenset.io
contract Token is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    constructor() ERC20('Token', 'TKN') {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _mint(msg.sender, 100_000 ether);
    }

    function bridgeBurn(address owner, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
    {
        _burn(owner, amount);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
