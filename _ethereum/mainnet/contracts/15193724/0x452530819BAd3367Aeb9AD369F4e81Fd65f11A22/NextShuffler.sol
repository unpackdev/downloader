// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
// Modifications (c) 2022 PROOF Holdings Inc
pragma solidity >=0.8.9 <0.9.0;

import "./Initializable.sol";

/**
@notice Returns the next value in a shuffled list [0,n), amortising the shuffle
across all calls to _next(). Can be used for randomly allocating a set of tokens
but the caveats in `dev` docs MUST be noted.
@dev Although the final shuffle is uniformly random, it is entirely
deterministic if the seed to the PRNG.Source is known. This MUST NOT be used for
applications that require secure (i.e. can't be manipulated) allocation unless
parties who stand to gain from malicious use have no control over nor knowledge
of the seed at the time that their transaction results in a call to _next().
 */
contract NextShuffler is Initializable {
    /// @notice Total number of elements to shuffle.
    uint256 internal numToShuffle;

    /**
    @notice Initialize the contract, in lieu of a constructor.
    @param numToShuffle_ Total number of elements to shuffle.
     */
    function initialize(uint256 numToShuffle_) internal onlyInitializing {
        numToShuffle = numToShuffle_;
    }

    /**
    @dev Number of items already shuffled; i.e. number of historical calls to
    _next(). This is the equivalent of `i` in the Wikipedia description of the
    Fisher–Yates algorithm.
     */
    uint256 internal shuffled;

    /**
    @dev A sparse representation of the shuffled list [0,n). List items that
    have been shuffled are stored with their original index as the key and their
    new index + 1 as their value. Note that mappings with numerical values
    return 0 for non-existent keys so we MUST increment the new index to
    differentiate between a default value and a new index of 0. See _get() and
    _set().
     */
    mapping(uint256 => uint256) private _permutation;

    /**
    @notice Returns the current value stored in list index `i`, accounting for
    all historical shuffling.
     */
    function _get(uint256 i) internal view returns (uint256) {
        uint256 val = _permutation[i];
        return val == 0 ? i : val - 1;
    }

    /**
    @notice Sets the list index `i` to `val`, equivalent `arr[i] = val` in a
    standard Fisher–Yates shuffle.
     */
    function _set(uint256 i, uint256 val) internal {
        _permutation[i] = i == val ? 0 : val + 1;
    }
}
