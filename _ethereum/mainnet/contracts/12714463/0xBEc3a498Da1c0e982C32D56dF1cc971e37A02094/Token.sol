// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

import "./ERC777.sol";


contract Token is ERC777 {
    constructor(address _owner) ERC777("Virusscoin", "VCN", new address[](0))
    {
        _mint(_owner, 100_000_000 * 10 ** 18, "", "");
    }
}
