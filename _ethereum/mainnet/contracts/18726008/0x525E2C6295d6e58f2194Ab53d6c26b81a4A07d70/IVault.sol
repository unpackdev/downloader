// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVault {
    /****************user api*********************/
    function preDeposit(
        uint n,
        bytes calldata withdrawalCredential,
        bool createELFee
    ) external payable;

    function onSplitFee() external payable;

    /****************privileged api*********************/

    // only for depositor

    function deposit(
        bytes calldata pubkeys,
        bytes calldata signatures,
        bytes32[] calldata depositDataRoots,
        bytes calldata withdrawalCredentials,
        uint32[] calldata ns
    ) external;

    // only for fee collector
    function collectFee() external;

    // only for owner

    function setDepositor(address _depositor) external;

    function setFeeCollector(address _feeCollector) external;

    function setDepositFee(uint depositFee) external;

    function setELFee(uint elFee) external;

    function setWithdrawalELFee(address user, uint elFee) external;

    event PreDeposit(
        address sender,
        uint n,
        bool createELFee,
        bytes withdrawalCredential,
        address elFeeContract
    );

    event Deposit(bytes pubkeys, bytes signatures, bytes32[] depositDataRoots);
    event CollectFee(address collector, uint amount);
    event SetDepositor(address depositor);
    event SetFeeCollector(address feeCollector);
    event SetDepositFee(uint depositFee);
    event SetELFee(uint elFee);
    event SetWithdrawalELFee(address user, uint elFee);
}
