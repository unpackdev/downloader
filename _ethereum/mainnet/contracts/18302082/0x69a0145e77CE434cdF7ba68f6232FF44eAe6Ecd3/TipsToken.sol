// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GlobalCappedOFT.sol";

/**
 * @notice Use this contract only on the BASE CHAIN. It locks tokens on source, on outgoing send(), and unlocks tokens when receiving from other chains.
 */
contract TipsToken is GlobalCappedOFT {
    uint256 public constant GLOBAL_MAX_TOTAL_SUPPLY = 1_000_000_000 ether;

    constructor(
        address _lzEndpoint
    ) GlobalCappedOFT("tips.tips", "TPTP", GLOBAL_MAX_TOTAL_SUPPLY, _lzEndpoint) {
        _mint(msg.sender, GLOBAL_MAX_TOTAL_SUPPLY);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
