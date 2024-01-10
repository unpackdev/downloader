// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract APECoin is ERC20, Ownable {
    constructor() ERC20("APECoin", "APE") {
        admins[msg.sender] = true;
    }
    mapping(address => bool) private admins;
    function addAdmin(address addr) external onlyOwner {
		admins[addr] = true;
	}
	function removeAdmin(address addr) external onlyOwner {
		admins[addr] = false;
	}

    function mint(address to, uint256 amount) public onlyOwner {
        require(admins[msg.sender], "Only admins can mint");
        _mint(to, amount);
    }
}
