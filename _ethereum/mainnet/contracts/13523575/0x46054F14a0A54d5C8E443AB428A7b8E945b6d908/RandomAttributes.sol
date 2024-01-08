// SPDX-License-Identifier: MIT
// Copyright 2021 Arran Schlosberg
pragma solidity >=0.8.0 <0.9.0;

import "./Random.sol";
import "./Ownable.sol";

/// @notice An abstract contract that allows for random allocation of attributes
/// to a set of tokens (presumably ERC721 but not limited).
/// @dev Inheriting contracts need to override two functions to define how
/// attributes are expressed (e.g. ERC721 metadata JSON).
abstract contract RandomAttributes is Ownable, Random {
    /// @notice Maximum number of tokens that will ever exist.
    /// @dev See _allocatedTo() for usage.
    uint256 immutable public MAX_TOKENS;

    constructor(uint256 maxTokens) {
        MAX_TOKENS = maxTokens;
    }

    /// @dev Override to define how TieredTraits are expressed.
    function attrForTrait(string memory trait, string memory value) virtual internal pure returns (bytes memory) {}

    /// @dev Override to define how Allocated traits are expressed.
    function attrFromName(string memory name) virtual internal pure returns (bytes memory) {}

    /// @notice Sets the entropy value used for random allocation.
    /// @dev NB See Random.sol for important considerations.
    function setEntropy(bytes32 entropy) onlyOwner external {
        Random._setEntropy(entropy);
    }

    /// @notice An attribute / trait that is allocated proportionally into
    /// Tiers. All will have the same Trait name, but different Tier names.
    /// @dev No checks are performed to ensure that the sum of all proportions
    /// <= Random.ONE. Proportions do not have to add to ONE, and any shortfall
    /// will result in that proportion of tokens not receiving this trait.
    struct TieredTrait {
        string name;
        Tier[] tiers;
    }

    /// @notice A Tier within a TieredTrait.
    /// @dev See Random.ONE, Random.PERCENT, and Random.BASIS_POINT for
    /// defining proportions. NB: As these allocations are subject to a random
    /// distribution, final proportions won't be exact. See Allocated if exact
    /// values are required, but note that they are more expensive to compute
    /// so MUST only be used for low values of k.
    struct Tier {
        string name;
        uint256 proportion;
    }

    /// @notice All TieredTraits to be assigned.
    TieredTrait[] internal _tiered;

    /// @notice Adds a new TieredTrait.
    /// @param index The expected index in the _tiered array, to guarantee
    /// idempotent calls during deployment.
    function _newTieredTrait(uint index, TieredTrait memory trait) onlyOwner external {
        // Ensure that calls are idempotent. Without this, pushing multiple
        // traits to the chain with one transaction failing could result in
        // unexpected indices.
        require(index == _tiered.length, "RandomAttributes: invalid tiered index");
        
        _tiered.push();
        _tiered[index].name = trait.name;
        _addToTieredTrait(index, 0, trait.tiers);
    }

    /// @notice Extends an existing TieredTrait with more Tiers.
    /// @param startIndex The expected index of the first Tier to be added, to
    /// guarantee idempotent calls during deployment.
    function _addToTieredTrait(uint traitIndex, uint startIndex, Tier[] memory tiers) onlyOwner public {
        // See _newTieredTrait() for logic.
        require(startIndex == _tiered[traitIndex].tiers.length, "RandomAttributes: invalid startIndex");
        
        // Solidity doesn't support copy from memory to storage for this type,
        // so push each element.
        for (uint i = 0; i < tiers.length; i++) {
            _tiered[traitIndex].tiers.push(tiers[i]);
        }
    }

    /// @notice Alias for _tieredTraitsFor() with zero-value entropy.
    function _tieredTraitsFor(uint256 tokenId, TieredTrait[] memory traits) internal view returns (bytes memory) {
        return _tieredTraitsFor(tokenId, traits, new bytes(0));
    }

    /// @notice Computes all Tiers, for all Traits, assigned to the token. The
    /// Tiers are passed to attrForTrait() and the returned values concatenated
    /// with abi.encodePacked() to be returned.
    /// @param traits The TieredTraits to be assigned. These are typically the
    /// values stored in _tiered, but MAY differ.
    /// @param _entropy Optional additional entropy for use in allocating Tiers.
    /// @dev The entropy in Random._entropy is always used, while the _entropy
    /// param is an additional source. The Random._entropy value is used to
    /// differentiate between contract instances whereas the parameter allows
    /// for different rolls of the dice within the same contract. This function
    /// SHOULD be used in a call, not a transaction, as it hasn't been optimised
    /// for gas consumption.
    function _tieredTraitsFor(uint256 tokenId, TieredTrait[] memory traits, bytes memory _entropy) internal view returns (bytes memory) {
        uint256 threshold;
        bytes memory assigned;

        for (uint i=0; i < traits.length; i++) {
            uint rand = _uniform(abi.encode(_entropy, tokenId, traits[i].name));

            // Although it would be more computationally efficient to perform a
            // binary search here, it adds code complexity that can result in a
            // bug. Testing of random functions is difficult enough as it is, so
            // we opt for simplicity for negligible gas cost (or zero given that
            // this function is intended for gas-free calls).
            threshold = 0;
            for (uint j = 0; j < traits[i].tiers.length; j++) {
                threshold += traits[i].tiers[j].proportion;
                
                if (rand <= threshold) {
                    assigned = abi.encodePacked(assigned, attrForTrait(traits[i].name, traits[i].tiers[j].name));
                    break;
                }
            }
        }

        return assigned;
    }

    /// @notice A directly allocated attribute that is assigned to exactly k
    /// tokens.
    /// @dev Allocation is very expensive, and may even cause a gas-free call to
    /// reach block limits (still enforced, just not paid). It scales roughly
    /// linearly as O(k) as long as k << MAX_TOKENS. If k approaches MAX_TOKENS
    /// then the probability of allocating to the same token on different random
    /// samplings increases and _isAllocatedTo() becomes much less efficient. If
    /// k is too large, TieredTraits SHOULD be used instead.
    struct Allocated {
        string name;
        uint256 k;
    }

    /// @notice All Allocated attributes to be assigned.
    Allocated[] internal _allocs;

    /// @notice Adds a new Allocated attribute.
    /// @param index The expected index in the _allocs array, to guarantee
    /// idempotent calls during deployment.
    function _newAllocatedTrait(uint index, Allocated memory alloc) onlyOwner external {
        require(index == _allocs.length, "RandomAttributes: invalid allocated index");
        _allocs.push(alloc);
    }

    /// @notice Alias for _allocatedTo() with zero-value entropy.
    function _allocatedTo(uint256 tokenId, Allocated[] memory allocs) internal view returns (bytes memory) {
        return _allocatedTo(tokenId, allocs, new bytes(0));
    }

    /// @notice Computes all Allocated attributes assigned to the given token.
    /// The names are passed to attrFromName() and the returned values
    /// concatenated with abi.encodePacked() to be returned.
    /// @param allocs The Allocated to be assigned. These are typically the
    /// values stored in _allocs, but MAY differ.
    /// @param _entropy Optional additional entropy for use in selecting tokens
    /// receiving Allocated attributes.
    /// @dev The entropy in Random._entropy is always used, while the _entropy
    /// param is an additional source. The Random._entropy value is used to
    /// differentiate between contract instances whereas the parameter allows
    /// for different rolls of the dice within the same contract. This function
    /// SHOULD be used in a call, not a transaction, as it hasn't been optimised
    /// for gas consumption.
    function _allocatedTo(uint256 tokenId, Allocated[] memory allocs, bytes memory _entropy) internal view returns (bytes memory) {
        // Determine how many bits of entropy are needed to choose from
        // MAX_TOKENS.
        uint256 logN = 0;
        uint256 n = MAX_TOKENS;
        assembly {
            for {} gt(n, 0) {n := shr(1, n)} {
                logN := add(logN, 1)
            }
        }
        uint256 mask = 2**logN - 1;

        bytes memory allocated;
        for (uint i=0; i < allocs.length; i++) {
            if (_isAllocatedTo(tokenId, allocs[i], logN, mask, _entropy)) {
                allocated = abi.encodePacked(allocated, attrFromName(allocs[i].name));
            }
        }
        return allocated;
    }

    /// @notice Returns whether a _specific_ Allocated attribute is assigned to
    /// the specific tokenId.
    /// @param logN An approximation of log_2(MAX_TOKENS) used to determine the
    /// number of random bits used for a single sample. MUST be the smallest
    /// integer value >log_2(MAX_TOKENS).
    /// @param mask A bitwise mask for sampling random bits. MUST be equal to
    /// 2**logN - 1, i.e. the smallest all-ones binary mask that is larger than
    /// MAX_TOKENS.
    /// @param _entropy See _allocatedTo().
    /// @dev Functions by sampling from keccak256(<entropy sources>,counter) in
    /// an unbiased fashion until either tokenId receives an Allocated trait or
    /// all traits are allocated. This function SHOULD be used in a call, not a
    /// transaction, as it hasn't been optimised for gas consumption.
    function _isAllocatedTo(uint256 tokenId, Allocated memory alloc, uint256 logN, uint256 mask, bytes memory _entropy) private view returns (bool) {
        // randSrc is a pool of entropy sourced from the hash of entropy sources
        // and a counter. When replenished, bitsRemaining is set to 256, and
        // reduced by logN after each sample.
        uint256 counter = 0;
        uint256 randSrc;
        uint256 bitsRemaining = 0;
        // The random sample [0,mask]. This is the smallest range that includes
        // MAX_TOKEN, thus improving efficiency of rejection sampling.
        uint256 rand;

        // Keeps track of the tokens other than tokenId to which this trait has
        // been allocated. Effectively a set, but Solidity doesn't support
        // mapping types out of storage, and this function MUST be `view`.
        bool[] memory already = new bool[](MAX_TOKENS);

        for (uint i = 0; i < alloc.k; i++) {
            while (true) {
                // Do we need to replenish the entropy source?
                if (bitsRemaining < logN) {
                    randSrc = uint256(keccak256(abi.encode(_entropy, Random._entropy, alloc.name, counter)));
                    counter++;
                    bitsRemaining = 256;
                }

                // Sample from randSrc.
                assembly {
                    rand := and(randSrc, mask)
                    randSrc := shr(logN, randSrc)
                    // Can never wrap because of the replenishment in the if
                    // block above.
                    bitsRemaining := sub(bitsRemaining, logN)
                }

                if (rand == tokenId) {
                    return true;
                }
                if (rand >= MAX_TOKENS) {
                    // The random value is out of range and therefore rejected.
                    // Don't use % MAX_TOKENS because this biases low-valued
                    // numbers, so instead we roll the dice again without
                    // incrementing i.
                    continue;
                }
                if (already[rand]) {
                    // Although this can be collapsed into the previous if
                    // statement, it's separated to check for test coverage.
                    // It's very hard to test random functions like this, so
                    // every bit of extra information helps.
                    continue;
                }
                already[rand] = true;
                // Note the inner loop so this allocates to the next token.
                break;
            }
        }

        return false;
    }

    /// @notice Returns the concatenation of _tieredTraitsFor() and
    /// _allocatedTo() for the specified token, using zero-value entropy and the
    /// contract-stored attributes.
    function _attributesOf(uint256 tokenId) external view returns (bytes memory) {
        TieredTrait[] memory tiered = _tiered;
        Allocated[] memory allocs = _allocs;

        return abi.encodePacked(
            _tieredTraitsFor(tokenId, tiered),
            _allocatedTo(tokenId, allocs)
        );
    }

}