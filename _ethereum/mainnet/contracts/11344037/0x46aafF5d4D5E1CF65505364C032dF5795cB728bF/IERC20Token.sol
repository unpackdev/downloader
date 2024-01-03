// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./DNFTLibrary.sol";

interface IERC20Token is IERC20 {

    function decimals() external view returns (uint8);

}