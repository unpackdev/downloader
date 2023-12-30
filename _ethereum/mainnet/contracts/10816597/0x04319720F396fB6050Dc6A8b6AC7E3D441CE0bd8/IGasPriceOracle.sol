// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./IERC20.sol";

interface IGasPriceOracle {

    function latestAnswer() external view returns (int256);


}
