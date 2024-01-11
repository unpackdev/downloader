// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IWeedERC20 {
    function mint(address _address, uint256 _amount) external;
    function burn(address _address, uint256 _amount) external;
}
