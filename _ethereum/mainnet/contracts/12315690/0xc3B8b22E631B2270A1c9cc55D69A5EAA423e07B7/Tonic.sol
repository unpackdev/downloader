// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "./ERC20PresetFixedSupply.sol";

/**
 * @title Tonic token contract
 * @author Tonic Finance
 */
contract Tonic is ERC20PresetFixedSupply {
    constructor()
        ERC20PresetFixedSupply("Tonic Finance Governance", "TON", 1337, 0x4C989615E49c77104cb26639800db42c3362B0D0)
    {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
