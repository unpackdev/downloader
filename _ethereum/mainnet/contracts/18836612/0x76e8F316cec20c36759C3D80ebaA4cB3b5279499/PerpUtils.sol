// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";
import "./IWasabiPerps.sol";

library PerpUtils {
    using Address for address;

    /// @dev Pays ETH to a given address
    /// @param _amount The amount to pay
    /// @param _target The address to pay to
    function payETH(uint256 _amount, address _target) internal {
        if (_amount > 0) {
            (bool sent, ) = payable(_target).call{value: _amount}("");
            if (!sent) {
                revert IWasabiPerps.EthTransferFailed(_amount, _target);
            }
        }
    }

    /// @dev Computes the close fee for a position by looking at the position size
    /// @param _position the position size
    /// @param _netValue the net value
    /// @param _isLong whether the position is long or short
    function computeCloseFee(
        IWasabiPerps.Position calldata _position,
        uint256 _netValue,
        bool _isLong
    ) internal pure returns(uint256) {
        if (_isLong) {
            return (_position.principal + _netValue) * _position.feesToBePaid / (_position.feesToBePaid + _position.downPayment + _position.principal);
        }
        return (_position.collateralAmount + _netValue) * _position.feesToBePaid / (_position.feesToBePaid + _position.collateralAmount);
    }

    /// @dev Receives payment from a given address
    /// @param _currency the currency to receive
    /// @param _amount the amount to receive
    /// @param _wethAddress the WETH address
    /// @param _sender the address to receive from
    function receivePayment(
        address _currency,
        uint256 _amount,
        address _wethAddress,
        address _sender
    ) internal {
        if (msg.value > 0) {
            if (_currency != _wethAddress) revert IWasabiPerps.InvalidCurrency();
            if (msg.value != _amount) revert IWasabiPerps.InsufficientAmountProvided();
        } else {
            SafeERC20.safeTransferFrom(IERC20(_currency), _sender, address(this), _amount);
        }
    }

    /// @dev Wraps the whole ETH in this contract
    function wrapWETH(address _wethAddress) internal {
        IWETH weth = IWETH(_wethAddress);
        weth.deposit{value: address(this).balance}();
    }

    /// @dev Executes a given list of functions
    /// @param _marketplaceCallData List of marketplace calldata
    function executeFunctions(IWasabiPerps.FunctionCallData[] memory _marketplaceCallData) internal {
        uint256 length = _marketplaceCallData.length;
        for (uint256 i; i < length; ++i) {
            IWasabiPerps.FunctionCallData memory functionCallData = _marketplaceCallData[i];
            functionCallData.to.functionCallWithValue(functionCallData.data, functionCallData.value);
        }
    }

    /// @dev Deducts the given amount from the total amount
    /// @param _amount the amount to deduct from
    /// @param _deductAmount the amount to deduct
    /// @return remaining the remaining amount
    /// @return deducted the total deducted
    function deduct(uint256 _amount, uint256 _deductAmount) internal pure returns(uint256 remaining, uint256 deducted) {
        if (_amount > _deductAmount) {
            remaining = _amount - _deductAmount;
            deducted = _deductAmount;
        } else {
            remaining = 0;
            deducted = _amount;
        }
    }
}