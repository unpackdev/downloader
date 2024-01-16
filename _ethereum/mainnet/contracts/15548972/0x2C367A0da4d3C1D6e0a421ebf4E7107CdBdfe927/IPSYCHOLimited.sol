// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title PSYCHO Limited interface
 */
interface IPSYCHOLimited {
    /**
     * @dev Returns bool
     * Avatar generation status
     *
     * `true` active
     * `false` inactive
     */
    function generative(
    ) external view returns (bool);

    /**
     * @dev Returns uint256
     * Generation and extension wei fee
     * multiplied by _quantity
     */
    function fee(
        uint256 _quantity
    ) external view returns (uint256);

    /**
     * @dev Payable transaction
     * Generates up to 20 avatars
     *
     * Requires minimum `fee(_quantity)`
     * and `generative() == true`
     */
    function generate(
        uint256 _quantity
    ) external payable;

    /**
     * @dev Payable transaction
     * Sets custom URI extension for avatar
     *
     * image _select 1
     * animation _select 2
     * image and animation _select 3
     * reset _select 0
     *
     * Requires minimum `fee(1)`
     */
    function extension(
        uint256 _select,
        uint256 _avatarId,
        string memory _image,
        string memory _animation
    ) external payable;

    /**
     * @dev Returns string array
     * The avatar metadata
     *
     * `metadata[0]` image
     * `metadata[1]` animation
     * `metadata[2]` trait
     * `metadata[3]` grade
     */
    function metadata(
        uint256 _avatarId
    ) external view returns (string[4] memory);
}
