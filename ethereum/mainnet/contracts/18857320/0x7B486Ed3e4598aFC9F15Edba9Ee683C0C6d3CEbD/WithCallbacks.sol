// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./ILoanCallback.sol";
import "./BaseLoan.sol";

abstract contract WithCallbacks is BaseLoan {
    struct Taxes {
        uint128 buyTax;
        uint128 sellTax;
    }

    event WhitelistedCallbackContractAdded(address contractAdded, Taxes tax);

    event WhitelistedCallbackContractRemoved(address contractRemoved);

    mapping(address => Taxes) private _callbackTaxes;

    constructor(string memory _name, address __currencyManager, address __collectionManager)
        BaseLoan(_name, __currencyManager, __collectionManager)
    {}

    /// @notice Add a whitelisted callback contract / update an existing one with different taxes.
    /// @param _contract Address of the contract.
    function addWhitelistedCallbackContract(address _contract, Taxes calldata _tax) external onlyOwner {
        _checkAddressNotZero(_contract);
        if (_tax.buyTax > _PRECISION || _tax.sellTax > _PRECISION) {
            revert InvalidValueError();
        }
        _isWhitelistedCallbackContract[_contract] = true;
        _callbackTaxes[_contract] = _tax;

        emit WhitelistedCallbackContractAdded(_contract, _tax);
    }

    /// @notice Remove a whitelisted callback contract.
    /// @param _contract Address of the contract.
    function removeWhitelistedCallbackContract(address _contract) external onlyOwner {
        _isWhitelistedCallbackContract[_contract] = false;
        delete _callbackTaxes[_contract];

        emit WhitelistedCallbackContractRemoved(_contract);
    }

    /// @return Whether a callback contract is whitelisted
    function isWhitelistedCallbackContract(address _contract) external view returns (bool) {
        return _isWhitelistedCallbackContract[_contract];
    }

    /// @notice Handle the afterPrincipalTransfer callback.
    /// @param _loan Loan.
    /// @param _callbackData Callback data.
    /// @param _fee Fee.
    /// @return buyTax
    function _handleAfterPrincipalTransferCallback(
        IMultiSourceLoan.Loan memory _loan,
        bytes memory _callbackData,
        uint256 _fee
    ) internal returns (uint128) {
        if (_noCallback(_callbackData)) {
            return 0;
        }
        if (
            !_isWhitelistedCallbackContract[msg.sender]
                || ILoanCallback(msg.sender).afterPrincipalTransfer(_loan, _fee, _callbackData)
                    != ILoanCallback.afterPrincipalTransfer.selector
        ) {
            revert ILoanCallback.InvalidCallbackError();
        }
        return _callbackTaxes[msg.sender].buyTax;
    }

    /// @notice Handle the afterNFTTransfer callback.
    /// @param _loan Loan.
    /// @param _callbackData Callback data.
    /// @return sellTax
    function _handleAfterNFTTransferCallback(IMultiSourceLoan.Loan memory _loan, bytes calldata _callbackData)
        internal
        returns (uint128)
    {
        if (_noCallback(_callbackData)) {
            return 0;
        }
        if (
            !_isWhitelistedCallbackContract[msg.sender]
                || ILoanCallback(msg.sender).afterNFTTransfer(_loan, _callbackData)
                    != ILoanCallback.afterNFTTransfer.selector
        ) {
            revert ILoanCallback.InvalidCallbackError();
        }
        return _callbackTaxes[msg.sender].sellTax;
    }

    function _noCallback(bytes memory _callbackData) private pure returns (bool) {
        return _callbackData.length == 0;
    }
}
