// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Yfact is ERC20, Ownable, ERC20Burnable {
    using SafeMath for uint256;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public ERC20(name, symbol) Ownable() {
        _mint(_msgSender(), initialSupply.mul(10**uint256(decimals())));
    }
}
