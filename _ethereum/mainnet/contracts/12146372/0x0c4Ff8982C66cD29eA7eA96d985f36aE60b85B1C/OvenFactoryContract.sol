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
    address public defaultBaker;
    address public defaultCapSetter;

    function setDefaultController(address _controller) external onlyOwner {
        defaultController = _controller;
    }

    function setDefaultBaker(address _baker) external onlyOwner {
        defaultBaker = _baker;
    }

    function setDefaultCapSetter(address _capSetter) external onlyOwner {
        defaultCapSetter = _capSetter;
    }

    function CreateEmptyOven() external {
        CreateOven(address(0), address(0));
    }

    function CreateOven(address _pie, address _recipe) public {
        require(defaultController != address(0), "CONTROLLER_NOT_SET");

        Oven oven = new Oven(
            address(this), address(this), defaultBaker, _pie, _recipe
        );
        ovens.push(address(oven));
        isOven[address(oven)] = true;

        oven.setCap(uint256(-1));

        oven.grantRole(oven.CAP_SETTER_ROLE(), defaultCapSetter);
        oven.grantRole(oven.CONTROLLER_ROLE(), defaultController);

        oven.renounceRole(oven.CAP_SETTER_ROLE(), address(this));
        oven.renounceRole(oven.CONTROLLER_ROLE(), address(this));

        emit OvenCreated(address(oven), defaultController, _pie, _recipe);
    }
}
