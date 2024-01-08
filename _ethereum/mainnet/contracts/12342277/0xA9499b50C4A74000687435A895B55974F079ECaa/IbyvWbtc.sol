// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./IERC20.sol";

interface IbyvWbtc is IERC20 {
    function pricePerShare() external view returns (uint);
}
