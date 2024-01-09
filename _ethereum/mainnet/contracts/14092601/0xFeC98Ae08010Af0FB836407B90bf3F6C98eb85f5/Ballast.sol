// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.11;

import "./draft-ERC20PermitUpgradeable.sol";
import "./OwnableUpgradeable.sol";

///	@title	Ballast  token contract
contract Ballast is OwnableUpgradeable, ERC20PermitUpgradeable {

    function initialize() initializer public {
        __ERC20_init("Ballast", "BLST");
        __Ownable_init();
        __ERC20Permit_init("Ballast");

        _mint(msg.sender, 6_260_870e18);
    }
}