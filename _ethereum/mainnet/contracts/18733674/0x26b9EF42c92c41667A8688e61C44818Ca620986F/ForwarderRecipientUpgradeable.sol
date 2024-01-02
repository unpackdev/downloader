// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./IForwarderRecipientUpgradeable.sol";

error InvalidForwarder(address caller);

abstract contract ForwarderRecipientUpgradeable is
    IForwarderRecipientUpgradeable,
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable
{
    address private _forwarder;

    bytes32 public constant SET_FORWARDER_ROLE = keccak256("SET_FORWARDER_ROLE");

    modifier onlyForwarder() {
        address msgSender = _msgSender();
        if (forwarder() != msgSender) {
            revert InvalidForwarder(msgSender);
        }
        _;
    }

    function __ForwarderRecipientUpgradeable_init(address forwarder_) internal onlyInitializing {
        __ForwarderRecipientUpgradeable_init_unchained(forwarder_);
    }

    function __ForwarderRecipientUpgradeable_init_unchained(address forwarder_) internal onlyInitializing {
        _forwarder = forwarder_;
    }

    /// @inheritdoc IForwarderRecipientUpgradeable
    function forwarder() public view virtual returns (address) {
        return _forwarder;
    }

    /// @inheritdoc IForwarderRecipientUpgradeable
    function setForwarder(address forwarder_) public virtual onlyRole(SET_FORWARDER_ROLE) {
        _forwarder = forwarder_;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
