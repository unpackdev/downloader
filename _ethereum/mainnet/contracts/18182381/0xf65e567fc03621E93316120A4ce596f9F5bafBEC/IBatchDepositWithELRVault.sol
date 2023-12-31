// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
 
interface IBatchDepositWithELRVault {

    /// @notice Thrown when zero value is set 
    error ZeroValueSet();

    /// @notice Thrown when values are set repeatedly
    error RepeatSetup();
    
    /// @notice Thrown when ETH amount error which is deposited
    error InvalidETHAmount();

    /// @notice The number of validators activated by a user at a time must not exceed the maxPerDeposit
    error ExceedingMaxLimit();

    /// @notice Thrown when Pubkeys' amount error
    error PubkeysCountError();

    /// @notice Thrown when WithdrawalCredentials' amount error
    error WithdrawalCredentialsCountError();

    /// @notice Thrown when Signatures' amount error
    error SignaturesCountError();

    /// @notice Thrown when DepositDataRoots' amount error
    error DepositDataRootsCountError();

    /// @notice Thrown when single pubkey is used twice
    error PubkeyUsed();

    /// @notice Thrown when single pubkey length error
    error PubkeyLengthError();

    /// @notice Thrown when single withdrawalCredential length error
    error WithdrawalCredentialLengthError();

    /// @notice Thrown when single signature length error
    error SignatureLengthError();

    event BatchDeposited(address indexed addr, bytes32 tag, bytes[] pubKeys, uint256 totalETHDeposited);
    
    event UpdateMaxPerDeposit(uint256 newMaxPerDeposit);

    event Swept(address indexed operator, address indexed receiver, uint256 ETHAmount);
}