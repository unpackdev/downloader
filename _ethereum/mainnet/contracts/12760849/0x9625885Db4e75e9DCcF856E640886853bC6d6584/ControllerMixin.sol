// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "./IController.sol";

contract ControllerMixin {
    event SetController(address controller);

    IController internal controller;

    constructor(IController _controller) {
        controller = _controller;
    }

    modifier onlyDao(string memory revertMsg) {
        require(msg.sender == controller.dao(), revertMsg);
        _;
    }

    modifier onlyDaoOrGuardian(string memory revertMsg) {
        require(controller.isDaoOrGuardian(msg.sender), revertMsg);
        _;
    }

    modifier issuanceNotPaused(string memory revertMsg) {
        require(controller.pausedIssuance() == false, revertMsg);
        _;
    }

    function _setController(address _controller) internal {
        controller = IController(_controller);
        emit SetController(_controller);
    }
}
