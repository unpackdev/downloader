// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Dux is ERC20, Ownable {
    constructor() ERC20("DUX", "DUX") {
        _mint(
            0xCf9908BEF579833E9DeD3306C42f33DB50B22997,
            1000000000 * 10**decimals()
        );
        _transferOwnership(0xCf9908BEF579833E9DeD3306C42f33DB50B22997);
    }
}
