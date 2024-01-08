// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract Tuna is ERC20("Tuna", "TUNA"), Ownable {
    uint public limit = 15000000 ether; // 15 000 000 is default emission limit
    
    mapping(address => bool) public managers;

    function addManager(address _address) external onlyOwner {
        managers[_address] = true;
    }

    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
    }

    function setLimit(uint _limit) external onlyOwner {
        limit = _limit;
    }
    
    function privateMint(address _to, uint _amount) external onlyOwner {
        require(this.totalSupply() + _amount <= limit, "Emission limit reached");
        _mint(_to, _amount);
    }

    function privateBurn(address _from, uint _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    function mint(address _to, uint _amount) external {
        require(this.totalSupply() + _amount <= limit, "Emission limit reached");
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract");
        _mint(_to, _amount);
    }

    function burn(address _from, uint _amount) external {
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract");
        _burn(_from, _amount);
    }
}
