// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract Governable {
    address public governance;

    constructor() {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "only governance");
        _;
    }

    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "null governance");
        governance = _governance;
    }
}
