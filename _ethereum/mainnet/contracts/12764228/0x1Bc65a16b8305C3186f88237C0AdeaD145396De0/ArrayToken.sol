// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.2;

import "./Context.sol";
import "./AccessControl.sol";
import "./ERC20.sol";

contract ArrayToken is Context, AccessControl, ERC20 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    address public curve = 0xa0bc1aEF5A4645a774Bd38F4733c6c4B4A4B0D0A;

    constructor(string memory name, string memory symbol)
    ERC20(name, symbol)

    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, curve);
        _setupRole(BURNER_ROLE, curve);
    }

    function mint(address to, uint256 amount)
    external
    virtual
    onlyRole(MINTER_ROLE)
    {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount)
    external
    virtual
    onlyRole(BURNER_ROLE)
    {
        _burn(from, amount);
    }

}
