//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.21;

/**
 * @title RMRK Deployer Interface
 * @notice This is interface is for an intermediary contract whose only purpose is to deploy Wrapped Collections.
 * @dev This contract does not have any validation, it is kept the minimal possible to avoid breaking the size limit.
 */
interface IRMRKDeployer {
    /**
     * @notice Deploys a new collection.
     * @param name Name of the token collection
     * @param symbol Symbol of the token collection
     * @param collectionMetadata CID of the collection metadata
     * @param maxSupply The maximum supply of tokens
     * @param royaltyRecipient Recipient of resale royalties
     * @param royaltyPercentageBps The percentage to be paid from the sale of the token expressed in basis points
     * @param initialAssetsMetadata Array with metadata of the initial assets which will be added into every minted token
     */
    function deployCollection(
        string memory name,
        string memory symbol,
        string memory collectionMetadata,
        uint256 maxSupply,
        address collectionOwner,
        address royaltyRecipient,
        uint16 royaltyPercentageBps,
        string[] memory initialAssetsMetadata
    ) external returns (address newCollection);
}
