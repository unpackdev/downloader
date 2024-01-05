//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./ERC20PresetFixedSupply.sol";

contract SwarmMarketsToken is ERC20PresetFixedSupply {
    /**
     * See {ERC20PresetFixedSupply-constructor}.
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(address owner) ERC20PresetFixedSupply("Swarm Markets", "SMT", 250000000 * 10**18, owner) {}
}
