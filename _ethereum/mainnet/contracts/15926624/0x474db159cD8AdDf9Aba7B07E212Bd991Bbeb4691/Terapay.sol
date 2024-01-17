// contracts/TPAY.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract TPAY is Context, Ownable, ERC20 {
    uint8 private immutable DECIMALS;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address mintTo_,
        uint256 supply_
    ) ERC20(name_, symbol_) {
        require(bytes(name_).length > 0, "TPAY: name is required");
        require(bytes(symbol_).length > 0, "TPAY: symbol is required");

        require(decimals_ > 0, "TPAY: decimals is required");
        DECIMALS = decimals_;

        require(mintTo_ != address(0), "TPAY: mintTo is required");
        require(supply_ > 0, "TPAY: supply is required");
        _mint(mintTo_, supply_);
    }

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }
}