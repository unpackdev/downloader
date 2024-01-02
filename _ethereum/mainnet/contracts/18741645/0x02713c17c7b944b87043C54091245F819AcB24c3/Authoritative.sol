// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./EnumerableSet.sol";
import "./Errors.sol";
import "./Revertible.sol";

contract Authoritative is IAuthErrors, Revertible {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private Admins;
    address public SuperAdmin;

    event SuperAdminTransferred(address oldSuperAdmin, address newSuperAdmin);
    event PlatformAdminAdded(address platformAdmin);
    event PlatformAdminRevoked(address platformAdmin);

    modifier onlySuperAdmin() {
        if (!IsSuperAdmin(msg.sender)) {
            revert CallerIsNotSuperAdmin(msg.sender);
        }
        _;
    }

    modifier onlyPlatformAdmin() {
        if (!IsPlatformAdmin(msg.sender))
            revert CallerIsNotPlatformAdmin(msg.sender);
        _;
    }

    function IsSuperAdmin(address addressToCheck) public view returns (bool) {
        return (SuperAdmin == addressToCheck);
    }

    function IsPlatformAdmin(
        address addressToCheck
    ) public view returns (bool) {
        return (Admins.contains(addressToCheck));
    }

    function GrantPlatformAdmin(
        address newPlatformAdmin_
    ) public onlySuperAdmin {
        if (newPlatformAdmin_ == address(0)) {
            Revert(PlatformAdminCannotBeAddressZero.selector);
        }
        // Add this to the enumerated list:
        Admins.add(newPlatformAdmin_);
        emit PlatformAdminAdded(newPlatformAdmin_);
    }

    function RevokePlatformAdmin(address oldAdmin) public onlySuperAdmin {
        Admins.remove(oldAdmin);
        emit PlatformAdminRevoked(oldAdmin);
    }

    function TransferSuperAdmin(address newSuperAdmin) public onlySuperAdmin {
        address oldSuperAdmin = SuperAdmin;
        SuperAdmin = newSuperAdmin;
        emit SuperAdminTransferred(oldSuperAdmin, newSuperAdmin);
    }
}
