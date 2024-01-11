// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IMutationRegistry.sol";
import "./IERC721Enumerable.sol";

interface IERC721GeneticData is IERC721Enumerable, IMutationRegistry {
    event UnlockMutation(uint256 tokenId, uint256 mutationId);
    event Mutate(uint256 tokenId, uint256 mutationId);

    function getTokenMutation(uint256 tokenId) external view returns (uint256);

    function getTokenDNA(uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    function getTokenDNA(uint256 tokenId, uint256[] memory splices)
        external
        view
        returns (uint256[] memory);

    function countTokenMutations(uint256 tokenId)
        external
        view
        returns (uint256);

    function isMutationUnlocked(uint256 tokenId, uint256 mutationId)
        external
        view
        returns (bool);

    function canMutate(uint256 tokenId, uint256 mutationId)
        external
        view
        returns (bool);

    function safeCatalystUnlockMutation(
        uint256 tokenId,
        uint256 mutationId,
        bool force
    ) external;

    function catalystUnlockMutation(uint256 tokenId, uint256 mutationId)
        external;

    function safeCatalystMutate(uint256 tokenId, uint256 mutationId) external;

    function catalystMutate(uint256 tokenId, uint256 mutationId) external;

    function mutate(uint256 tokenId, uint256 mutationId) external payable;
}
