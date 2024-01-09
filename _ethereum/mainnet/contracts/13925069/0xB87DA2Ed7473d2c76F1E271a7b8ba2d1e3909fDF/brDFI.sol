// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20Upgradeable.sol";

contract brDFI is ERC20Upgradeable {
    address private _minter;

    function initialize_coin(address minter_gateway) public initializer {
        __ERC20_init("bridged DFI (DefiChain)", "brDFI");
        _minter = minter_gateway;
    }

    function change_minter(address minter_gateway) public initializer {
        // Only minters can upgrade
        require(_minter == msg.sender, "DOES_NOT_HAVE_MINTER_ROLE");

        _minter = minter_gateway;
    }

    function mint(address to, uint256 amount) public {
        // Only minters can mint
        require(_minter == msg.sender, "DOES_NOT_HAVE_MINTER_ROLE");

        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        // Only minters can burn
        require(_minter == msg.sender, "DOES_NOT_HAVE_BURNER_ROLE");

       _burn(from, amount);
    }
}