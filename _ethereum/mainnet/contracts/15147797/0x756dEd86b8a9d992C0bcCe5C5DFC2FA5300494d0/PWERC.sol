// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract PWERC is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("PWER Credits", "PWERC") {
        _mint(
            0x4B68032C47fdA577c7094F0fA81A1542c9E2967E,
            2000000 * 10**decimals()
        );

        _transferOwnership(0x4B68032C47fdA577c7094F0fA81A1542c9E2967E);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
