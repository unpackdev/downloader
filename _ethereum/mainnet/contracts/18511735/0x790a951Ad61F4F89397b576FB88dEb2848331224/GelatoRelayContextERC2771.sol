// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./GelatoRelayERC2771Base.sol";
import "./TokenUtils.sol";

uint256 constant _FEE_COLLECTOR_START = 92; // offset: address + address + uint256 + address
uint256 constant _FEE_TOKEN_START = 72; // offset: address + uint256 + address
uint256 constant _FEE_START = 52; // offset: uint256 + address
uint256 constant _MSG_SENDER_START = 20; // offset: address

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContextERC2771
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeCollectorRelayContextERC2771()
    pure
    returns (address feeCollector)
{
    assembly {
        feeCollector := shr(
            96,
            calldataload(sub(calldatasize(), _FEE_COLLECTOR_START))
        )
    }
}

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContextERC2771
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeTokenRelayContextERC2771() pure returns (address feeToken) {
    assembly {
        feeToken := shr(96, calldataload(sub(calldatasize(), _FEE_TOKEN_START)))
    }
}

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContextERC2771
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeRelayContextERC2771() pure returns (uint256 fee) {
    assembly {
        fee := calldataload(sub(calldatasize(), _FEE_START))
    }
}

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContextERC2771
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getMsgSenderRelayContextERC2771() pure returns (address _msgSender) {
    assembly {
        _msgSender := shr(
            96,
            calldataload(sub(calldatasize(), _MSG_SENDER_START))
        )
    }
}

/**
 * @dev Context variant with feeCollector, feeToken, fee, _msgSender appended to msg.data
 * Expects calldata encoding:
    abi.encodePacked(
        _data,
        _feeCollector,
        _feeToken,
        _fee,
        _msgSender
    );
 * Therefore, we're expecting 20 + 20 + 32 + 20 = 92 bytes to be appended to normal msgData
 *     feeCollector: - 92 bytes
 *     feeToken: - 72 bytes
 *     fee: - 52 bytes
 *     _msgSender: - 20 bytes
 */

/// @dev Do not use with GelatoRelayFeeCollectorERC2771 - pick only one
abstract contract GelatoRelayContextERC2771 is GelatoRelayERC2771Base {
    using TokenUtils for address;

    // DANGER! Only use with onlyGelatoRelayERC2771, onlyGelatoRelayConcurrentERC2771,
    // `_isGelatoRelayERC2771` or `_isGelatoRelayConcurrentERC2771` checks
    function _transferRelayFee() internal {
        _getFeeToken().transfer(_getFeeCollector(), _getFee());
    }

    // DANGER! Only use with onlyGelatoRelayERC2771, onlyGelatoRelayConcurrentERC2771,
    // `_isGelatoRelayERC2771` or `_isGelatoRelayConcurrentERC2771` checks
    function _transferRelayFeeCapped(uint256 _maxFee) internal {
        uint256 fee = _getFee();
        require(
            fee <= _maxFee,
            "GelatoRelayContextERC2771._transferRelayFeeCapped: maxFee"
        );
        _getFeeToken().transfer(_getFeeCollector(), fee);
    }

    // DANGER! Only use with onlyGelatoRelayERC2771, onlyGelatoRelayConcurrentERC2771,
    // `_isGelatoRelayERC2771` or `_isGelatoRelayConcurrentERC2771` checks
    function _transferFromRelayFee() internal {
        _getFeeToken().transferFrom(
            _getMsgSender(),
            _getFeeCollector(),
            _getFee()
        );
    }

    // DANGER! Only use with onlyGelatoRelayERC2771, onlyGelatoRelayConcurrentERC2771,
    // `_isGelatoRelayERC2771` or `_isGelatoRelayConcurrentERC2771` checks
    function _transferFromRelayFeeCapped(uint256 _maxFee) internal {
        uint256 fee = _getFee();
        require(
            fee <= _maxFee,
            "GelatoRelayContextERC2771._transferFromRelayFeeCapped: maxFee"
        );
        _getFeeToken().transferFrom(_getMsgSender(), _getFeeCollector(), fee);
    }

    // DANGER! Only use with onlyGelatoRelayERC2771, onlyGelatoRelayConcurrentERC2771,
    // `_isGelatoRelayERC2771` or `_isGelatoRelayConcurrentERC2771` checks
    function _transferFromRelayFeeCappedWithPermit(
        uint256 _maxFee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        uint256 fee = _getFee();
        require(
            fee <= _maxFee,
            "GelatoRelayContextERC2771._transferFromRelayFeeCappedWithPermit: maxFee"
        );

        address from = _getMsgSender();
        address token = _getFeeToken();

        token.permit(from, address(this), _maxFee, _deadline, _v, _r, _s);
        token.transferFrom(from, _getFeeCollector(), fee);
    }

    function _getMsgData() internal view virtual returns (bytes calldata) {
        return
            _isGelatoRelayERC2771(msg.sender)
                ? msg.data[:msg.data.length - _FEE_COLLECTOR_START]
                : msg.data;
    }

    function _getMsgSender() internal view virtual returns (address) {
        return
            _isGelatoRelayERC2771(msg.sender)
                ? _getMsgSenderRelayContextERC2771()
                : msg.sender;
    }

    // Only use with onlyGelatoRelayERC2771, onlyGelatoRelayConcurrentERC2771,
    // `_isGelatoRelayERC2771` or `_isGelatoRelayConcurrentERC2771` checks
    function _getFeeCollector() internal pure returns (address) {
        return _getFeeCollectorRelayContextERC2771();
    }

    // Only use with onlyGelatoRelayERC2771, onlyGelatoRelayConcurrentERC2771,
    // `_isGelatoRelayERC2771` or `_isGelatoRelayConcurrentERC2771` checks
    function _getFeeToken() internal pure returns (address) {
        return _getFeeTokenRelayContextERC2771();
    }

    // Only use with onlyGelatoRelayERC2771, onlyGelatoRelayConcurrentERC2771,
    // `_isGelatoRelayERC2771` or `_isGelatoRelayConcurrentERC2771` checks
    function _getFee() internal pure returns (uint256) {
        return _getFeeRelayContextERC2771();
    }
}
