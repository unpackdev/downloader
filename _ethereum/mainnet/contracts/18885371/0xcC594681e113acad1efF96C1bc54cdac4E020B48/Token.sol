// contracts/Token.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "ERC20.sol";
import "Ownable.sol";
import "VestingWallet.sol";

contract Token is VestingWallet {
    constructor(uint256 initialSupply) VestingWallet("Meteor", "MTO") {
        _mint(msg.sender, initialSupply);
        initiateVesting();
    }
}
