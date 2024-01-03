// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

interface LotteryInterface {
    function fulfillRandom(uint) external;
    function canResolve() external view returns(bool);
    function results() external;
    function canContinue() external view returns(bool);
    function continueGame() external;
}