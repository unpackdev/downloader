// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./VirtualBalance.sol";

interface IHelioswap {
    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function decayPeriod() external view returns (uint256);

    function fee() external view returns (uint256);

    function slippageFee() external view returns (uint256);

    function virtualBalancesForAddition(IERC20)
        external
        view
        returns (VirtualBalance.Data memory);

    function virtualBalancesForRemoval(IERC20)
        external
        view
        returns (VirtualBalance.Data memory);

    function token(uint256) external view returns (IERC20);

    function getReserves()
        external
        view
        returns (uint256 reserve0, uint256 reserve1);

    function estimateBalanceForAddition(IERC20) external view returns (uint256);

    function estimateBalanceForRemoval(IERC20) external view returns (uint256);
}
