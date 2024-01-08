// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

interface IOracleSimple {
    function update() external returns (bool);

    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}
