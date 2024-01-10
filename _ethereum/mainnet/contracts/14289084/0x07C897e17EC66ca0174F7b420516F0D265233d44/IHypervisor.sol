// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

interface IHypervisor {

    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to
    ) external returns (uint256 shares);

    function withdraw(
        uint256 shares,
        address to,
        address from
    ) external returns (uint256 amount0, uint256 amount1);

    function balanceOf(address user) external view returns(uint256);

    function totalSupply() external view returns (uint256);

    function token0() external view returns(address);

    function token1() external view returns(address);

    function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

    function transferFrom(address from, address to, uint value) external returns (bool);
}
