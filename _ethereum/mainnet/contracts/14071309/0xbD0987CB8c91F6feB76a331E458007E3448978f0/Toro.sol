// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract Toro is ERC20("Toro", "TORO"), Ownable {
    mapping(address => bool) public managers;
    bool public mintT = false;

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

    function mintTreasury(uint _amount) external onlyOwner {
    require(mintT = false, "Treasury mint has already occurred");
        mintT = true;
        _mint(msg.sender, _amount);
    }
}