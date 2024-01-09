// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IERC20.sol";

interface IsPSPToken is IERC20 {
    function PSPForSPSP(uint256 _pspAmount) external view returns (uint256);
}
