// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
import "./ERC20.sol";

/**
 * @notice implementation of the DEFED token contract
 * @author DEFED
 */
contract DefeToken is ERC20 {
    string internal constant NAME = "DEFE Token";
    string internal constant SYMBOL = "DEFE";

    uint256 internal constant TOTAL_SUPPLY = 1e28;

    constructor(address misc) public ERC20(NAME, SYMBOL) {
        _mint(misc, TOTAL_SUPPLY);
    }
}
