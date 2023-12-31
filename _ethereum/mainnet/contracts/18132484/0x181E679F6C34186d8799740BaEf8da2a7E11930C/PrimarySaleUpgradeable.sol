// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Initializable.sol";
import "./IPrimarySaleUpgradeable.sol";

abstract contract PrimarySaleUpgradeable is IPrimarySaleUpgradeable, Initializable {
    /// @dev The address that receives all primary sales value.
    address internal _recipient;

    modifier onlySale() {
        if (msg.sender != _recipient) revert PrimarySale__Unauthorized();
        _;
    }

    function __PrimarySale_init(address recipient_) internal onlyInitializing {
        __PrimarySale_init_unchained(recipient_);
    }

    function __PrimarySale_init_unchained(address recipient_) internal onlyInitializing {
        _setupPrimarySaleRecipient(recipient_);
    }

    /// @dev Returns primary sale recipient address.
    function primarySaleRecipient() external view override returns (address) {
        return _recipient;
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setupPrimarySaleRecipient(address saleRecipient_) external onlySale {
        _setupPrimarySaleRecipient(saleRecipient_);
    }

    function _setupPrimarySaleRecipient(address saleRecipient_) internal {
        _recipient = saleRecipient_;
        emit PrimarySaleRecipientUpdated(saleRecipient_);
    }

    uint256[49] private __gap;
}
