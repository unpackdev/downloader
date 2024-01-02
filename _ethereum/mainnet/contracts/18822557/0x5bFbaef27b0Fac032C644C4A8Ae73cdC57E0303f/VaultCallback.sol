// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./DataTypesPeerToPeer.sol";
import "./Errors.sol";
import "./IVaultCallback.sol";

abstract contract VaultCallback is IVaultCallback {
    address public immutable borrowerGateway;

    constructor(address _borrowerGateway) {
        if (_borrowerGateway == address(0)) {
            revert Errors.InvalidAddress();
        }
        borrowerGateway = _borrowerGateway;
    }

    function repayCallback(
        DataTypesPeerToPeer.Loan calldata loan,
        bytes calldata data
    ) external {
        if (msg.sender != borrowerGateway) {
            revert Errors.InvalidSender();
        }
        _repayCallback(loan, data);
    }

    function _repayCallback(
        DataTypesPeerToPeer.Loan calldata loan,
        bytes calldata data
    ) internal virtual {} // solhint-disable no-empty-blocks
}
