// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC20.sol";

contract BULL is ERC20 {
    address public mintedAt;

    constructor(address minter) ERC20("BullionFxV2", "$BULL") {
        mintedAt = minter;
        _mint(minter, 2599888888 * 10**decimals());
    }
}
    