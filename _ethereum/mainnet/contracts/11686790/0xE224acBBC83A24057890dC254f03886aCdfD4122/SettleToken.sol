// contracts/CJCMToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";

contract SettleToken is ERC20 {

    constructor() public ERC20("SettleToken", "SETTLE") {
        _mint(msg.sender, 10000000 ether);
    }

    function burn(uint256 amount) public {
		_burn(msg.sender, amount);
    }
}
