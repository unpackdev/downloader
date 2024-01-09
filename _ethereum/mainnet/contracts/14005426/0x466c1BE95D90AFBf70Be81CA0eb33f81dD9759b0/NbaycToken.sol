// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

import "./console.sol";

contract NbaycToken is ERC20Burnable, Ownable {

    mapping(address => bool) private admins;

    constructor(address adminAddr) ERC20("Ball", "BALL") {
        admins[adminAddr] = true;
    }

    function mintReward(address recipient, uint amount) external onlyAdmin {

        console.log("Mint tokens : %s, %s from %s", recipient, amount, msg.sender);

        // Create the money and send it to the recipient
        // Like banks ...
        _mint(recipient, amount);
    }

    // When an amount is used for a match, it is burnt here...
    function burnMoney(address recipient, uint amount) external onlyAdmin {

        _burn(recipient, amount);
    }


    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can call this");
        _;
    }

    function setAdmin(address addr) public onlyAdmin {
        admins[addr] = true;
    }
    
    function unsetAdmin(address addr) public onlyAdmin {
        delete admins[addr];
    }

}
