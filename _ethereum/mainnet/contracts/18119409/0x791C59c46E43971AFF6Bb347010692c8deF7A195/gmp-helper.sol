// SPDX-FileCopyrightText: Hadron Labs
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

import "./IAxelarGateway.sol";
import "./IAxelarGasService.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";

interface IWSTETH is IERC20, IERC20Permit {}

/// @title GMP helper which makes it easier to call Lido Satellite on Neutron
/// @author Murad Karammaev
/// @notice Default flow (without a GMP Helper) is to:
///           1. tx approve() on wstETH contract
///           2. tx payNativeGasForContractCallWithToken() on Axelar Gas Service
///           3. tx callContractWithToken() on Axelar gateway
///         This contract simplifies it to:
///           1. tx approve() on wstETH contract
///           2. tx send() on GMP Helper
///         It is also possible to simplify it further if user wallet supports EIP-712 signing:
///           1. tx sendWithPermit() on GMP Helper
contract GmpHelper {
    IAxelarGasService public immutable GAS_SERVICE;
    IAxelarGateway public immutable GATEWAY;
    IWSTETH public immutable WST_ETH;
    // Address of Lido Satellite contract on Neutron, replace it with a real address before deploying
    string public constant LIDO_SATELLITE = "neutron1ug740qrkquxzrk2hh29qrlx3sktkfml3je7juusc2te7xmvsscns0n2wry";
    string public constant DESTINATION_CHAIN = "neutron";
    string public constant WSTETH_SYMBOL = "wstETH";

    /// @notice Construct GMP Helper
    /// @param axelarGateway Address of Axelar Gateway contract
    /// @param axelarGasReceiver Address of Axelar Gas Service contract
    /// @param wstEth Address of Wrapped Liquid Staked Ether contract
    constructor(
        address axelarGateway,
        address axelarGasReceiver,
        address wstEth
    ) {
        GAS_SERVICE = IAxelarGasService(axelarGasReceiver);
        GATEWAY = IAxelarGateway(axelarGateway);
        WST_ETH = IWSTETH(wstEth);
    }

    /// @notice Send `amount` of wstETH to `receiver` on Neutron.
    ///         Requires allowance on wstETH contract.
    ///         Requires gas fee in ETH.
    /// @param receiver Address on Neutron which shall receive canonical wstETH
    /// @param amount Amount of wstETH-wei to send to `receiver`
    /// @param gasRefundAddress Address which receives ETH refunds from Axelar,
    ///        use 0 to default to msg.sender
    function send(
        string calldata receiver,
        uint256 amount,
        address gasRefundAddress
    ) external payable {
        _send(receiver, amount, gasRefundAddress);
    }

    /// @notice Send `amount` of wstETH to `receiver` on Neutron, using EIP-2612 permit.
    ///         Requires gas fee in ETH.
    /// @param receiver Address on Neutron which shall receive canonical wstETH
    /// @param amount Amount of wstETH-wei to send to `receiver`
    /// @param deadline EIP-2612 permit signature deadline
    /// @param v Value `v` of EIP-2612 permit signature
    /// @param r Value `r` of EIP-2612 permit signature
    /// @param s Value `s` of EIP-2612 permit signature
    /// @param gasRefundAddress Address which receives ETH refunds from Axelar,
    ///        use 0 to default to msg.sender
    function sendWithPermit(
        string calldata receiver,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address gasRefundAddress
    ) external payable {
        WST_ETH.permit(msg.sender, address(this), amount, deadline, v, r, s);
        _send(receiver, amount, gasRefundAddress);
    }

    function _send(
        string calldata receiver,
        uint256 amount,
        address gasRefundAddress
    ) internal {
        // 1. withdraw wstETH from caller and approve it for Axelar Gateway.
        // Gateway will attempt to transfer funds from address(this), hence we
        // are forced to withdraw them from caller account first.
        WST_ETH.transferFrom(msg.sender, address(this), amount);
        WST_ETH.approve(address(GATEWAY), amount);

        // 2. Generate GMP payload
        bytes memory payload = _encodeGmpPayload(receiver);

        // 3. Pay for gas
        GAS_SERVICE.payNativeGasForContractCallWithToken{value: msg.value}(
            address(this),
            DESTINATION_CHAIN,
            LIDO_SATELLITE,
            payload,
            WSTETH_SYMBOL,
            amount,
            gasRefundAddress == address(0) ? msg.sender : gasRefundAddress
        );

        // 4. Make GMP call
        GATEWAY.callContractWithToken(
            DESTINATION_CHAIN,
            LIDO_SATELLITE,
            payload,
            WSTETH_SYMBOL,
            amount
        );
    }

    function _encodeGmpPayload(
        string memory targetReceiver
    ) internal pure returns (bytes memory) {
        require(bytes(targetReceiver).length > 8, "receiver address is too short"); // len("neutron1") == 8
        require(bytes(targetReceiver).length < 255, "receiver address is too long");

        bytes memory prefix = bytes("neutron1");
        for (uint8 i = 0; i < prefix.length; i++) {
            require(bytes(targetReceiver)[i] == prefix[i], "receiver: incorrect prefix");
        }

        bytes memory argValues = abi.encode(
            targetReceiver
        );

        string[] memory argumentNameArray = new string[](1);
        argumentNameArray[0] = "receiver";

        string[] memory abiTypeArray = new string[](1);
        abiTypeArray[0] = "string";

        bytes memory gmpPayload;
        gmpPayload = abi.encode(
            "mint",
            argumentNameArray,
            abiTypeArray,
            argValues
        );

        return abi.encodePacked(
            bytes4(0x00000001),
            gmpPayload
        );
    }
}
