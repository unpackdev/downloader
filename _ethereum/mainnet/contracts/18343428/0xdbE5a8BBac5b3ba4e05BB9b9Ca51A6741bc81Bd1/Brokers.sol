// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BrokersStorage.sol";
import "./BrokersSignatureUtils.sol";
import "./BrokersTokenTransferrer.sol";
import "./DataTypes.sol";
import "./Ownable.sol";

/// @title NF3 OTC Broking Protocol
/// @author NF3 Exchange
/// @notice This contract inherits from IBroke interface.
/// @dev This contract is for brokers who are acting between users for trust trading.
/// @dev All trades between users are done by trusted third party(brokers) and brokers
/// @dev Get the fee from both sides whenever swapping assets.
contract Brokers is Ownable, BrokersTokenTransferrer, BrokersSignatureUtils {
    /// -----------------------------------------------------------------------
    /// Broker Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IBrokers
    function swap(
        TradeInfo calldata tradeInfo,
        bytes memory makerSignature,
        bool makerContra,
        bytes memory takerSignature,
        bool takerContra
    ) external override {
        // sanity checks on input
        _swapSanityChecks(tradeInfo, makerSignature, takerSignature);

        // Transfer maker fee if no contra
        if (!makerContra) {
            _transferFee(tradeInfo.maker, tradeInfo.makerFees);
        }

        // Transfer maker assets
        _transferAssets(
            tradeInfo.makerAssets,
            takerContra,
            tradeInfo.takerFees,
            tradeInfo.maker,
            tradeInfo.taker
        );

        // Transfer taker fee if no contract
        if (!takerContra) {
            _transferFee(tradeInfo.taker, tradeInfo.takerFees);
        }

        // Transfer taker assets
        _transferAssets(
            tradeInfo.takerAssets,
            makerContra,
            tradeInfo.makerFees,
            tradeInfo.taker,
            tradeInfo.maker
        );

        // Set both parties' nonce.
        _setNonce(tradeInfo.maker, tradeInfo.makerNonce);
        _setNonce(tradeInfo.taker, tradeInfo.takerNonce);

        emit BrokerSwapped(tradeInfo, _msgSender());
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @dev helper function to perform sanity checks while swapping assets
    function _swapSanityChecks(
        TradeInfo calldata _trade,
        bytes memory _makerSignature,
        bytes memory _takerSignature
    ) internal view {
        // verify signatures
        _verifyTradeInfoSignature(_trade, _makerSignature, _takerSignature);

        // check if called by the correct broker
        _checkBroker(
            _msgSender(),
            _trade.makerFees.broker,
            _trade.takerFees.broker
        );

        // check if nonces are correct
        _checkNonce(_trade.maker, _trade.makerNonce);
        _checkNonce(_trade.taker, _trade.takerNonce);

        // check if trade expired
        _checkExpiration(_trade.duration);
    }

    /// @dev Check if the nonce is in correct status.
    /// @param _owner Owner address
    /// @param _nonce Nonce value
    function _checkNonce(address _owner, uint256 _nonce) internal view {
        if (getNonce(_owner, _nonce)) {
            revert BrokersError(BrokersErrorCodes.INVALID_NONCE);
        }
    }

    /// @dev Check the asset expiration.
    /// @param _duration Trade expiration
    function _checkExpiration(uint256 _duration) internal view {
        if (_duration < block.timestamp) {
            revert BrokersError(BrokersErrorCodes.TIME_HAS_EXPIRED);
        }
    }

    /// @dev Check if the caller is valid broker who both parties chose.
    /// @param _caller Caller address
    /// @param _userBroker1 First user's broker
    /// @param _userBroker2 Second user's broker
    function _checkBroker(
        address _caller,
        address _userBroker1,
        address _userBroker2
    ) internal pure {
        if (_caller != _userBroker1 || _caller != _userBroker2) {
            revert BrokersError(BrokersErrorCodes.CALLER_IS_NOT_BROKER);
        }
    }
}
