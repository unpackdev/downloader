pragma solidity ^0.8.0;

import "./ERC20.sol";


contract Feng is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialBalance_
    ) ERC20(name_, symbol_) {
        require(initialBalance_ > 0, "Feng: supply cannot be zero");

        _mint(_msgSender(), initialBalance_*10**decimals_);
    }
}