// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC721GeneticData.sol";
import "./MutationRegistry.sol";

/**
 * @dev An ERC721 extension that provides access to storage and expansion of token information.
 * Initial data is stored in the base genes map. Newly introduced data will be stored in the extended genes map.
 * Token information may be extended whenever a token unlocks new mutations from the mutation registry.
 * Mutation catalysts may forcefully unlock or cause mutations.
 * Implementation inspired by nftchance's Mimetic Metadata concept.
 */
abstract contract ERC721GeneticData is
    ERC721Enumerable,
    MutationRegistry,
    IERC721GeneticData
{
    // Mapping from token ID to base genes
    uint64[MAX_SUPPLY] internal _tokenBaseGenes;

    // Mapping from token ID to extended genes
    uint8[][MAX_SUPPLY] private _tokenExtendedGenes;

    // Mapping from token ID to active mutation
    uint8[MAX_SUPPLY] private _tokenMutation;

    // Mapping from token ID to unlocked mutations
    bool[MAX_MUTATIONS][MAX_SUPPLY] public tokenUnlockedMutations;

    // List of mutation catalysts
    mapping(address => bool) public mutationCatalysts;

    modifier onlyMutationCatalyst() {
        require(
            mutationCatalysts[_msgSender()],
            "ERC721GeneticData: caller is not catalyst"
        );
        _;
    }

    /**
     * @dev Returns the token's active mutation.
     */
    function getTokenMutation(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (uint256)
    {
        return _tokenMutation[tokenId];
    }

    /**
     * @dev Returns the token's DNA sequence.
     */
    function getTokenDNA(uint256 tokenId)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory splices;
        return getTokenDNA(tokenId, splices);
    }

    /**
     * @dev Returns the token's DNA sequence.
     * @param splices DNA customizations to apply
     */
    function getTokenDNA(uint256 tokenId, uint256[] memory splices)
        public
        view
        override
        tokenExists(tokenId)
        returns (uint256[] memory)
    {
        uint8[] memory genes = _tokenExtendedGenes[tokenId];
        uint256 geneCount = genes.length;
        uint256 spliceCount = splices.length;
        uint256[] memory dna = new uint256[](geneCount + 1);
        dna[0] = uint256(keccak256(abi.encodePacked(_tokenBaseGenes[tokenId])));

        for (uint256 i; i < geneCount; i++) {
            // Expand genes and add to DNA sequence
            dna[i + 1] = uint256(keccak256(abi.encodePacked(dna[i], genes[i])));

            // Splice previous genes
            if (i < spliceCount) {
                dna[i] ^= splices[i];
            }
        }

        // Splice final genes
        if (spliceCount == geneCount + 1) {
            dna[geneCount] ^= splices[geneCount];
        }

        return dna;
    }

    /**
     * @dev Gets the number of unlocked token mutations.
     */
    function countTokenMutations(uint256 tokenId)
        external
        view
        override
        tokenExists(tokenId)
        returns (uint256)
    {
        return _countTokenMutations(tokenId);
    }

    /**
     * @dev Checks whether the token has unlocked a mutation.
     * note base mutation is always unlocked.
     */
    function isMutationUnlocked(uint256 tokenId, uint256 mutationId)
        external
        view
        override
        tokenExists(tokenId)
        mutationExists(mutationId)
        returns (bool)
    {
        return _isMutationUnlocked(tokenId, mutationId);
    }

    /**
     * @dev Checks whether the token can mutate to a mutation safely.
     */
    function canMutate(uint256 tokenId, uint256 mutationId)
        external
        view
        override
        tokenExists(tokenId)
        mutationExists(mutationId)
        returns (bool)
    {
        return _canMutate(tokenId, mutationId);
    }

    /**
     * @dev Toggles a mutation catalyst's state.
     */
    function toggleMutationCatalyst(address catalyst) external onlyOwner {
        mutationCatalysts[catalyst] = !mutationCatalysts[catalyst];
    }

    /**
     * @dev Unlocks a mutation for the token.
     * @param force unlocks mutation even if it can't be mutated to.
     */
    function safeCatalystUnlockMutation(
        uint256 tokenId,
        uint256 mutationId,
        bool force
    ) external override tokenExists(tokenId) mutationExists(mutationId) {
        require(
            !_isMutationUnlocked(tokenId, mutationId),
            "ERC721GeneticData: unlock to unlocked mutation"
        );
        require(
            force || _canMutate(tokenId, mutationId),
            "ERC721GeneticData: unlock to unavailable mutation"
        );

        catalystUnlockMutation(tokenId, mutationId);
    }

    /**
     * @dev Unlocks a mutation for the token.
     */
    function catalystUnlockMutation(uint256 tokenId, uint256 mutationId)
        public
        override
        onlyMutationCatalyst
    {
        _unlockMutation(tokenId, mutationId);
    }

    /**
     * @dev Changes a token's active mutation if it's unlocked.
     */
    function safeCatalystMutate(uint256 tokenId, uint256 mutationId)
        external
        override
        tokenExists(tokenId)
        mutationExists(mutationId)
    {
        require(
            _tokenMutation[tokenId] != mutationId,
            "ERC721GeneticData: mutate to active mutation"
        );

        require(
            _isMutationUnlocked(tokenId, mutationId),
            "ERC721GeneticData: mutate to locked mutation"
        );

        catalystMutate(tokenId, mutationId);
    }

    /**
     * @dev Changes a token's active mutation.
     */
    function catalystMutate(uint256 tokenId, uint256 mutationId)
        public
        override
        onlyMutationCatalyst
    {
        _mutate(tokenId, mutationId);
    }

    /**
     * @dev Changes a token's active mutation.
     */
    function mutate(uint256 tokenId, uint256 mutationId)
        external
        payable
        override
        onlyApprovedOrOwner(tokenId)
        mutationExists(mutationId)
    {
        if (_isMutationUnlocked(tokenId, mutationId)) {
            require(
                _tokenMutation[tokenId] != mutationId,
                "ERC721GeneticData: mutate to active mutation"
            );
        } else {
            require(
                _canMutate(tokenId, mutationId),
                "ERC721GeneticData: mutate to unavailable mutation"
            );
            require(
                msg.value == getMutation(mutationId).cost,
                "ERC721GeneticData: incorrect amount of ether sent"
            );

            _unlockMutation(tokenId, mutationId);
        }

        _mutate(tokenId, mutationId);
    }

    /**
     * @dev Allows owner to regenerate cloned genes.
     */
    function unclone(uint256 tokenA, uint256 tokenB) external onlyOwner {
        require(tokenA != tokenB, "ERC721GeneticData: unclone of same token");
        uint256 genesA = _tokenBaseGenes[tokenA];
        require(
            genesA == _tokenBaseGenes[tokenB],
            "ERC721GeneticData: unclone of uncloned tokens"
        );
        _tokenBaseGenes[tokenA] = uint64(bytes8(_getGenes(tokenA, genesA)));
    }

    /**
     * @dev Gets the number of unlocked token mutations.
     */
    function _countTokenMutations(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 count = 1;
        bool[MAX_MUTATIONS] memory mutations = tokenUnlockedMutations[tokenId];
        for (uint256 i = 1; i < MAX_MUTATIONS; i++) {
            if (mutations[i]) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Checks whether the token has unlocked a mutation.
     * note base mutation is always unlocked.
     */
    function _isMutationUnlocked(uint256 tokenId, uint256 mutationId)
        private
        view
        returns (bool)
    {
        return mutationId == 0 || tokenUnlockedMutations[tokenId][mutationId];
    }

    /**
     * @dev Checks whether the token can mutate to a mutation.
     */
    function _canMutate(uint256 tokenId, uint256 mutationId)
        private
        view
        returns (bool)
    {
        uint256 activeMutationId = _tokenMutation[tokenId];
        uint256 nextMutationId = getMutation(activeMutationId).next;
        Mutation memory mutation = getMutation(mutationId);

        return
            mutation.enabled &&
            (nextMutationId == 0 || nextMutationId == mutationId) &&
            (mutation.prev == 0 || mutation.prev == activeMutationId);
    }

    /**
     * @dev Unlocks a token's mutation.
     */
    function _unlockMutation(uint256 tokenId, uint256 mutationId) private {
        tokenUnlockedMutations[tokenId][mutationId] = true;
        _addGenes(tokenId, getMutation(mutationId).geneCount);
        emit UnlockMutation(tokenId, mutationId);
    }

    /**
     * @dev Changes a token's active mutation.
     */
    function _mutate(uint256 tokenId, uint256 mutationId) private {
        _tokenMutation[tokenId] = uint8(mutationId);
        emit Mutate(tokenId, mutationId);
    }

    /**
     * @dev Adds new genes to the token's DNA sequence.
     */
    function _addGenes(uint256 tokenId, uint256 maxGeneCount) private {
        uint8[] storage genes = _tokenExtendedGenes[tokenId];
        uint256 geneCount = genes.length;
        bytes32 newGenes;
        while (geneCount < maxGeneCount) {
            if (newGenes == 0) {
                newGenes = _getGenes(tokenId, geneCount);
            }
            genes.push(uint8(bytes1(newGenes)));
            newGenes <<= 8;
            unchecked {
                geneCount++;
            }
        }
    }

    /**
     * @dev Gets new genes for a token's DNA sequence.
     */
    function _getGenes(uint256 tokenId, uint256 seed)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    tokenId,
                    seed,
                    ownerOf(tokenId),
                    block.number,
                    block.difficulty
                )
            );
    }

    function _burn(uint256 tokenId) internal override {
        delete _tokenMutation[tokenId];
        delete _tokenBaseGenes[tokenId];
        delete _tokenExtendedGenes[tokenId];
        delete tokenUnlockedMutations[tokenId];
        super._burn(tokenId);
    }
}
