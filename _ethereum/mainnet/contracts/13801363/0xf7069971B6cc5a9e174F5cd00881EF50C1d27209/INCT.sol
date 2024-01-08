// contracts/INCT.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @title INCT
 * @dev NCT minimal interface, it extends the IERC20 with a burn function
 *
 * Authors: s.imo
 * Created: 01.07.2021
 */
interface INCT is IERC20 {

    function burn(uint256 burnQuantity) external;

}