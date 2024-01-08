// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface ILiquidation {
    function liquidate(uint32 positionId) external;

    function bankruptedLiquidate(uint32 positionId) external;

    function alertLiquidation(uint32 positionId) external view returns (bool);

    function alertBankruptedLiquidation(uint32 positionId) external view returns (bool);
}
