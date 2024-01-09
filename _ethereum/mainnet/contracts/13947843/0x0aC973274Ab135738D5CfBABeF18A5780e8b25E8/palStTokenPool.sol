// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IERC20.sol";

interface palStTokenPool is IERC20 {
    function exchangeRateStored() external view returns (uint256);
}
