//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title ArtistCollectionStorage
/// @author Simon Fremaux (@dievardump)
/// @notice Storage contract for ArtistCollection721
/// @dev This is the Storage of Artist Collection 721 contract
///      This is a contract made to work with upgradeable contract,
///      if you ever add state variables, you must update __gap accordingly.
///      -> https://forum.openzeppelin.com/t/what-exactly-is-the-reason-for-uint256-50-private-gap/798
///      if you do not use Upgradeable contracts, you should comment the line that defines __gap
contract ArtistCollection721Storage {
    uint256 internal nextTokenId;

    /// @dev If you ever add new state variable please add BEFORE this comment, and update __gap accordingly
    /// @dev https://forum.openzeppelin.com/t/what-exactly-is-the-reason-for-uint256-50-private-gap/798
    uint256[50] private __gap;
}
