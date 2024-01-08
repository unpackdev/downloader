// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IFluidity {
    function initialFunding(uint value) external;

    function closeInitialFunding() external;

    function fundLiquidity(uint value) external;

    function withdrawLiquidity(uint value) external;

    function fundTokenPrice() external view returns (uint);

    function availableToFund() external view returns (uint);
}
