// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <0.9.0;

import "./IAddressRegistryV1.sol";

//-------------------------------------------------------------------------
// Interface IAddressRegistryReceiverV1
//
/// Contracts can be registered (offchain) to receive callbacks for when
/// an offchain screening even has completed.  In such a case that `handler`
/// contract must implmenet the IAddressRegistryReceiverV1 interface.
/// @title Contract IAddressRegistryReceiverV1
/// @author Chris Jimison
interface IAddressRegistryReceiverV1 {
    /// Callback made by the offchain oracle when a response has come in
    /// from the offchain oracle
    /// @param result of the check
    /// @param reqID that maps to this response
    /// @param account that was checked offchain if it is safe
    /// @param value of that results
    function onResponse(
        IAddressRegistryV1.ResultsEnum result,
        uint256 reqID,
        address account,
        bool value
    ) external;

    /// Callback made by the offchain oracle when the registration was complete.
    /// @param result of the registration.
    /// @param regID identifier of the registration.
    function onRegistration(
        IAddressRegistryV1.ResultsEnum result,
        uint256 regID
    ) external;
}
