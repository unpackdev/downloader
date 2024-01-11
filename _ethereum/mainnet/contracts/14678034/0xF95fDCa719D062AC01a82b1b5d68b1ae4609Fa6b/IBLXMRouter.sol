// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMRouter {

    function BLXM() external view returns (address);
    
    function addRewards(address token, uint totalBlxmAmount, uint16 supplyDays) external returns (uint amountPerHours);

    function addLiquidity(
        address token,
        uint amountBlxmDesired,
        uint amountTokenDesired,
        uint amountBlxmMin,
        uint amountTokenMin,
        address to,
        uint deadline,
        uint16 lockedDays
    ) external returns (uint amountBlxm, uint amountToken, uint liquidity);

    function removeLiquidity(
        uint liquidity,
        uint amountBlxmMin,
        uint amountTokenMin,
        address to,
        uint deadline,
        uint idx
    ) external returns (uint amountBlxm, uint amountToken, uint rewards);
}