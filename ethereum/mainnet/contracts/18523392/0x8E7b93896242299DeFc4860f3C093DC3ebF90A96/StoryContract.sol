// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/*//////////////////////////////////////////////////////////////////////////
                            Imports
//////////////////////////////////////////////////////////////////////////*/

import "./ERC165.sol";
import "./IStory.sol";

/*//////////////////////////////////////////////////////////////////////////
                            Story Contract
//////////////////////////////////////////////////////////////////////////*/

/// @title Story Contract
/// @dev standalone, inheritable abstract contract implementing the Story Contract interface
/// @author transientlabs.xyz
/// @custom:version 4.0.2
abstract contract StoryContract is IStory, ERC165 {
    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    bool public storyEnabled;

    /*//////////////////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////////////////*/

    modifier storyMustBeEnabled() {
        if (!storyEnabled) revert StoryNotEnabled();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////////////////*/

    /// @param enabled - a boolean to enable or disable Story additions
    constructor(bool enabled) {
        storyEnabled = enabled;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Story Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev function to set story enabled/disabled
    /// @dev requires story admin
    /// @param enabled - a boolean setting to enable or disable Story additions
    function setStoryEnabled(bool enabled) external {
        if (!_isStoryAdmin(msg.sender)) revert NotStoryAdmin();
        storyEnabled = enabled;
    }

    /// @inheritdoc IStory
    function addCreatorStory(uint256 tokenId, string calldata creatorName, string calldata story)
        public
        storyMustBeEnabled
    {
        if (!_tokenExists(tokenId)) revert TokenDoesNotExist();
        if (!_isCreator(msg.sender, tokenId)) revert NotTokenCreator();

        emit CreatorStory(tokenId, msg.sender, creatorName, story);
    }

    /// @inheritdoc IStory
    function addStory(uint256 tokenId, string calldata collectorName, string calldata story)
        external
        storyMustBeEnabled
    {
        if (!_tokenExists(tokenId)) revert TokenDoesNotExist();
        if (!_isTokenOwner(msg.sender, tokenId)) revert NotTokenOwner();

        emit Story(tokenId, msg.sender, collectorName, story);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Hooks
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev function to allow access to enabling/disabling story
    /// @param potentialAdmin - the address to check for admin priviledges
    function _isStoryAdmin(address potentialAdmin) internal view virtual returns (bool);

    /// @dev function to check if a token exists on the token contract
    /// @param tokenId - the token id to check for existence
    function _tokenExists(uint256 tokenId) internal view virtual returns (bool);

    /// @dev function to check ownership of a token
    /// @param potentialOwner - the address to check for ownership of `tokenId`
    /// @param tokenId - the token id to check ownership against
    function _isTokenOwner(address potentialOwner, uint256 tokenId) internal view virtual returns (bool);

    /// @dev function to check creatorship of a token
    /// @param potentialCreator - the address to check creatorship of `tokenId`
    /// @param tokenId - the token id to check creatorship against
    function _isCreator(address potentialCreator, uint256 tokenId) internal view virtual returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                                Overrides
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165) returns (bool) {
        return interfaceId == type(IStory).interfaceId || ERC165.supportsInterface(interfaceId);
    }
}