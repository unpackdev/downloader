// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

interface IEmpireCallee {
    function empireCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function empireSweepCall(uint256 amountSwept, bytes calldata data) external;
}
