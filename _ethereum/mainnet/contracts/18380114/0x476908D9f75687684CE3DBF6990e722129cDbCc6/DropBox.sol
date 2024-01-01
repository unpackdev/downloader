// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Owned.sol";
import "./IBitcoin.sol";

contract DropBox is Owned {
    constructor(address owner_) Owned(owner_) {}

    function collect(uint256 value, IBitcoin underlying) public onlyOwner {
        underlying.transfer(owner, value);
    }
}
