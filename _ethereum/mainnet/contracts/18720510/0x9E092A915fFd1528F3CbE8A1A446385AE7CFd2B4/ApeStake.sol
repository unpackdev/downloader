// SPDX-License-Identifier: MIT

/**
 * @title ApeStake Coin
 * @dev More info at: https://twitter.com/apestake
 */
pragma solidity ^0.8.19;


import "./Context.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";


contract ApeStake is ERC20, Ownable {

    string private constant TOKEN_NAME = "ApeStake";
    string private constant TOKEN_SYMBOL = "APSTK";
    uint256 private constant INITIAL_SUPPLY = 500000000 * (10 ** 18);

    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function totalSupply() public view override returns (uint256) {
        return INITIAL_SUPPLY;
    }
    /**
     * @dev Burns a specific amount of tokens.
     * @param amount The amount of token to be burned.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

}
