// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.6;

interface ISolidlyFactory {
    function getPair(address tokenA, address tokenB, bool stable) external view returns (address pair);
}
