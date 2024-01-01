// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC20.sol";

// contract KdjToken is ERC20 {
//     constructor() ERC20("KDJ", "KDJ") {
//         _mint(msg.sender, 21000000 );
//     }
// }
contract ERC20FixedSupply is ERC20 {
    constructor() ERC20("KDJ", "KDJ") {
        _mint(msg.sender, 21000000 * (10**decimals()));
    }
}