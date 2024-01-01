// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ICurveFiStableSwapPool {
    function price_oracle() external view returns (uint256);
    function ma_last_time() external view returns (uint256);
}
