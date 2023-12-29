// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./IAdaptor.sol";
import "./ICrossChainPool.sol";

abstract contract Adaptor is
    IAdaptor,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    ICrossChainPool public crossChainPool;

    uint256 private _used;

    /// @notice whether the token is valid
    /// @dev wormhole chainId => token address => bool
    /// Instead of a security feature, this is a sanity check in case user uses an invalid token address
    mapping(uint256 => mapping(address => bool)) public validToken;

    uint256[50] private __gap;

    event BridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 sequence
    );
    event LogError(uint256 emitterChainId, address emitterAddress, bytes data);

    error ADAPTOR__CONTRACT_NOT_TRUSTED();
    error ADAPTOR__INVALID_TOKEN();

    function __Adaptor_init(ICrossChainPool _crossChainPool) internal virtual onlyInitializing {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();

        crossChainPool = _crossChainPool;
    }

    /**
     * @dev Nonce must be non-zero, otherwise wormhole will revert the message
     */
    function bridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 deliveryGasLimit
    ) external payable override returns (uint256 sequence) {
        require(msg.sender == address(crossChainPool), 'Adaptor: not authorized');
        _isValidToken(toChain, toToken);

        sequence = _bridgeCreditAndSwapForTokens(
            toToken,
            toChain,
            fromAmount,
            minimumToAmount,
            receiver,
            receiverValue,
            deliveryGasLimit
        );

        // (emitterChainID, emitterAddress, sequence) is used to retrive the generated VAA from the Guardian Network and for tracking
        emit BridgeCreditAndSwapForTokens(toToken, toChain, fromAmount, minimumToAmount, receiver, sequence);
    }

    /**
     * Internal functions
     */

    function _bridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 deliveryGasLimit
    ) internal virtual returns (uint256 sequence);

    function _isValidToken(uint256 chainId, address tokenAddr) internal view {
        if (!validToken[chainId][tokenAddr]) revert ADAPTOR__INVALID_TOKEN();
    }

    function _swapCreditForTokens(
        uint256 emitterChainId,
        address emitterAddress,
        address toToken,
        uint256 creditAmount,
        uint256 minimumToAmount,
        address receiver
    ) internal returns (bool success, uint256 amount) {
        try crossChainPool.completeSwapCreditForTokens(toToken, creditAmount, minimumToAmount, receiver) returns (
            uint256 actualToAmount,
            uint256
        ) {
            return (true, actualToAmount);
        } catch (bytes memory reason) {
            // TODO: Investigate how can we decode error message from logs
            emit LogError(emitterChainId, emitterAddress, reason);
            crossChainPool.mintCredit(creditAmount, receiver);

            return (false, creditAmount);
        }
    }

    function _encode(
        address toToken,
        uint256 creditAmount,
        uint256 minimumToAmount,
        address receiver
    ) internal pure returns (bytes memory) {
        require(toToken != address(0), 'toToken cannot be zero');
        require(receiver != address(0), 'receiver cannot be zero');
        require(creditAmount != uint256(0), 'creditAmount cannot be zero');
        require(toToken != receiver, 'toToken cannot be receiver');

        return abi.encode(toToken, creditAmount, minimumToAmount, receiver);
    }

    function _decode(
        bytes memory encoded
    ) internal pure returns (address toToken, uint256 creditAmount, uint256 minimumToAmount, address receiver) {
        require(encoded.length == 128, 'byte length must be 128');

        (toToken, creditAmount, minimumToAmount, receiver) = abi.decode(encoded, (address, uint256, uint256, address));

        require(toToken != address(0), 'toToken cannot be zero');
        require(receiver != address(0), 'receiver cannot be zero');

        require(creditAmount != uint256(0), 'creditAmount cannot be zero');
        require(toToken != receiver, 'toToken cannot be receiver');
    }

    /**
     * Permisioneed functions
     */

    function approveToken(uint256 wormholeChainId, address tokenAddr) external onlyOwner {
        require(!validToken[wormholeChainId][tokenAddr]);
        validToken[wormholeChainId][tokenAddr] = true;
    }

    function revokeToken(uint256 wormholeChainId, address tokenAddr) external onlyOwner {
        require(validToken[wormholeChainId][tokenAddr]);
        validToken[wormholeChainId][tokenAddr] = false;
    }
}
