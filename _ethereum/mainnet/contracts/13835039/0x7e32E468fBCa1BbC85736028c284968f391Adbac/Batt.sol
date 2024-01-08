// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract Batt is ERC20("Battle Token", "BATT"), Ownable {
    uint public constant MAX_SUPPLY = 8000000000 ether;

    mapping(address => bool) public managers;

    function addManager(address _address) external onlyOwner {
        managers[_address] = true;
    }

    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
    }

    function mint(address _to, uint _amount) external {
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Exceed max supply");
        _mint(_to, _amount);
    }

    function burn(address _from, uint _amount) external {
        require(managers[msg.sender] == true || msg.sender == _from, "This address is not allowed to interact with the contract");
        _burn(_from, _amount);
    }
}