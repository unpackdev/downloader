// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IOE is IERC20 {
    function getIsOdd() external view returns(bool);
}
