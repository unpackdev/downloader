// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.7;

import "./ERC20.sol";

contract MTDToken is ERC20 {
    constructor () ERC20("MetaDee token", "MTD") {
        // mint(msg.sender, 1000000 * (10 ** 18));
    }

    function mintToken(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
