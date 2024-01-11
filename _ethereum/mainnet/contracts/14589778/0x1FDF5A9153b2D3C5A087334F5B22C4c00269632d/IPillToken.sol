// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./IERC20.sol";

interface IPillToken is IERC20 {
    function mint(address _user, uint256 _amount) external;
}
