// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface ICoreFeesV1 {
    event FeeAccountUpdated(address actor, address feeAccount);

    function FEE_ACCOUNT() external returns (address payable);

    function updateFeeAccount(address payable feeAccount) external;
}
