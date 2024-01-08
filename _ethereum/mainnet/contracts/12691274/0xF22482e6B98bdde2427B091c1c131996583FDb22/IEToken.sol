// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "./IERC20.sol";

interface IEToken is IERC20 {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);

    function recover(IERC20 token, uint256 amount) external returns (bool);
}
