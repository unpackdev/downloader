// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./LibGovernance.sol";

abstract contract Governable {

    /// @notice Verifies the message hash against the signatures. Requires a majority.
    modifier onlyConsensus(bytes32 _ethHash, bytes[] calldata _signatures) {
        uint256 members = LibGovernance.membersCount();
        require(_signatures.length <= members, "Governance: Invalid number of signatures");
        require(_signatures.length > members / 2, "Governance: Invalid number of signatures");

        address[] memory signers = new address[](_signatures.length);
        for (uint256 i = 0; i < _signatures.length; i++) {
            address signer = ECDSA.recover(_ethHash, _signatures[i]);
            require(LibGovernance.isMember(signer), "Governance: invalid signer");
            for (uint256 j = 0; j < i; j++) {
                require(signer != signers[j], "Governance: duplicate signatures");
            }
            signers[i] = signer;
        }
        _;
    }

}
