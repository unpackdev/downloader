// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IERC20.sol";

interface IyToken is IERC20 {
    function pricePerShare() external view returns (uint256);
}
