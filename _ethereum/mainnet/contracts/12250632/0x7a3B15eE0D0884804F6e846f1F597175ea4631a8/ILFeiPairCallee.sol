// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ILFeiPairCallee {
    function lFeiPairCall(
        address sender,
        uint256 amountFeiOut,
        bytes calldata data
    ) external;
}
