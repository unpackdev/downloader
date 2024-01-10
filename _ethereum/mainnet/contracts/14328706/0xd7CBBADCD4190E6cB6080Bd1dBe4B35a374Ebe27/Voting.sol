// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./EnumerableSet.sol";

abstract contract Voting {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => address) internal _votersDecisions;

    EnumerableSet.AddressSet internal _voters;

    event Vote(address voter, address candidate);

    function _vote(address voter, address candidate) internal {
        require(voter != address(0), "vote from the zero address");

        if (_votersDecisions[voter] != candidate) {
            _votersDecisions[voter] = candidate;

            if (candidate == address(0)) {
                _voters.remove(voter);
            } else {
                _voters.add(voter);
            }

            emit Vote(voter, candidate);
        }
    }

    uint256[48] private __gap;
}
