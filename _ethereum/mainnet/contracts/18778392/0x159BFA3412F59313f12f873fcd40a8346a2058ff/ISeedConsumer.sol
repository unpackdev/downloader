// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title ISeedConsumer
 * @author fx(hash)
 * @notice Interface for randomizers to interact with FxGenArt721 tokens
 */
interface ISeedConsumer {
    /*//////////////////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when a seed request is fulfilled for a specific token
     * @param _randomizer Address of the randomizer contract
     * @param _tokenId ID of the token
     * @param _seed Hash of the random seed
     */
    event SeedFulfilled(address indexed _randomizer, uint256 indexed _tokenId, bytes32 _seed);

    /*//////////////////////////////////////////////////////////////////////////
                                  FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Fullfills the random seed request on the FxGenArt721 token contract
     * @param _tokenId ID of the token
     * @param _seed Hash of the random seed
     */
    function fulfillSeedRequest(uint256 _tokenId, bytes32 _seed) external;
}
