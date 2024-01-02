// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Ownable.sol";

import "./IAddressProvider.sol";
import "./IDebtController.sol";

contract AddressProvider is Ownable, IAddressProvider {
    IDebtController public debtController;
    address public feeReceiver;
    address public immutable wethAddress;

    constructor(
        IDebtController _debtController,
        address _feeReceiver,
        address _wethAddress
    ) Ownable(msg.sender) {
        debtController = _debtController;
        feeReceiver = _feeReceiver;
        wethAddress = _wethAddress;
    }

    /// @inheritdoc IAddressProvider
    function getDebtController()
        external
        view
        override
        returns (IDebtController)
    {
        return debtController;
    }

    /// @inheritdoc IAddressProvider
    function getFeeReceiver()
        external
        view
        override
        returns (address)
    {
        return feeReceiver;
    }

    /// @inheritdoc IAddressProvider
    function getWethAddress() external view returns (address) {
        return wethAddress;
    }

    /// @dev sets the debt controller
    /// @param _debtController the debt controller
    function setDebtController(IDebtController _debtController) external onlyOwner {
        debtController = _debtController;
    }

    /// @dev sets the fee controller
    /// @param _feeReceiver the fee receiver
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }
}