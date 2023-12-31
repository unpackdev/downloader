// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IUpgradable.sol";
import "./ISquidMulticall.sol";

// This should be owned by the microservice that is paying for gas.
interface ISquidDepositService is IUpgradable {
    error ZeroAddressProvided();
    error NotRefundIssuer();
    error NativeTransferFailed();

    function addressForBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address);

    function addressForCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external view returns (address);

    function addressForCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address);

    function addressForFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external view returns (address);

    function bridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external;

    function callBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external;

    function callBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express
    ) external;

    function fundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external;

    function refundBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external;

    function refundCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient,
        address tokenToRefund
    ) external;

    function refundCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external;

    function refundFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient,
        address tokenToRefund
    ) external;

    function refundLockedAsset(address receiver, address token, uint256 amount) external;

    function receiverImplementation() external returns (address receiver);

    function refundToken() external returns (address);
}
