// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";

contract WrappedEquivalenceTokenV2 is ERC20 {
    constructor() ERC20("Wrapped Equivalence Token V2", "WEQT") {_mint(msg.sender, 10 ** 30);}
}