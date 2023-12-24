// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import "./Adaptor.sol";
import "./IWormholeReceiver.sol";
import "./IWormholeRelayer.sol";
import "./IWormhole.sol";

/// @title WormholeAdaptor
/// @notice `WormholeAdaptor` uses the generic relayer of wormhole to send message across different networks
contract WormholeAdaptor is IWormholeReceiver, Adaptor {
    struct CrossChainPoolData {
        uint256 creditAmount;
        address toToken;
        uint256 minimumToAmount;
        address receiver;
    }

    IWormholeRelayer public relayer;
    IWormhole public wormhole;

    /// @dev wormhole chainId => adaptor address
    mapping(uint16 => address) public adaptorAddress;

    /// @dev hash => is message delivered
    mapping(bytes32 => bool) public deliveredMessage;

    event UnknownEmitter(address emitterAddress, uint16 sourceChain);
    event SetAdaptorAddress(uint16 wormholeChainId, address adaptorAddress);

    error ADAPTOR__MESSAGE_ALREADY_DELIVERED(bytes32 _hash);

    function initialize(
        IWormholeRelayer _relayer,
        IWormhole _wormhole,
        ICrossChainPool _crossChainPool
    ) public virtual initializer {
        relayer = _relayer;
        wormhole = _wormhole;

        __Adaptor_init(_crossChainPool);
    }

    /**
     * External/public functions
     */

    /**
     * @notice A convinience function to redeliver
     * @dev Redeliver could actually be invoked permisionless on any of the chain that wormhole supports
     * Delivery fee attached to the txn should be done off-chain via `WormholeAdaptor.estimateRedeliveryFee` to reduce gas cost
     *
     * *** This will only be able to succeed if the following is true **
     *         - (For EVM_V1) newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - (For EVM_V1) newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     */
    function requestResend(
        uint16 sourceChain, // wormhole chain ID
        uint64 sequence, // wormhole message sequence
        uint16 targetChain, // wormhole chain ID
        uint256 newReceiverValue,
        uint256 newGasLimit
    ) external payable {
        VaaKey memory deliveryVaaKey = VaaKey(
            sourceChain,
            _ethAddrToWormholeAddr(address(relayer)), // use the relayer address
            sequence
        );
        relayer.resendToEvm{value: msg.value}(
            deliveryVaaKey, // VaaKey memory deliveryVaaKey
            targetChain, // uint16 targetChain
            newReceiverValue, // uint256 newReceiverValue
            newGasLimit, // uint256 newGasLimit
            relayer.getDefaultDeliveryProvider() // address newDeliveryProviderAddress
        );
    }

    /**
     * Permisioneed functions
     */

    /**
     * @dev core relayer is assumed to be trusted so re-entrancy protection is not required
     * Note: This function should NOT throw; Otherwise it will result in a delivery failure
     * Assumptions to the wormhole relayer:
     *   - The message should deliver typically within 5 minutes
     *   - Unused gas should be refunded to the refundAddress
     *   - The target chain id and target contract address is verified
     * Things to be aware of:
     *   - VAA are not verified, order of message can be changed
     *   - deliveries can potentially performed multiple times
     * (ref: https://book.wormhole.com/technical/evm/relayer.html#delivery-failures)
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory /* additionalVaas */,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable override {
        // Only the core relayer can invoke this function
        // Verify the sender as there are trust assumptions to the generic relayer
        require(msg.sender == address(relayer), 'not authorized');

        // only accept messages from a trusted chain & contract
        // Assumption: the core relayer must verify the target chain ID and target contract address
        address sourAddr = _wormholeAddrToEthAddr(sourceAddress);
        if (adaptorAddress[sourceChain] != sourAddr) {
            emit UnknownEmitter(sourAddr, sourceChain);
            return;
        }

        // Important note: While Wormhole is in beta, the selected RelayProvider can potentially
        // reorder, omit, or mix-and-match VAAs if they were to behave maliciously
        _recordMessageHash(deliveryHash);

        (address toToken, uint256 creditAmount, uint256 minimumToAmount, address receiver) = _decode(payload);

        // transfer receiver value to the `receiver`
        (bool success, ) = receiver.call{value: msg.value}(new bytes(0));
        require(success, 'WormholeAdaptor: failed to send receiver value');

        _swapCreditForTokens(sourceChain, sourAddr, toToken, creditAmount, minimumToAmount, receiver);
    }

    function setAdaptorAddress(uint16 wormholeChainId, address addr) external onlyOwner {
        adaptorAddress[wormholeChainId] = addr;
        emit SetAdaptorAddress(wormholeChainId, addr);
    }

    /**
     * Internal functions
     */

    function _recordMessageHash(bytes32 _hash) internal {
        // revert if the message is already delivered
        if (deliveredMessage[_hash]) revert ADAPTOR__MESSAGE_ALREADY_DELIVERED(_hash);
        deliveredMessage[_hash] = true;
    }

    function _bridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain, // wormhole chain ID
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 deliveryGasLimit
    ) internal override returns (uint256 sequence) {
        // Delivery fee attached to the txn is done off-chain via `estimateDeliveryFee` to reduce gas cost
        // Unused `deliveryGasLimit` is sent to the `refundAddress` (`receiver`).

        require(toChain <= type(uint16).max, 'invalid chain ID');

        // (emitterChainID, emitterAddress, sequence) is used to retrive the generated VAA from the Guardian Network and for tracking
        sequence = relayer.sendPayloadToEvm{value: msg.value}(
            uint16(toChain), // uint16 targetChain
            adaptorAddress[uint16(toChain)], // address targetAddress
            _encode(toToken, fromAmount, minimumToAmount, receiver), // bytes memory payload
            receiverValue, // uint256 receiverValue
            deliveryGasLimit, // uint256 gasLimit
            uint16(toChain), // uint16 refundChain
            receiver // address refundAddress
        );
    }

    /**
     * Read-only functions
     */

    /**
     * @notice Estimate the amount of message value required to deliver a message with given `deliveryGasLimit` and `receiveValue`
     * A buffer should be added to `deliveryGasLimit` in case the amount of gas required is higher than the expectation
     * @param toChain wormhole chain ID
     * @param deliveryGasLimit gas limit of the callback function on the designated network
     * @param receiverValue target amount of gas token to receive
     * @dev Note that this function may fail if the value requested is too large. Using deliveryGasLimit 200000 is typically enough
     */
    function estimateDeliveryFee(
        uint16 toChain,
        uint256 receiverValue,
        uint32 deliveryGasLimit
    ) external view returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused) {
        return relayer.quoteEVMDeliveryPrice(toChain, receiverValue, deliveryGasLimit);
    }

    function estimateRedeliveryFee(
        uint16 toChain,
        uint256 receiverValue,
        uint32 deliveryGasLimit
    ) external view returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused) {
        return relayer.quoteEVMDeliveryPrice(toChain, receiverValue, deliveryGasLimit);
    }

    function _wormholeAddrToEthAddr(bytes32 addr) internal pure returns (address) {
        require(address(uint160(uint256(addr))) != address(0), 'addr bytes cannot be zero');
        return address(uint160(uint256(addr)));
    }

    function _ethAddrToWormholeAddr(address addr) internal pure returns (bytes32) {
        require(addr != address(0), 'addr cannot be zero');
        return bytes32(uint256(uint160(addr)));
    }
}
