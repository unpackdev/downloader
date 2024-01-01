// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ProxyOFT.sol";

interface IOwnable {
    function owner() external view returns (address);
}

contract TokenProxy is ProxyOFT {
    uint256 public fee;

    event WithdrawNative(address indexed user, uint256 amount);
    event FeeChanged(uint256 currentFee, uint256 newFee);

    error NotOwner();
    error NativeTransferFailed();

    modifier onlyAdmin() {
        if(msg.sender != _getOwner()) {
            revert NotOwner();
        }
        _;
    }

    constructor(
        address _token,
        address _lzEndpoint,
        uint256 _nativeFee
    ) ProxyOFT(_lzEndpoint, _token) {
        if (msg.sender != _getOwner()) {
            revert NotOwner();
        }
        fee = _nativeFee;
    }

    function _getOwner() internal view returns(address) {
        return IOwnable(address(innerToken)).owner();
    }

    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) public view virtual override returns (uint256, uint256) {
        (uint256 nativeFee, uint256 zroFee) = super.estimateSendFee(_dstChainId, _toAddress, _amount, _useZro, _adapterParams);
        return (nativeFee + fee, zroFee);
    }

    function _send(address _from, uint16 _dstChainId, bytes memory _toAddress, uint _amount, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) internal virtual override {
        _checkAdapterParams(_dstChainId, PT_SEND, _adapterParams, NO_EXTRA_GAS);

        uint amount = _debitFrom(_from, _dstChainId, _toAddress, _amount);

        bytes memory lzPayload = abi.encode(PT_SEND, _toAddress, amount);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value - fee);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function withdrawEth() external onlyAdmin {
        uint256 amount = address(this).balance;
        (bool success,) = payable(msg.sender).call{value : amount}("");
        if (!success) {
            revert NativeTransferFailed();
        }
        emit WithdrawNative(msg.sender, amount);
    }

    function setNativeFee(uint256 fee_) external onlyAdmin {
        emit FeeChanged(fee, fee_);
        fee = fee_;
    }
}
