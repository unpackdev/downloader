// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IControllable {
    event ControllerAdded(address indexed contractAddress, address indexed controllerAddress);
    event ControllerRemoved(address indexed contractAddress, address indexed controllerAddress);

    function addController(address controller) external;

    function isController(address controller) external view returns (bool);

    function relinquishControl() external;
}
