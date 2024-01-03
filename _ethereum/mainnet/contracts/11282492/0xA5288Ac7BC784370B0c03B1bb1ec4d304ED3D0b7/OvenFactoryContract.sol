// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./Ownable.sol";
import "./Oven.sol";

contract OvenFactoryContract is Ownable {
    event OvenCreated(
        address Oven,
        address Controller,
        address Pie,
        address Recipe
    );

    address[] public ovens;
    mapping(address => bool) public isOven;
    address public defaultController;

    function setDefaultController(address _controller) external onlyOwner {
        defaultController = _controller;
    }

    function CreateEmptyOven() external {
        CreateOven(address(0), address(0));
    }

    function CreateOven(address _pie, address _recipe) public {
        require(defaultController != address(0), "CONTROLLER_NOT_SET");

        Oven oven = new Oven(address(this), _pie, _recipe);
        ovens.push(address(oven));
        isOven[address(oven)] = true;

        oven.setCap(uint256(-1));
        oven.setController(defaultController);
        emit OvenCreated(address(oven), defaultController, _pie, _recipe);
    }
}
