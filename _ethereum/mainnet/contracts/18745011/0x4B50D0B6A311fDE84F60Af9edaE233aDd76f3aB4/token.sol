//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";


 contract Gaming is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("Gaming", "GAMING")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 420000000000000 * 10 ** decimals());
    }
}