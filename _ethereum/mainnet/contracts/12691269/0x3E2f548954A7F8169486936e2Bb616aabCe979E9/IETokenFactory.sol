// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "./IEToken.sol";

interface IETokenFactory {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function createEToken(string memory name, string memory symbol) external returns (IEToken);
}
