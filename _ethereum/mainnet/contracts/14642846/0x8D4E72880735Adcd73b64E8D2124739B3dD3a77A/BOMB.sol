pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract BOMB is Context, ERC20, Ownable {
    constructor () public ERC20("Bomb", "BOMB") {
        _mint(_msgSender(), 999999999999999999999999999999999);
    }
}
