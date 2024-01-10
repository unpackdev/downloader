//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC165.sol";

///
/// @dev interface for a holder (owner) of an ERC2981-enabled token
/// @dev to modify the fee amount as well as transfer ownership of
/// @dev royalty to someone else.
///
interface IERC2981Holder {

    /// @dev emitted when the roalty has changed
    event RoyaltyFeeChanged(
        address indexed operator,
        uint256 indexed _id,
        uint256 _fee
    );

    /// @dev emitted when the roalty ownership has been transferred
    event RoyaltyOwnershipTransferred(
        uint256 indexed _id,
        address indexed oldOwner,
        address indexed newOwner
    );

    /// @notice set the fee amount for the fee id
    /// @param _id  the fee id
    /// @param _fee the fee amount
    function setFee(uint256 _id, uint256 _fee) external;

    /// @notice get the fee amount for the fee id
    /// @param _id  the fee id
    /// @return the fee amount
    function getFee(uint256 _id) external returns (uint256);

    /// @notice get the owner address of the royalty
    /// @param _id  the fee id
    /// @return the owner address
    function royaltyOwner(uint256 _id) external returns (address);


    /// @notice transfer ownership of the royalty to someone else
    /// @param _id  the fee id
    /// @param _newOwner  the new owner address
    function transferOwnership(uint256 _id, address _newOwner) external;

}
