// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Swapper.sol";
import "./ReentrancyGuard.sol";
import "./IConnext.sol";
import "./StructInterface.sol";
import "./LibSwap.sol";
import "./LibAsset.sol";
import "./LibBridge.sol";
import "./LibFeeCollector.sol";
import "./GenericErrors.sol";

contract ConnextFacet is Swapper, ReentrancyGuard, StructInterface {

    IConnext private immutable connext;

    struct ConnextData {
        uint256 relayerFee;
        uint256 slippage;
        uint32 destDomainId;
        bool isFeeNative;
    }

    struct Swap {
        uint256 amount;
        uint256 minAmount;
        address weth;
        address partner;
    }

    event Bridged(address sender, uint256 chainId, address tokenBridged, uint256 tokensBridged, bytes payload);

    constructor (IConnext _connext) {
        connext = _connext;
    }

    function bridgeTokensConnext(
        uint256 _amount,
        address _partner,
        ConnextData calldata _connextData,
        BridgeData calldata _bridgeData,
        bytes calldata _destSwaps
    ) 
        external 
        payable 
        nonReentrant
    {
        if (_amount == 0) revert InvalidAmount();

        LibAsset.depositAsset(
            _bridgeData.sendingAsset,
            _amount
        );

        uint256 tokensBridged = _bridge(_amount, _partner, _bridgeData, _connextData);

        bytes memory payload = _destSwaps.length > 0
            ? abi.encodePacked(_bridgeData.receiver, _destSwaps) 
            : abi.encodePacked(_bridgeData.receiver);

        emit Bridged(msg.sender, _bridgeData.chainId, _bridgeData.sendingAsset, tokensBridged, payload);
    }

    function swapAndBridgeTokensConnext(
        Swap calldata _swapData,
        ConnextData calldata _connextData, 
        BridgeData calldata _bridgeData,
        LibSwap.SwapData[] calldata _srcSwaps,
        bytes calldata _destSwaps
    ) 
        external 
        payable 
        nonReentrant
    {
        if (_swapData.amount == 0) revert InvalidAmount();

        uint256 receivedAmount = _swap(
            _swapData.amount, 
            _swapData.minAmount, 
            _swapData.weth, 
            _srcSwaps, 
            _connextData.isFeeNative ? _connextData.relayerFee : 0, 
            _swapData.partner
        );

        if (_srcSwaps[_srcSwaps.length - 1].toToken != _bridgeData.sendingAsset) revert InformationMismatch();

        receivedAmount = _bridge(receivedAmount, _swapData.partner, _bridgeData, _connextData);

        bytes memory payload = _destSwaps.length > 0 
            ? abi.encodePacked(_bridgeData.receiver, _destSwaps) 
            : abi.encodePacked(_bridgeData.receiver);

        emit Bridged(msg.sender, _bridgeData.chainId, _bridgeData.sendingAsset, receivedAmount, payload);
    }

    function _bridge(
        uint256 _amount, 
        address _partner, 
        BridgeData calldata _bridgeData, 
        ConnextData calldata _connextData
    ) private returns (uint256 tokensBridged) {
        address contractAddressTo = LibBridge.getContractTo(_bridgeData.chainId);
        if (contractAddressTo == address(0)) revert UnsupportedChainId(_bridgeData.chainId);
        (uint256 crosschainFee, uint256 minFee) = LibBridge.getFeeInfo(_bridgeData.chainId);

        if (minFee == 0) revert UnsupportedChainId(_bridgeData.chainId);
        if (!LibBridge.getApprovedToken(_bridgeData.sendingAsset)) revert TokenNotSupported();
        
        tokensBridged = LibFeeCollector.takeCrosschainFee(
            _amount, 
            _partner, 
            _bridgeData.sendingAsset,
            crosschainFee,
            minFee
        );

        LibAsset.approveERC20(
            IERC20(_bridgeData.sendingAsset),
            address(connext),
            tokensBridged
        );

        if (_connextData.isFeeNative) {
            connext.xcall{ value: _connextData.relayerFee}(
                _connextData.destDomainId,
                contractAddressTo,
                _bridgeData.sendingAsset,
                contractAddressTo,
                tokensBridged,
                _connextData.slippage,
                ""
            );
        } else {
            connext.xcall(
                _connextData.destDomainId,
                contractAddressTo,
                _bridgeData.sendingAsset,
                contractAddressTo,
                tokensBridged - _connextData.relayerFee,
                _connextData.slippage,
                "",
                _connextData.relayerFee
            );
        }
    }
}