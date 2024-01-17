// SPDX-License-Identifier: MIT
// Ermine utility token (ERM) :: https://ermine.pro 


//  ███████╗██████╗$███╗$$$███╗██╗███╗$$$██╗███████╗
//  ██╔════╝██╔══██╗████╗$████║██║████╗$$██║██╔════╝
//  █████╗$$██████╔╝██╔████╔██║██║██╔██╗$██║█████╗$$
//  ██╔══╝$$██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██╔══╝$$
//  ███████╗██║$$██║██║$╚═╝$██║██║██║$╚████║███████╗
//  ╚══════╝╚═╝$$╚═╝╚═╝$$$$$╚═╝╚═╝╚═╝$$╚═══╝╚══════╝


pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Ermine is ERC20, Ownable {
    uint256 public maxAmountERM = 800 * 1e24;
    uint256 public burnedERM = 0;

    event Burn(address indexed from, uint256 amount);
    
    constructor () ERC20 ("Ermine", "ERM") {
        _mint(msg.sender, maxAmountERM);
    }

//Burning is available to everyone
    function burn(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "There are not enough tokens on your balance!");
        require((totalSupply() - amount) >= (400 * 1e24), "No more burning! At least 400M ERM must remain!");
        _burn(msg.sender, amount);
        burnedERM += amount;
        emit Burn(msg.sender, amount);
    }    
}