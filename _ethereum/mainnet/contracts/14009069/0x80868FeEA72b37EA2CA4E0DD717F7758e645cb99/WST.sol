// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Capped.sol";
import "./InternalWhitelistControl.sol";


// temp: set cap to 1 billion ether
contract WST is ERC20Capped(1e9 ether), InternalWhitelistControl {

    constructor() ERC20("WallStreetToken", "WST") {}

    function mint(address account, uint256 amount)
    external
    internalWhitelisted(msg.sender) {
        _mint(account, amount);
    }

    function burnFrom(address account, uint256 amount) 
    external 
    internalWhitelisted(msg.sender) {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
    }

}