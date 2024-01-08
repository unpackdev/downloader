pragma solidity ^0.5.0;

import "./ERC20Detailed.sol";
import "./ERC20.sol";
import "./ERC20Pausable.sol";
import "./ERC20Burnable.sol";

contract SDS is ERC20, ERC20Detailed, ERC20Pausable, ERC20Burnable {

    string private constant NAME = "SDS  Token";
    string private constant SYMBOLS = "SDS";
    uint8 private constant DECIMALS = 18;
    uint256 private constant INITIAL_SUPPLY = 800000000;

    constructor() public ERC20Detailed(NAME, SYMBOLS, DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY * (10 ** uint256(decimals())));
    }

}
