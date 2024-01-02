// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./IERC20.sol";

interface Hypervisor is IERC20 {
    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function whitelistedAddress() external view returns (address);

    function withdraw(
        uint256 shares,
        address to,
        address from,
        uint256[4] memory minAmounts
    ) external returns (uint256 amount0, uint256 amount1);

    function getTotalAmounts() external view returns (uint256 total0, uint256 total1);
}
