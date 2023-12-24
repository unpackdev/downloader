// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import "./Adaptor.sol";
import "./Ownable.sol";

contract MockAdaptor is Adaptor {
    struct CrossChainPoolData {
        uint256 creditAmount;
        address toToken;
        uint256 minimumToAmount;
        address receiver;
    }

    struct DeliverData {
        address deliverAddr;
        bytes data;
    }

    struct DeliveryRequest {
        uint256 id;
        uint16 sourceChain;
        address sourceAddress;
        uint16 targetChain;
        address targetAddress;
        DeliverData deliverData; //Has the gas limit to execute with
    }

    uint16 public chainId;
    uint256 public nonceCounter;

    // nonce => message
    mapping(uint256 => DeliveryRequest) public messages;

    // fromChain => nonce => processed
    mapping(uint256 => mapping(uint256 => bool)) public messageDelivered;

    function initialize(uint16 _mockChainId, ICrossChainPool _crossChainPool) external virtual initializer {
        __Adaptor_init(_crossChainPool);

        chainId = _mockChainId;
        nonceCounter = 1; // use non-zero value
    }

    function _bridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 gasLimit
    ) internal override returns (uint256 trackingId) {
        CrossChainPoolData memory crossChainPoolData = CrossChainPoolData({
            creditAmount: fromAmount,
            toToken: toToken,
            minimumToAmount: minimumToAmount,
            receiver: receiver
        });

        bytes memory data = abi.encode(crossChainPoolData);
        DeliverData memory deliverData = DeliverData({deliverAddr: address(0), data: data});
        uint256 nonce = nonceCounter++;
        messages[nonce] = DeliveryRequest({
            id: nonce,
            sourceChain: chainId,
            sourceAddress: address(this),
            targetChain: uint16(toChain),
            targetAddress: address(0),
            deliverData: deliverData
        });
        return (trackingId << 16) + nonce;
    }

    /* Message receiver, should be invoked by the bridge */

    function deliver(
        uint256 id,
        uint16 fromChain,
        address fromAddr,
        uint16 targetChain,
        address targetAddress,
        DeliverData calldata deliverData
    ) external returns (bool success, uint256 amount) {
        require(targetChain == chainId, 'targetChain invalid');
        require(!messageDelivered[fromChain][id], 'message delivered');

        messageDelivered[fromChain][id] = true;

        CrossChainPoolData memory data = abi.decode(deliverData.data, (CrossChainPoolData));
        return
            _swapCreditForTokens(
                fromChain,
                fromAddr,
                data.toToken,
                data.creditAmount,
                data.minimumToAmount,
                data.receiver
            );
    }

    function faucetCredit(uint256 creditAmount) external {
        crossChainPool.mintCredit(creditAmount, msg.sender);
    }

    function encode(
        address toToken,
        uint256 creditAmount,
        uint256 minimumToAmount,
        address receiver
    ) external pure returns (bytes memory) {
        return _encode(toToken, creditAmount, minimumToAmount, receiver);
    }

    function decode(
        bytes memory encoded
    ) external pure returns (address toToken, uint256 creditAmount, uint256 minimumToAmount, address receiver) {
        return _decode(encoded);
    }
}
