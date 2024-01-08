/*

 ██████╗██████╗  ██████╗  ██████╗ ██████╗ ██████╗ ██╗██╗     ███████╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔══██╗██╔═══██╗██╔════╝██╔═══██╗██╔══██╗██║██║     ██╔════╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
██║     ██████╔╝██║   ██║██║     ██║   ██║██║  ██║██║██║     █████╗      ██║  ███╗███████║██╔████╔██║█████╗  
██║     ██╔══██╗██║   ██║██║     ██║   ██║██║  ██║██║██║     ██╔══╝      ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
╚██████╗██║  ██║╚██████╔╝╚██████╗╚██████╔╝██████╔╝██║███████╗███████╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
 ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
                                                                                                             
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "Ownable.sol";
import "ERC20.sol";

import "ICrocodileGamePiranha.sol";

contract CrocodileGamePiranha is ICrocodileGamePiranha, ERC20, Ownable {
    // The implementation of ERC20 token is heavily borrowed from the fox.game code.

    mapping(address => bool) public controllers;
  
    constructor() ERC20("CrocodileGame", "PIRANHA") {}


    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }


    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}