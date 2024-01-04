// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPeggy {
    function sendToCosmos(
        address token,
        address destination,
        uint256 amount
    ) external;
}
