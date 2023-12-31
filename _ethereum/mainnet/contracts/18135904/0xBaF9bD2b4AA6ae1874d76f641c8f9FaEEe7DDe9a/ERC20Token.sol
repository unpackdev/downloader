pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Detailed.sol";

/**
 * @title ERC20Token
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract ERC20Token is ERC20, ERC20Detailed, Ownable {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor (
        string memory name, 
        string memory symbol, 
        uint8  decimal, 
        uint256 totalSupply
        ) public ERC20Detailed(name, symbol, decimal) {
        _mint(msg.sender, totalSupply * (10 ** uint256(decimals())));
    }


    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 value) public onlyOwner {
        _burn(account, value);
    }
}