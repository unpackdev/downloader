//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20PresetFixedSupply.sol";

contract SinanEnergyToken is ERC20PresetFixedSupply {
    constructor()
        ERC20PresetFixedSupply(
            "SinanEnergyToken",
            "SET",
            100_000_000 * 10**18,
            0x1FF26692bfBD1E34ef6C630eE8569B7dd6E3091E
        )
    {}
}
