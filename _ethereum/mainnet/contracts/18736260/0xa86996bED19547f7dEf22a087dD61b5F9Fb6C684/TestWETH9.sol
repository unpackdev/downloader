// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./IWETH9.sol";
import "./ERC20.sol";
import "./ProxyAdmin.sol";

contract TestWETH9 is ERC20, IWETH9 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function deposit() external payable override {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external override {
        _burn(msg.sender, _amount);
        payable(address(msg.sender)).transfer(_amount);
    }
}
