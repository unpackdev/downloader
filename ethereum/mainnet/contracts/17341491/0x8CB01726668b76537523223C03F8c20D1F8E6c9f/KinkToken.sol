// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/// @custom:security-contact info@kinkbnb.com
contract KinkToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("KinkToken", "KINK") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
