// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.14;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";

contract WagmiToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("WAGMI", "WGMI") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function grantMinter(address to) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        _grantRole(MINTER_ROLE, to);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}