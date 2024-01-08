// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IPositionAmountChecker {

    function checkPositionAmount(address baseToken, address quoteToken, uint256 amount, uint256 leverageScaled) external view returns (bool);

}