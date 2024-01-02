// SPDX-License-Identifier: MIT

/**
 * @title LilPudgys Pudgy Coin Contract
 * @notice A simple ERC20 token named LilPudgys
 * @dev More info at: https://twitter.com/lilpudgyscoin
 */
pragma solidity ^0.8.19;

// Importing OpenZeppelin's libraries for safe and standard implementations
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";

// LilPudgys token contract definition
contract LilPudgys is ERC20, Ownable {

    uint256 private constant INITIAL_SUPPLY = 500000000 * (10 ** 18);

    string private constant TOKEN_NAME = "LilPudgys";
    string private constant TOKEN_SYMBOL = "LILPDG";

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
