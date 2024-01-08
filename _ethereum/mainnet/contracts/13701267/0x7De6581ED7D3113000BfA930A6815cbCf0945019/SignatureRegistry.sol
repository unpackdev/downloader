// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 Arran Schlosberg (@divergencearran / @divergence_art)
pragma solidity >=0.8.0 <0.9.0;

import "./SignatureChecker.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

/// @dev Abstract the set of signers to keep primary contract smaller.
contract SignerRegistry is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SignatureChecker for EnumerableSet.AddressSet;

    /**
    @notice Addresses from which we accept signatures during allow-list phase.
    */
    EnumerableSet.AddressSet private _signers;

    constructor(address[] memory signers) {
        for (uint256 i = 0; i < signers.length; i++) {
            _signers.add(signers[i]);
        }
    }

    /// @notice Wrapper around internal signers.validateSignature().
    function validateSignature(address to, bytes calldata signature)
        public
        view
    {
        _signers.validateSignature(to, signature);
    }

    /// @notice Add an address to the set of allowed signature sources.
    function addSigner(address signer) external onlyOwner {
        _signers.add(signer);
    }

    /// @notice Remove an address from the set of allowed signature sources.
    function removeSigner(address signer) external onlyOwner {
        _signers.remove(signer);
    }
}
