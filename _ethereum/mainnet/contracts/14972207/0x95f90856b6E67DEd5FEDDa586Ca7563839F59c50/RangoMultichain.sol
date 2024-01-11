// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BaseContract.sol";
import "./IRangoMultichain.sol";
import "./RangoMultichainModels.sol";
import "./MultichainRouter.sol";

contract RangoMultichain is IRangoMultichain, BaseContract {
    event MultichainBridge(
        RangoMultichainModels.MultichainBridgeType _actionType,
        address _fromToken,
        address _underlyingToken,
        uint _inputAmount,
        address multichainRouter,
        address _receiverAddress,
        uint _receiverChainID
    );

    mapping(address => bool) public multichainRouters;


    constructor(address _nativeWrappedAddress) {
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        baseStorage.nativeWrappedAddress = _nativeWrappedAddress;
    }
    
    receive() external payable { }

    function addMultichainRouters(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            multichainRouters[_addresses[i]] = true;
        }
    }

    function removeMultichainRouters(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            delete multichainRouters[_addresses[i]];
        }
    }

    function multichainBridge(
        RangoMultichainModels.MultichainBridgeType _actionType,
        address _fromToken,
        address _underlyingToken,
        uint _inputAmount,
        address _multichainRouter,
        address _receiverAddress,
        uint _receiverChainID
    ) external override payable whenNotPaused nonReentrant {
        require(multichainRouters[_multichainRouter], 'Requested router address not whitelisted');
        if (_actionType == RangoMultichainModels.MultichainBridgeType.OUT_NATIVE) {
            require(msg.value >= _inputAmount, 'Insufficient ETH sent for OUT_NATIVE action');
            require(_fromToken == NULL_ADDRESS, 'Invalid _fromToken, it must be equal to null address');
        }

        if (_actionType != RangoMultichainModels.MultichainBridgeType.OUT_NATIVE) {
            SafeERC20.safeTransferFrom(IERC20(_fromToken), msg.sender, address(this), _inputAmount);
            approve(_fromToken, _multichainRouter, _inputAmount);
        }

        MultichainRouter router = MultichainRouter(_multichainRouter);

        if (_actionType == RangoMultichainModels.MultichainBridgeType.OUT) {
            router.anySwapOut(_underlyingToken, _receiverAddress, _inputAmount, _receiverChainID);
        } else if (_actionType == RangoMultichainModels.MultichainBridgeType.OUT_UNDERLYING) {
            router.anySwapOutUnderlying(_underlyingToken, _receiverAddress, _inputAmount, _receiverChainID);
        } else if (_actionType == RangoMultichainModels.MultichainBridgeType.OUT_NATIVE) {
            router.anySwapOutNative{value: msg.value}(_underlyingToken, _receiverAddress, _receiverChainID);
        } else {
            revert();
        }

        emit MultichainBridge(_actionType, _fromToken, _underlyingToken, _inputAmount, _multichainRouter, _receiverAddress, _receiverChainID);
    }
}