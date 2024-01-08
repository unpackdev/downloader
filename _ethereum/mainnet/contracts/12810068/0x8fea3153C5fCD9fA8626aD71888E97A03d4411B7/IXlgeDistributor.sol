// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IXlgeDistributor {
    function removeLiquidityETH(
        uint256 _amountLGEToken,
        uint256 _amountXVIXMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    ) external;
}
