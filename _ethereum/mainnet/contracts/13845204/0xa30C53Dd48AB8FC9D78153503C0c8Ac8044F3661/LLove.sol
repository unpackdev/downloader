// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.6.0 <0.8.9;
import "./ERC20.sol";
import "./Ownable.sol";

contract LLove is ERC20("LLove", "LLOVE"), Ownable {
    uint16 public version=21;
    mapping(address => bool) public managers;

    function addManager(address _address) external onlyOwner {
        managers[_address] = true;
    }

    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
    }

    function mint(address _to, uint _amount) public {
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract mint");
        _mint(_to, _amount);
    }

    function burn(address _from, uint _amount) public {
        require(managers[msg.sender] == true, "This address is not allowed to interact with the contract burn");
        _burn(_from, _amount);
    }
}