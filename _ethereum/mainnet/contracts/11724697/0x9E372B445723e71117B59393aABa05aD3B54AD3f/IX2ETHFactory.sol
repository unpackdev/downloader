// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2ETHFactory {
    function feeReceiver() external view returns (address);
    function interestReceiver() external view returns (address);
}
