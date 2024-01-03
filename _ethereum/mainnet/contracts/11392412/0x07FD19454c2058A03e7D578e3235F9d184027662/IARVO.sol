// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./IERC20.sol";

interface IARVO is IERC20 {
    function mint(address _beneficiary, uint256 _amount) external;
    function burn(address _beneficiary, uint256 _amount) external;
}
