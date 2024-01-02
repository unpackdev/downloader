// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

interface IDepositContract {
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}

contract BatchDepositToBeacon {
    error InvalidDepositSetup();
    error InvalidAmount();
    error MismatchedArrays();

    event BatchDepositedToBeacon(address depositer, uint256 totalAmountDeposited);

    uint256 private constant _CREDENTIALS_LENGTH = 32;
    uint256 private constant _MAX_VALIDATORS = 200;
    uint256 private constant _DEPOSIT_AMOUNT = 32 ether;

    IDepositContract public immutable depositContract;

    constructor(address _depositContract) {
        depositContract = IDepositContract(_depositContract);
    }

    /// @notice Batch Deposit To Beacon Deposit Contract, number of deposits limited to number of _MAX_VALIDATORS
    function batchDeposit(
        bytes[] calldata pubkeys,
        bytes calldata withdrawal_credentials,
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots
    ) external payable {
        if (withdrawal_credentials.length != _CREDENTIALS_LENGTH) revert InvalidDepositSetup();
        uint256 len = deposit_data_roots.length;
        if (len > _MAX_VALIDATORS) revert InvalidDepositSetup();
        if (len != pubkeys.length || len != signatures.length) revert MismatchedArrays();
        if (msg.value != len * _DEPOSIT_AMOUNT) revert InvalidAmount();

        for (uint256 i; i < len;) {
            depositContract.deposit{value: _DEPOSIT_AMOUNT}(
                pubkeys[i], withdrawal_credentials, signatures[i], deposit_data_roots[i]
            );
            unchecked {
                ++i;
            }
        }

        emit BatchDepositedToBeacon(msg.sender, msg.value);
    }
}
