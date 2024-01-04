pragma solidity ^0.6.0;

import "./ERC20.sol";

/**
 * @title BitconnectToken
 */
contract BitconnectToken is ERC20 {
    // modify token name
    string public constant NAME = "Bitconnect Community Token";
    // modify token symbol
    string public constant SYMBOL = "BCCX";
    // modify token decimals
    uint8 public constant DECIMALS = 18;
    // modify initial token supply
    uint256 public constant INITIAL_SUPPLY = 10000000 * (10 ** uint256(DECIMALS)); // 10 million tokens

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20(NAME, SYMBOL) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
