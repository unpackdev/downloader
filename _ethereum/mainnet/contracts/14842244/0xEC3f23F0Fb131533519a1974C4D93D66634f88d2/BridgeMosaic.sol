// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IBridge.sol";
import "./IMosaicVault.sol";

contract BridgeMosaic is IBridge {
    IMosaicVault public mosaicVault;

    constructor(address _mosaicVault) {
        require(_mosaicVault != address(0), "Invalid address");
        mosaicVault = IMosaicVault(_mosaicVault);
    }

    function transferERC20(
        uint256 destinationNetworkId,
        address tokenIn,
        uint256 amount,
        address destinationAddress,
        bytes calldata data
    ) external override {
        SafeERC20.safeIncreaseAllowance(IERC20(tokenIn), address(mosaicVault), amount);

        (
            uint256 maxTransferDelay,
            address tokenOut,
            uint256 remoteAmmId,
            uint256 amountOutMin,
            bool swapToNative
        ) = abi.decode(data, (uint256, address, uint256, uint256, bool));

        mosaicVault.transferERC20ToLayer(
            amount,
            tokenIn,
            destinationAddress,
            destinationNetworkId,
            maxTransferDelay,
            tokenOut,
            remoteAmmId,
            amountOutMin,
            swapToNative
        );
    }

    function transferNative(
        uint256 destinationNetworkId,
        uint256 amount,
        address destinationAddress,
        bytes calldata data
    ) external payable override {
        (
            uint256 _maxTransferDelay,
            address _tokenOut,
            uint256 _remoteAmmId,
            uint256 _amountOutMin,
            bool _swapToNative
        ) = abi.decode(data, (uint256, address, uint256, uint256, bool));

        mosaicVault.transferETHToLayer{value: msg.value}(
            destinationAddress,
            destinationNetworkId,
            _maxTransferDelay,
            _tokenOut,
            _remoteAmmId,
            _amountOutMin,
            _swapToNative
        );
    }
}
