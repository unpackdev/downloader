// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

interface ISynapseBridge {
    // Struct to store deposit data
    struct Deposit {
        address sourceNetworkToken;
        address destinationNetworkToken;
        address sender;
        address receiver;
        uint256 amount;
        uint256 sourceChainId;
        uint256 destinationChainId;
        uint256 nonce;
    }

    // Struct to store withdraw data
    struct Withdraw {
        address sourceNetworkToken;
        address destinationNetworkToken;
        address sender;
        address receiver;
        uint256 amount;
        uint256 sourceChainId;
        uint256 destinationChainId;
        uint256 nonce;
    }

    // Events
    event DepositEvent(
        address indexed sourceNetworkToken,
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        uint256 sourceChainId,
        uint256 destinationChainId,
        uint256 nonce
    );

    event WithdrawEvent(
        address indexed destinationNetworkToken,
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        uint256 sourceChainId,
        uint256 destinationChainId,
        uint256 nonce
    );

    event EmergencyWithdrawEvent(
        address indexed token,
        address indexed receiver,
        uint256 amount
    );

    event RenounceEvent(
        address indexed destinationNetworkToken,
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        uint256 sourceChainId,
        uint256 destinationChainId,
        uint256 nonce
    );

    event PaymentReceived(address from, uint256 amount);

    // Errors
    error Unauthorized();
    error InvalidSigner();
    error InvalidAmount();
    error InvalidChainId();
    error WithdrawFailed();
    error InvalidTransfer();
    error AddressZeroCheck();
    error ChainIdZeroCheck();
    error HashAlreadyUsed();
    error InsufficientAvailableBalance();
}
