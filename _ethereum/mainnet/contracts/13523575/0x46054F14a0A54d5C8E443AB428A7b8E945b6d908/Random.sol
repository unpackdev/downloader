// SPDX-License-Identifier: MIT
// Copyright 2021 Arran Schlosberg
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice Random contracts can generate unbiased pseudorandom numbers from
 * seeds. Best practice requires only setting the `entropy` value _after_
 * user interaction, and obtaining it from a source out of the control of anyone
 * who may benefit from the outcome. Ideally a VRF would be used. If the
 * contract admin can't be trusted, they can publicly nominate a future block
 * number and use its hash; NOTE that this can be manipulated by a miner, so
 * their expected return of such an action should be considered. If the admin
 * can be trusted then they can use a commit-and-reveal approach.
 */
contract Random {
    /// @notice A base entropy source that ensures that calls to _uniform(seed)
    /// return different values to calls in another contract despite having the
    /// same seed.
    bytes32 internal _entropy;

    /// @notice Immutably sets the entropy value if not already set.
    function _setEntropy(bytes32 entropy) internal {
        require (!entropySet(), "Entropy already set");
        _entropy = entropy;
    }

    /// @notice Returns if the entropy value has been set, assuming that this
    /// value was not 0.
    function entropySet() public view returns (bool) {
        return uint256(_entropy) != 0;
    }

    /// @notice Returns the value passed to _setEntropy().
    function getEntropy() public view returns (bytes32) {
        require (entropySet(), "Entropy not set");
        return _entropy;
    }

    /**
     * @dev As we're generating random numbers from hashes, their ranges are
     * always powers of two. However we need denominators that are
     * human-friendly and therefore powers of 10. Generating a random number in
     * [0,10^59] can be performed in an unbiased manner by repeatedly sampling
     * 196 bits from keccak256(seed||counter) until it's within the range. These
     * values are chosen because 10^59/2^196 = 0.9957 so we very rarely have to
     * try again and waste computation.
     */
    uint256 private constant RAND_MASK = 2**196 - 1;
    uint256 public constant ONE = 1e59;

    /// @notice Values equivalent to 1% and 0.01%.
    uint256 public constant PERCENT = 1e57;
    uint256 public constant BASIS_POINT = 1e55;

    /// @notice Returns a uniformly distributed random number [0, ONE].
    function _uniform(bytes memory seed) internal view returns (uint256) {
        uint256 rand = RAND_MASK;
        // The loop will always run at least once because RAND_MASK > ONE.
        for (uint j = 0; rand > ONE; j++) {
            rand = uint256(keccak256(abi.encode(_entropy, seed, j)));
            assembly { rand := and(rand, RAND_MASK) }
        }
        return rand;
    }
}