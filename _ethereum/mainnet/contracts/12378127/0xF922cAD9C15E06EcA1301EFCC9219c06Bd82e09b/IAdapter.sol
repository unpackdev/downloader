// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IAdapter {
    function openPosition( address baseToken, address collToken, uint collAmount, uint borrowAmount ) external;
    function closePosition() external returns (uint);
    function liquidate() external;
    function settleCreditEvent(
        address baseToken, uint collateralLoss, uint poolLoss) external;

    event openPositionEvent(uint positionId, address caller, uint baseAmt, uint borrowAmount);
    event closePositionEvent(uint positionId, address caller, uint amount);
    event liquidateEvent(uint positionId, address caller);
    event creditEvent(address token, uint collateralLoss, uint poolLoss);
}
