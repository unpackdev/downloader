pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";

contract RolazGold is ERC20, ERC20Detailed, ERC20Burnable {

    constructor () public ERC20Detailed("RolazGold", "rGLD", 18) {
        _mint(msg.sender, 50000000 * (10 ** uint256(decimals())));
    }
}