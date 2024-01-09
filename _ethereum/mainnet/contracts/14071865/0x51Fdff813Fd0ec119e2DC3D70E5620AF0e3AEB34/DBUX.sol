// SPDX-License-Identifier: MIT

// The official ERC20 currency token of the Dickbutt ecosystem

pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";

contract DBUX is ERC20, Ownable
{
    mapping(address => bool) controllers;

    constructor() ERC20("Dickbucks", "DBUX") {}

    function mint(address to, uint256 amount) external onlyController
    {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyController
    {
        _burn(from, amount);
    }

    function addController(address controller) external onlyOwner
    {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner
    {
        controllers[controller] = false;
    }

    modifier onlyController()
    {
        require(controllers[_msgSender()] == true, "Caller is not controller");
        _;
    }
}