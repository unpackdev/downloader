// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./IControllable.sol";

abstract contract Controllable is IControllable {
    mapping(address => bool) _controllers;

    /**
     * @dev Throws if called by any account not in authorized list
     */
    modifier onlyController() {
        require(
            _controllers[msg.sender] == true || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        _;
    }

    /**
     * @dev Add an address allowed to control this contract
     */
    function _addController(address _controller) internal {
        _controllers[_controller] = true;
    }

    /**
     * @dev Add an address allowed to control this contract
     */
    function addController(address _controller) external override onlyController {
        _controllers[_controller] = true;
    }

    /**
     * @dev Check if this address is a controller
     */
    function isController(address _address) external view override returns (bool allowed) {
        allowed = _controllers[_address];
    }

    /**
     * @dev Check if this address is a controller
     */
    function relinquishControl() external view override onlyController {
        _controllers[msg.sender];
    }
}
