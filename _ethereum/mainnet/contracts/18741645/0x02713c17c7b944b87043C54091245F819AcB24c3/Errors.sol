// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IAuthErrors {
    error CallerIsNotSuperAdmin(address caller);
    error CallerIsNotPlatformAdmin(address caller);
    error PlatformAdminCannotBeAddressZero();
}