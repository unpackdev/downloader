
/*

     ___   .___________.  ______   .___  ___. ____    ____  _______ .______          _______. _______ 
    /   \  |           | /  __  \  |   \/   | \   \  /   / |   ____||   _  \        /       ||   ____|
   /  ^  \ `---|  |----`|  |  |  | |  \  /  |  \   \/   /  |  |__   |  |_)  |      |   (----`|  |__   
  /  /_\  \    |  |     |  |  |  | |  |\/|  |   \      /   |   __|  |      /        \   \    |   __|  
 /  _____  \   |  |     |  `--'  | |  |  |  |    \    /    |  |____ |  |\  \----.----)   |   |  |____ 
/__/     \__\  |__|      \______/  |__|  |__|     \__/     |_______|| _| `._____|_______/    |_______|
                                                                                                      

*/



// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.6;
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";


contract nuclei is ERC20, ERC20Burnable, Ownable {

  mapping(address => bool) controllers;
  
  constructor() ERC20("Xielcun", "XNuc") { }

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  function burnFrom(address account, uint256 amount) public override {
      if (controllers[msg.sender]) {
          _burn(account, amount);
      }
      else {
          super.burnFrom(account, amount);
      }
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}