// contracts/ISeed.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";


interface ISeeds is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address _fruitAddress, address staker) external view returns (uint256);
}
