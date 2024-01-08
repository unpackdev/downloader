// contracts/INCT.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface INCT is IERC20 {

    function burn(uint256 burnQuantity) external;

}