// SPDX-License-Identifier: GPL-3.0

/*
██████╗  █████╗ ███████╗     █████╗ ██████╗ ███████╗███████╗
██╔══██╗██╔══██╗██╔════╝    ██╔══██╗██╔══██╗██╔════╝██╔════╝
██████╔╝███████║█████╗      ███████║██████╔╝█████╗  ███████╗
██╔══██╗██╔══██║██╔══╝      ██╔══██║██╔═══╝ ██╔══╝  ╚════██║
██████╔╝██║  ██║███████╗    ██║  ██║██║     ███████╗███████║
╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

~ See you in Banana Coast!

Founders: @richThecreator, @GreatRedApe @Ape-Eeeee
Developed By: @richTheCreator
*/

pragma solidity ^0.8.7;

import "./ERC20.sol";

contract Peel is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply_
    ) ERC20(name, symbol) {
        _mint(msg.sender, totalSupply_);
    }
}
