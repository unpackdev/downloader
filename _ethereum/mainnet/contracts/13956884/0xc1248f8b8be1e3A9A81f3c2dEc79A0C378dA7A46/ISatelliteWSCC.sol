// SPDX-License-Identifier: Unlicense

import "./IERC20.sol";

pragma solidity >=0.6.0 <0.8.0;

interface ISatelliteWSCC is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
    function burn(address from, uint256 amount) external;
}