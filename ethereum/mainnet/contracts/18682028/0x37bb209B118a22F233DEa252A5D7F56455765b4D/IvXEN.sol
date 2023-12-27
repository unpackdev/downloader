// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

import "./ILayerZeroReceiver.sol";
import {IWormholeReceiver} from  "./IWormholeReceiver.sol";
import {IBurnRedeemable} from  "./IBurnRedeemable.sol";

/*
 * @title vXEN Contract
 *
 * @notice This interface outlines functions for the vXEN token, an ERC20 token with bridging and burning capabilities.
 *
 * Co-Founders:
 * - Simran Dhillon: simran@xenify.io
 * - Hardev Dhillon: hardev@xenify.io
 * - Dayana Plaz: dayana@xenify.io
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IvXEN is
    IBurnRedeemable,
    IWormholeReceiver,
    ILayerZeroReceiver
{
    /// -------------------------------------- ERRORS --------------------------------------- \\\

    /**
     * @notice This error is thrown when only the team is allowed to call a function.
     */
    error OnlyTeamAllowed();

    /**
     * @notice This error is thrown when XEN address is already set.
     */
    error XENIsAlreadySet();

    /**
     * @notice This error is thrown when the fee provided is insufficient.
     */
    error InsufficientFee();

    /**
     * @notice This error is thrown when the caller is not verified.
     */
    error NotVerifiedCaller();

    /**
     * @notice This error is thrown when only the relayer is allowed to call a function.
     */
    error OnlyRelayerAllowed();

    /**
     * @notice This error is thrown when the address length is invalid or less than the expected length.
     */
    error InvalidAddressLength();

    /**
     * @notice This error is thrown when the source address is invalid.
     */
    error InvalidSourceAddress();

    /**
     * @notice This error is thrown when the hex string length is not even.
     */
    error HexStringLengthNotEven();

    /**
     * @notice This error is thrown when the provided Ether is not enough to cover the estimated gas fee.
     */
    error InsufficientFeeForWormhole();

    /**
     * @notice This error is thrown when the Wormhole source address is invalid.
     */
    error InvalidWormholeSourceAddress();

    /**
     * @notice This error is thrown when the LayerZero source address is invalid.
     */
    error InvalidLayerZeroSourceAddress();

    /**
     * @notice This error is thrown when a Wormhole message has already been processed.
     */
    error WormholeMessageAlreadyProcessed();

    /// ------------------------------------- ENUMS ----------------------------------------- \\\

    /**
     * @notice Enum to represent the different bridges available.
     * @dev LayerZero = 1, Axelar = 2, Wormhole = 3.
     */
    enum BridgeId {
        LayerZero,
        Axelar,
        Wormhole
    }

    /// -------------------------------------- EVENTS --------------------------------------- \\\

    /**
     * @notice Emitted when vXEN tokens are bridged to another chain.
     * @param from Address on the source chain that initiated the bridge.
     * @param burnedAmount Amount of vXEN tokens burned for the bridge.
     * @param bridgeId Identifier for the bridge used
     * @param outgoingChainId ID of the destination chain.
     * @param to Address on the destination chain to receive the tokens.
     */
    event vXENBridgeTransfer(
        address indexed from,
        uint256 burnedAmount,
        BridgeId indexed bridgeId,
        bytes outgoingChainId,
        address indexed to
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Emitted when vXEN tokens are received from a bridge.
     * @param to Address that receives the minted vXEN tokens.
     * @param mintAmount Amount of vXEN tokens minted.
     * @param bridgeId Identifier for the bridge used
     * @param incomingChainId ID of the source chain.
     * @param from Address on the source chain that initiated the bridge.
     */
    event vXENBridgeReceive(
        address indexed to,
        uint256 mintAmount,
        BridgeId indexed bridgeId,
        bytes incomingChainId,
        address indexed from
    );

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Sets the XEN contract address.
     * @dev This function is called by the team to set XEN contract address.
     * Function can be called only once.
     * @param _XEN The XEN contract address.
     * @param _ratio The ratio between vXEN and XEN used for minting and burning.
     */
    function setXENAndRatio(address _XEN, uint256 _ratio) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns the specified amount of XEN tokens and mints an equivalent amount of vXEN tokens.
     * @param _amount Amount of XEN tokens to burn.
     */
    function burnXEN(uint256 _amount) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns the specified amount of XEN tokens and bridges them via the LayerZero network.
     * @dev Burns the XEN tokens from the sender's address and then initiates a bridge operation using the LayerZero network.
     * @param _amount The amount of XEN tokens to burn and bridge.
     * @param dstChainId The Chain ID of the destination chain on the LayerZero network.
     * @param to The recipient address on the destination chain.
     * @param feeRefundAddress Address to refund any excess fees.
     * @param zroPaymentAddress Address of the ZRO token holder who would pay for the transaction.
     * @param adapterParams Parameters for custom functionality, e.g., receiving airdropped native gas from the relayer on the destination.
     */
    function burnAndBridgeViaLayerZero(
        uint256 _amount,
        uint16 dstChainId,
        address to,
        address payable feeRefundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns the specified amount of XEN tokens and bridges them via the Axelar network.
     * @dev Burns the XEN tokens from the sender's address and then initiates a bridge operation using the Axelar network.
     * @param _amount The amount of XEN tokens to burn and bridge.
     * @param dstChainId The target chain where tokens should be bridged to on the Axelar network.
     * @param to The recipient address on the destination chain.
     * @param feeRefundAddress Address to refund any excess fees.
     */
    function burnAndBridgeViaAxelar(
        uint256 _amount,
        string calldata dstChainId,
        address to,
        address payable feeRefundAddress
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns the specified amount of XEN tokens and bridges them via the Wormhole network.
     * @dev Burns the XEN tokens from the sender's address and then initiates a bridge operation using the Wormhole network.
     * @param _amount The amount of XEN tokens to burn and bridge.
     * @param targetChain The ID of the target chain on the Wormhole network.
     * @param to The recipient address on the destination chain.
     * @param feeRefundAddress Address to refund any excess fees.
     * @param gasLimit The gas limit for the transaction on the destination chain.
     */
    function burnAndBridgeViaWormhole(
        uint256 _amount,
        uint16 targetChain,
        address to,
        address payable feeRefundAddress,
        uint256 gasLimit
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns a specific amount of vXEN tokens from a user's address.
     * @dev Allows an external entity to burn tokens from a user's address, provided they have the necessary allowance.
     * @param _user The address from which the vXEN tokens will be burned.
     * @param _amount The amount of vXEN tokens to burn.
     */
    function burn(
        address _user,
        uint256 _amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Bridges tokens to another chain via LayerZero.
     * @dev Encodes destination and contract addresses, checks Ether sent against estimated gas,
     * then triggers the LayerZero endpoint to bridge tokens.
     * @param _dstChainId ID of the target chain on LayerZero.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param feeRefundAddress Address for any excess fee refunds.
     * @param _zroPaymentAddress Address of the ZRO token holder covering transaction fees.
     * @param _adapterParams Additional parameters for custom functionalities.
     */
    function bridgeViaLayerZero(
        uint16 _dstChainId,
        address from,
        address to,
        uint256 _amount,
        address payable feeRefundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Bridges tokens to another chain via Axelar.
     * @dev Encodes sender's address and amount, then triggers the Axelar gateway to bridge tokens.
     * @param destinationChain ID of the target chain on Axelar.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param feeRefundAddress Address for any excess fee refunds.
     */
    function bridgeViaAxelar(
        string calldata destinationChain,
        address from,
        address to,
        uint256 _amount,
        address payable feeRefundAddress
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Bridges tokens to another chain via Wormhole.
     * @dev Estimates gas for the Wormhole bridge, checks Ether sent, then triggers the Wormhole relayer.
     * @param targetChain ID of the target chain on Wormhole.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param feeRefundAddress Address for any excess fee refunds.
     * @param _gasLimit Gas limit for the transaction on the destination chain.
     */
    function bridgeViaWormhole(
        uint16 targetChain,
        address from,
        address to,
        uint256 _amount,
        address payable feeRefundAddress,
        uint256 _gasLimit
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Estimates the bridging fee on LayerZero.
     * @dev Uses the `estimateFees` method of the endpoint contract.
     * @param _dstChainId ID of the destination chain on LayerZero.
     * @param from Sender's address on the source chain.
     * @param to Recipient's address on the destination chain.
     * @param _amount Amount of tokens to bridge.
     * @param _payInZRO If false, user pays the fee in native token.
     * @param _adapterParam Parameters for adapter services.
     * @return nativeFee Estimated fee in native tokens.
     */
    function estimateGasForLayerZero(
        uint16 _dstChainId,
        address from,
        address to,
        uint256 _amount,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Estimates the bridging fee on Wormhole.
     * @dev Uses the `quoteEVMDeliveryPrice` method of the wormholeRelayer contract.
     * @param targetChain ID of the destination chain on Wormhole.
     * @param _gasLimit Gas limit for the transaction on the destination chain.
     * @return cost Estimated fee for the operation.
     */
    function estimateGasForWormhole(
        uint16 targetChain,
        uint256 _gasLimit
    ) external view returns (uint256 cost);

    /// ------------------------------------------------------------------------------------- \\\
}