// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

contract Yoor is ERC20Capped, Ownable {
    constructor()
        ERC20('Yoor', 'YOOR')
        ERC20Capped(300000000 * 10**decimals())
    {
        ERC20._mint(msg.sender, 10000000 * 10**decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
