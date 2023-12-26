// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract BridgeMock {
    function bridge(address token, uint256 amount, uint256, address, bytes memory) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }
}
