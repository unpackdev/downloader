// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ONFT1155Core.sol";
import "./NonblockingLzApp.sol";
import "./IEmissionBooster.sol";
import "./ERC165.sol";

/**
 * Custom version of ONFT1155Core contract to use with MinterestNFT
 */
abstract contract MONFT1155Core is ONFT1155Core {
    function estimateSendBatchFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bool _useZro,
        bytes memory _adapterParams
    ) public view virtual override returns (uint256 nativeFee, uint256 zroFee) {
        uint256[] memory tiers = _getTiers(_tokenIds);

        bytes memory payload = abi.encode(_toAddress, _tokenIds, tiers, _amounts);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function _sendBatch(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual override {
        uint256[] memory tiers = _getTiers(_tokenIds);

        _debitFrom(_from, _dstChainId, _toAddress, _tokenIds, tiers, _amounts);
        bytes memory payload = abi.encode(_toAddress, _tokenIds, tiers, _amounts);
        if (_tokenIds.length == 1) {
            if (useCustomAdapterParams) {
                _checkGasLimit(_dstChainId, FUNCTION_TYPE_SEND, _adapterParams, NO_EXTRA_GAS);
            } else {
                require(_adapterParams.length == 0, "LzApp: _adapterParams must be empty.");
            }
            emit SendToChain(_dstChainId, _from, _toAddress, _tokenIds[0], _amounts[0]);
            _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        } else if (_tokenIds.length > 1) {
            if (useCustomAdapterParams) {
                _checkGasLimit(_dstChainId, FUNCTION_TYPE_SEND_BATCH, _adapterParams, NO_EXTRA_GAS);
            } else {
                require(_adapterParams.length == 0, "LzApp: _adapterParams must be empty.");
            }
            emit SendBatchToChain(_dstChainId, _from, _toAddress, _tokenIds, _amounts);
            _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        }
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal virtual override {
        // decode and load the toAddress
        (bytes memory toAddressBytes, uint256[] memory tokenIds, uint256[] memory tiers, uint256[] memory amounts) = abi
            .decode(_payload, (bytes, uint256[], uint256[], uint256[]));
        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        _creditTo(_srcChainId, toAddress, tokenIds, tiers, amounts);

        if (tokenIds.length == 1) {
            emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenIds[0], amounts[0]);
        } else if (tokenIds.length > 1) {
            emit ReceiveBatchFromChain(_srcChainId, _srcAddress, toAddress, tokenIds, amounts);
        }
    }

    function _getTiers(uint256[] memory _tokenIds) internal view returns (uint256[] memory) {
        uint256[] memory tiers = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tiers[i] = _getEmissionBooster().tokenTier(_tokenIds[i]);
        }
        return tiers;
    }

    function _getEmissionBooster() internal view virtual returns (IEmissionBooster);

    // Overriding unused function from ONFT1155Core
    function _debitFrom(
        address,
        uint16,
        bytes memory,
        uint256[] memory,
        uint256[] memory
    ) internal pure override {
        require(false, "Deprecated function");
    }

    // Overriding unused function from ONFT1155Core
    function _creditTo(
        uint16,
        address,
        uint256[] memory,
        uint256[] memory
    ) internal pure override {
        require(false, "Deprecated function");
    }

    // Overload functions from ONFT1155Core, add tiers parameter
    function _debitFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _tiers,
        uint256[] memory _amounts
    ) internal virtual;

    // Overload functions from ONFT1155Core, add tiers parameter
    function _creditTo(
        uint16 _srcChainId,
        address _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _tiers,
        uint256[] memory _amounts
    ) internal virtual;
}
