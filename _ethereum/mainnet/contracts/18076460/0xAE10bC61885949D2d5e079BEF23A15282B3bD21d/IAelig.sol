// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAelig {

    /*
        @notice Update the store address.
        @dev Can be called only by admins.
        @param _store The new store address.
    */
    function updateStore(address _store) external;

    /*
        @notice Update the tags address.
        @dev Can be called only by admins.
        @param _tags The new tags address.
    */
    function updateTags(address _tags) external;

    /*
        @notice Returns the model for the target frame.
        @param frameId The id of the target frame.
        @return The model associated with the target frame.
    */
    function getModel(uint256 frameId) external view returns(uint256);

    /*
        @notice Create new frames with given model.
        @param model The model of the new frames.
        @param receiver The address that will receive the frames.
        @param quantity The amount of frame that will be created.
    */
    function newFrames(uint256 model, address receiver, uint256 quantity) external;

    /*
        @notice Emitted when a new frame is created.
        @param model The model of the new frame.
        @param id The id of the new frame.
        @param receiver The address that will receive the frame.
    */
    event FramesCreated(uint256 indexed model, uint256 id, address receiver);

    /*
        @notice Emitted when store is updated.
        @param store The new store.
    */
    event StoreUpdated(address store);

    /*
        @notice Emitted when tags address is updated.
        @param tags The new tags address.
    */
    event TagsUpdated(address tags);
}
