// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IFijaACL.sol";
import "./errors.sol";

///
/// @title Access control contract
/// @author Fija
/// @notice Provides access rights management to child contracts
/// @dev some of the methods have default access modifiers and
/// some do not have restrictions. Please verify and override to have expected behaviour
/// *********** IMPORTANT **************
/// whitelist functions in the contract are not protected
/// it is responsibility of child contracts to define access rights
///
abstract contract FijaACL is IFijaACL {
    address private _owner;
    address private _governance;
    address private _reseller;
    mapping(address => bool) private _whitelist;

    constructor(address governance_, address reseller_) {
        _transferOwnership(msg.sender);
        _transferGovernance(governance_);
        _transferReseller(reseller_);
    }

    ///
    /// @dev Throws if called by any account that's not whitelisted.
    ///
    modifier onlyWhitelisted() {
        _checkWhitelist();
        _;
    }

    ///
    /// @dev Throws if called by any account other than the owner.
    ///
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    ///
    /// @dev Throws if called by any account other than the Governance.
    ///
    modifier onlyGovernance() {
        _checkGovernance();
        _;
    }

    ///
    /// @dev Throws if called by any account other than the Reseller.
    ///
    modifier onlyReseller() {
        _checkReseller();
        _;
    }

    ///
    /// @dev Throws if called by any account other than the Governance or Owner.
    ///
    modifier onlyOwnerOrGovernance() {
        _checkOwnerOrGovernance();
        _;
    }

    ///
    /// @dev Throws if receiver and owner are not in the whitelist
    ///
    modifier onlyReceiverOwnerWhitelisted(address receiver, address owner_) {
        _checkReceiverOwnerWhitelisted(receiver, owner_);
        _;
    }

    ///
    /// @dev Throws if receiver is not in the whitelist
    ///
    modifier onlyReceiverWhitelisted(address receiver) {
        _checkReceiverWhitelisted(receiver);
        _;
    }

    ///
    /// NOTE: emits IFijaACL.WhitelistedAddressAdded
    /// @inheritdoc IFijaACL
    ///
    function addAddressToWhitelist(
        address addr
    ) public virtual override returns (bool) {
        if (isWhitelisted(addr)) {
            return false;
        }
        _addAddressToWhitelist(addr);

        return true;
    }

    ///
    /// NOTE: emits IFijaACL.WhitelistedAddressRemoved
    /// @inheritdoc IFijaACL
    ///
    function removeAddressFromWhitelist(
        address addr
    ) public virtual override returns (bool) {
        if (!isWhitelisted(addr)) {
            return false;
        }
        _removeAddressFromWhitelist(addr);

        return true;
    }

    ///
    /// @inheritdoc IFijaACL
    ///
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    ///
    /// @inheritdoc IFijaACL
    ///
    function governance() public view virtual override returns (address) {
        return _governance;
    }

    ///
    /// @inheritdoc IFijaACL
    ///
    function reseller() public view virtual override returns (address) {
        return _reseller;
    }

    ///
    /// @inheritdoc IFijaACL
    ///
    function isWhitelisted(
        address addr
    ) public view virtual override returns (bool) {
        return _whitelist[addr];
    }

    ///
    /// NOTE: only owner access, emits IFijaACL.OwnershipTransferred
    /// @inheritdoc IFijaACL
    ///
    function transferOwnership(
        address newOwner
    ) external virtual override onlyOwner {
        _transferOwnership(newOwner);
    }

    ///
    /// NOTE: only owner or governance access, emits IFijaACL.GovernanceTransferred
    /// @inheritdoc IFijaACL
    ///
    function transferGovernance(
        address newGovernance
    ) external virtual override onlyOwnerOrGovernance {
        if (newGovernance == address(0)) {
            revert ACLGovZero();
        }
        _transferGovernance(newGovernance);
    }

    ///
    /// NOTE: only governance access, emits IFijaACL.ResellerTransferred
    /// @inheritdoc IFijaACL
    ///
    function transferReseller(
        address newReseller
    ) external virtual override onlyGovernance {
        if (newReseller == address(0)) {
            revert ACLResellZero();
        }
        _transferReseller(newReseller);
    }

    ///
    /// NOTE: only governance access, emits IFijaACL.GovernanceTransferred
    /// @inheritdoc IFijaACL
    ///
    function renounceGovernance() external virtual override onlyGovernance {
        _transferGovernance(address(0));
    }

    ///
    /// NOTE: only reseller access, emits IFijaACL.ResellerTransferred
    /// @inheritdoc IFijaACL
    ///
    function renounceReseller() external virtual override onlyReseller {
        _transferReseller(address(0));
    }

    ///
    /// NOTE: owner cannot be zero address
    /// @dev Helper method for transferOwnership.
    /// Changes ownership access to new owner address.
    /// @param newOwner address of new owner
    ///
    function _transferOwnership(address newOwner) internal virtual {
        if (newOwner == address(0)) {
            revert ACLOwnerZero();
        }
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    ///
    /// @dev Helper method for transferGovernance.
    /// Changes governance access to new governance address.
    /// @param newGovernance address of new governance
    ///
    function _transferGovernance(address newGovernance) internal virtual {
        address oldGovernance = _governance;
        _governance = newGovernance;
        emit GovernanceTransferred(oldGovernance, newGovernance);
    }

    ///
    /// @dev Helper method for transferReseller.
    /// Changes reseller access to new reseller address.
    /// @param newReseller address of new reseller
    ///
    function _transferReseller(address newReseller) internal virtual {
        address oldReseller = _reseller;
        _reseller = newReseller;
        emit ResellerTransferred(oldReseller, newReseller);
    }

    ///
    /// @dev Helper method for onlyOwner modifier
    ///
    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) {
            revert ACLNotOwner();
        }
    }

    ///
    /// @dev Helper method for onlyGovernance modifier
    ///
    function _checkGovernance() internal view virtual {
        if (governance() != msg.sender) {
            revert ACLNotGov();
        }
    }

    ///
    /// @dev Helper method for onlyOwnerOrGovernance modifier
    ///
    function _checkOwnerOrGovernance() internal view virtual {
        if (governance() != msg.sender && owner() != msg.sender) {
            revert ACLNotGovOwner();
        }
    }

    ///
    /// @dev Helper method for onlyReseller modifier
    ///
    function _checkReseller() internal view virtual {
        if (reseller() != msg.sender) {
            revert ACLNotReseller();
        }
    }

    ///
    /// @dev Helper method for onlyWhitelisted modifier
    ///
    function _checkWhitelist() internal view virtual {
        if (!isWhitelisted(msg.sender)) {
            revert ACLNotWhitelist();
        }
    }

    ///
    /// @dev Helper method for onlyReceiverOwnerWhitelisted modifier
    ///
    function _checkReceiverOwnerWhitelisted(
        address receiver,
        address owner_
    ) internal view virtual {
        if (!isWhitelisted(receiver) || !isWhitelisted(owner_)) {
            revert ACLRedeemWithdrawReceiverOwnerNotWhitelist();
        }
    }

    ///
    /// @dev Helper method for onlyReceiverWhitelisted modifier
    ///
    function _checkReceiverWhitelisted(address receiver) internal view virtual {
        if (!isWhitelisted(receiver)) {
            revert ACLDepositReceiverNotWhitelist();
        }
    }

    ///
    /// @dev Helper method for adding address to contract whitelist.
    /// @param addr address to be added to the whitelist
    ///
    function _addAddressToWhitelist(address addr) internal {
        if (addr == address(0)) {
            revert ACLWhitelistAddressZero();
        }
        _whitelist[addr] = true;
        emit WhitelistedAddressAdded(addr);
    }

    ///
    /// @dev Helper method for removing address from contract whitelist.
    /// @param addr address to be removed from the whitelist
    ///
    function _removeAddressFromWhitelist(address addr) internal {
        _whitelist[addr] = false;
        emit WhitelistedAddressRemoved(addr);
    }
}
