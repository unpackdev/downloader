// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract Wood is ERC20("Wood", "WOOD"), Ownable {
    mapping(address => bool) public managers;

    function addManager(address _address) external onlyOwner {
        managers[_address] = true;
    }

    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
    }

    function mint(address _to, uint _amount) external {
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract");
        _mint(_to, _amount);
    }

    function burn(address _from, uint _amount) external {
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract");
        _burn(_from, _amount);
    }
}