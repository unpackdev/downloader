// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/// @custom:security-contact oops@anxtrom.com
contract Anx is ERC20, ERC20Burnable, Ownable {
    //
    constructor() ERC20("Anx", "@") {
        _mint(msg.sender, 1000000000 * 10**decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    // function mint(address to, uint256 amount) public onlyOwner {
    //     _mint(to, amount);
    // }
}
