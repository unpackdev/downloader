// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFeeDistributorUpgradeable {
    error LengthMisMatch();
    error InvalidRecipient();

    event FeeUpdated();

    struct FeeInfo {
        address recipient;
        uint96 percentageInBps;
    }

    function clientInfo() external view returns (address recipient, uint96 percentage);
}
