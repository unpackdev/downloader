//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IPolicyManager {
    function enablePolicyForFund(
        address,
        address,
        bytes calldata
    ) external;
}
