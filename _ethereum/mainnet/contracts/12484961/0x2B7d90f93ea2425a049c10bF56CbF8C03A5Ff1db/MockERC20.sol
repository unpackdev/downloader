// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
import "./ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address receiver_
    ) ERC20(name_, symbol_) {
        if (decimals_ != 18) {
            _setupDecimals(decimals_);
        }
        _mint(receiver_, 210000000000000000000000000);
    }

}
