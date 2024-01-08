// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./EnumerableSet.sol";
import "./Counters.sol";
import "./ECDSA.sol";

library LibGovernance {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;
    bytes32 constant STORAGE_POSITION = keccak256("governance.storage");

    struct Storage {
        bool initialized;
        // nonce used for making administrative changes
        Counters.Counter administrativeNonce;
        // the set of active validators
        EnumerableSet.AddressSet membersSet;
    }

    function governanceStorage() internal pure returns (Storage storage gs) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }


    /// @notice Adds/removes a validator from the member set
    function updateMember(address _account, bool _status) internal {
        Storage storage gs = governanceStorage();
        if (_status) {
            require(
                gs.membersSet.add(_account),
                "Governance: Account already added"
            );
        } else if (!_status) {
            require(
                gs.membersSet.length() > 1,
                "Governance: Would become memberless"
            );
            require(
                gs.membersSet.remove(_account),
                "Governance: Account is not a member"
            );
        }
        gs.administrativeNonce.increment();
    }

    /// @notice Computes the bytes32 ethereum signed message hash of the member update message
    function computeMemberUpdateMessage(address _account, bool _status) internal view returns (bytes32) {
        Storage storage gs = governanceStorage();
        bytes32 hashedData =
            keccak256(
                abi.encode(_account, _status, gs.administrativeNonce.current())
            );
        return ECDSA.toEthSignedMessageHash(hashedData);
    }

    /// @notice Returns true/false depending on whether a given address is member or not
    function isMember(address _member) internal view returns (bool) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.contains(_member);
    }

    /// @notice Returns the count of the members
    function membersCount() internal view returns (uint256) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.length();
    }

    /// @notice Returns the address of a member at a given index
    function memberAt(uint256 _index) internal view returns (address) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.at(_index);
    }

    /// @notice Validates the provided signatures aginst the member set
    function validateSignatures(bytes32 _ethHash, bytes[] calldata _signatures) internal view {
        address[] memory signers = new address[](_signatures.length);
        for (uint256 i = 0; i < _signatures.length; i++) {
            address signer = ECDSA.recover(_ethHash, _signatures[i]);
            require(isMember(signer), "Governance: invalid signer");
            for (uint256 j = 0; j < i; j++) {
                require(signer != signers[j], "Governance: duplicate signatures");
            }
            signers[i] = signer;
        }
    }
}