// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./ERC20.sol";
import "./Ownable.sol";

contract KOKODIToken is ERC20, Ownable {

    mapping(address => bool) public controllers;
    address public devAddress;

    constructor() ERC20("KOKODI Token", "KKDT") {
        controllers[owner()] = true;
        devAddress = owner();
    }

    function sendTokenTo(address account, uint amount) external onlyController {
        _mint(account, amount);
    }

    function sendTokens(address[] calldata addresses, uint[] calldata amounts) external onlyController {
        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i], amounts[i]);
        }
    }

    function transferToDevs(address from, uint256 amount) external onlyController {
        _transfer(from, devAddress, amount);
    }

    function setDevAddress(address _devAddress) external onlyController {
        devAddress = _devAddress;
    }

    modifier onlyController() {
        require(controllers[msg.sender], "Wrong caller!");
        _;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

}