// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IOwnable.sol";
import "./IValidateMint.sol";

/* Variable getters */
interface IValidateMint_Signature_Variables {
    /// @param boxId retrieve public key/address for given `boxId`
    function box__signer(uint256 boxId) external view returns (address);
}

/* Function definitions */
interface IValidateMint_Signature_Functions {
    /// Store data for new generation
    /// @param boxId Generation key to store `box__signer` value
    /// @param signer Public key/address to validate signatures with
    /// @custom:throw "Token already has auth"
    /// @custom:throw "Invalid box ID"
    /// @custom:throw "Signer already assigned"
    function newBox(uint256 boxId, address signer) external;
}

/* For external callers */
interface IValidateMint_Signature is
    IValidateMint_Signature_Functions,
    IValidateMint_Signature_Variables,
    IValidateMint,
    IOwnable
{

}
