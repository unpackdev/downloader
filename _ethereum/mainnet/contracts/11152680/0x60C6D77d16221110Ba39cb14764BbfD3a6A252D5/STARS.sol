pragma solidity ^0.5.4;

import "./ERC20Mintable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";


contract STARS is ERC20Detailed, ERC20Mintable, ERC20Burnable {
    string private _name = "STARS";
    string private _symbol = "STARS";
    uint8 private _decimal = 18;

    constructor() public ERC20Detailed(_name, _symbol, _decimal) {}
}
