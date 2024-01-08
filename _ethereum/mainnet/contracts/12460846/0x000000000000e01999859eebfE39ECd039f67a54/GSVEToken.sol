// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";

/**
* @dev the GSVE token is a ERC20 token with burning capabilities
*/
contract GSVEToken is ERC20{    
    using SafeMath for uint256;

    /**
    * @dev mint 1 billion GSVE tokens
    */
    constructor() public ERC20("Gas Save Protocol Token", "GSVE") {
        _mint(msg.sender, 100000000*(10**18));
    }

    /**
    * @dev a function that allows a user to burn x amount of tokens
    */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
    * @dev a function that allows burning tokens from an approved address
    */
    function burnFrom(address account, uint256 amount) external {
        _burn(account, amount);
        uint256 allowed = allowance(account, msg.sender);
        if ((allowed >> 255) == 0) {
            _approve(account, msg.sender, allowed.sub(amount, "ERC20: burn amount exceeds allowance"));
        }
    }
}