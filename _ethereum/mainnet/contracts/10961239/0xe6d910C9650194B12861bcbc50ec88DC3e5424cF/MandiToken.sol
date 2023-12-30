// SPDX-License-Identifier: MIT

pragma solidity =0.6.11;

import "./ERC20.sol";

contract MandiToken is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 10000000000 *
        (10**18); // Ten billion tokens with standard 18 decimals of precision

    constructor(address[] memory holders, uint256[] memory balances) public ERC20("Mandi", "Mandi") {
        require(holders.length == balances.length, "MandiToken: Constructor array size mismatch");
        for (uint256 i = 0; i < holders.length; i++) {
            _mint(holders[i], balances[i]);
        }
        require(totalSupply() == TOTAL_SUPPLY, "MandiToken: Initial supply does not match expected");
    }
}
