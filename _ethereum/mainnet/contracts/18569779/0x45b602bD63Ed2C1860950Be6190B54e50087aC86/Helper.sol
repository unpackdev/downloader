// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "./AccessControl.sol";
import "./Ownable2Step.sol";
import "./Initializable.sol";

error InvalidAdminAndOwnerAddress();

library CommonFunction {
    function _defaultContractURI(string memory baseContractURI_) internal view returns (string memory) {
        return
            bytes(baseContractURI_).length > 0
                ? string(abi.encodePacked(baseContractURI_, Strings.toHexString(uint256(uint160(address(this))), 20)))
                : "";
    }
}

library CommonError {
    error CannotBeZeroAddress();
    error CannotIncreaseMaxSupply();
    error CannotUpdatePermanentURI();
    error NotApprovedNorOwner();
    error ValueCannotBeZero();
    error ValueExceedsMaxSupply();
    error ValueBelowCurrentSupply();
    error InsufficientPayment();
    error InvalidPaymentAmount();
    error InvalidVoucher();
    error TokenAlreadyExists();
    error TokenNonExistent();
    error TransferNotAllowed();
}

contract CommonAccess is Initializable, AccessControl, Ownable2Step {
    function initialize(address admin_, address owner_) public virtual onlyInitializing {
        if (admin_ == address(0) && owner_ == address(0)) {
            revert("invalidadminowner");
        }

        if (admin_ != address(0)) _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        if (owner_ != address(0)) {
            _transferOwnership(owner_);
        } else {
            _transferOwnership(admin_);
        }
    }

    /**
     * @dev adminOrOwnerOnly checks if msg.sender is either has an admin role or is owner the contract
     */
    modifier adminOrOwnerOnly() {
        if (owner() != _msgSender()) {
            _checkRole(DEFAULT_ADMIN_ROLE);
        }
        _;
    }

    function grantAdminRole(address account) external onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function revokeAdminRole(address account) external onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }
}

contract CommonSoulBound is Initializable {
    bool private _SOULBOUND;

    event SoulBoundToken();

    function initialize(bool soulbound_) public virtual onlyInitializing {
        _SOULBOUND = soulbound_;
        if (_SOULBOUND) emit SoulBoundToken();
    }

    /**
     * @dev isTransferAllowed checks if SOULBOUND setting is enable, if yes, diable all transferability of tokens.
     */
    modifier isTransferAllowed() {
        if (_SOULBOUND) revert CommonError.TransferNotAllowed();
        _;
    }
}
