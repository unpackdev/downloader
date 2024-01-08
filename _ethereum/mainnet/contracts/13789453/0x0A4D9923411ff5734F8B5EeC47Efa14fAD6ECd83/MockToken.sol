// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeOwnable.sol";
import "./console.sol";

contract MockToken is ERC20 {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        if (decimals_ != 18) {
            _setupDecimals(decimals_);
        }
    }

    function mint (address to_, uint amount_) external {
        _mint(to_, amount_);
    }
}
