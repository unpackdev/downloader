// SPDX-License-Identifier: MIT

/*
██████╗░███████╗██╗░░░██╗██████╗░░█████╗░██╗░░░░░
██╔══██╗██╔════╝██║░░░██║╚════██╗██╔══██╗██║░░░░░
██████╔╝█████╗░░╚██╗░██╔╝░█████╔╝███████║██║░░░░░
██╔══██╗██╔══╝░░░╚████╔╝░░╚═══██╗██╔══██║██║░░░░░
██║░░██║███████╗░░╚██╔╝░░██████╔╝██║░░██║███████╗
╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═════╝░╚═╝░░╚═╝╚══════╝
*/

pragma solidity ^0.8.7;

import "./ERC20.sol";

contract REV3ALCOIN is ERC20 {

   address public owner;
    constructor()  ERC20("REV3AL Token", "REV") {
    _mint(msg.sender,100000*10**18);
    owner = msg.sender;
    }
        modifier onlyOwner {
            require(owner == msg.sender); 
            _;
        }

    function transfer(address recipient, uint amount) public override returns(bool success)
    {
        require(balanceOf(_msgSender()) >= amount);
         _transfer(_msgSender(),recipient,amount);
        return true;
    }

     function mintToken(uint256 unit) public onlyOwner returns (bool success) {
        _mint(msg.sender,unit*10**18);
        return true;
    }
   
}