// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title IDynamicAttributesV1
 * @author @NFTMike | @NFTCulture
 * @dev Interface for defining the structure of DynamicAttributes objects.
 *
 * This interface should capture all of the data relevant to a group of tokens being
 * stored entirely on-chain.
 *
 * The interface is designed to allow the metadata to be modified and updated as needed.
 *
 * Besides the 'isAnimated' attribute, the interface is designed to be decoupled from
 * the artwork scheme implemented for the related tokens. 'isAnimated' is just used
 * as a cleaner and more deliberate approach than checking string length of an animation.
 */
interface IDynamicAttributesV1 {
    struct DynamicAttributesV1 {
        uint256 tokenType;
        bool isSerialized;
        bool isAnimated;
        bool hasTokenDescription;
        string title;
        string tokenDescription;
        string[] attributeNames;
        string[] attributeValues;
    }
}
