// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMintable {
    function setBridge(address _bridge) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}
