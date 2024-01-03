// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

interface IKingSwapCallee {
    function KingSwapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
