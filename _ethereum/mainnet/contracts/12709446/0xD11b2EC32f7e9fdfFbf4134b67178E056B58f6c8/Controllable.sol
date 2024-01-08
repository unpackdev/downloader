// SPDX-License-Identifier: MIT
// @author: https://github.com/SHA-2048

pragma solidity ^0.8.0;

import "./Controller.sol";

contract Controllable {

    Controller public controller;

    constructor(Controller _controller) {
        controller = _controller;
    }

    modifier whenNotPaused() {
        require(!controller.paused(), "Forbidden: System is paused");
        _;
    }

}
