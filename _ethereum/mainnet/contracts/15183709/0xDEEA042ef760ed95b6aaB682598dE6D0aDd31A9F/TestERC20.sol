// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC20.sol";

contract TestERC20 is ERC20("Element ERC20 Token", "EUSD") {

    function amint(uint256 EUSD) external {
        _mint(msg.sender, EUSD * (10**18));
    }

    function amintTo(address to, uint256 EUSD) external {
        _mint(to, EUSD * (10**18));
    }
}
