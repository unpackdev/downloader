// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";

contract SeedClubToken is ERC20, Ownable {
    constructor() ERC20("Seed Club Token", "$CLUB") {
        _mint(msg.sender, 10000000 * 10**decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
