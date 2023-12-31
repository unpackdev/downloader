// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Magnitude.sol";

contract StakeInfo is Magnitude {
  /**
   * @notice the owner of a stake indexed by the stake id
   * index + 160(owner)
   */
  mapping(uint256 stakeId => uint256 info) public stakeIdInfo;
  /**
   * @notice this error is thrown when the stake in question
   * is not owned by the expected address
   */
  error StakeNotOwned(address provided, address expected);
  error StakeNotCustodied(uint256 stakeId);
  /**
   * verify the ownership of a stake given its id
   * @param owner the supposed owner of the stake
   * @param stakeId the id of the stake in question
   * @notice error occurs if owner does not match
   */
  function verifyStakeOwnership(address owner, uint256 stakeId) external view {
    _verifyStakeOwnership(owner, stakeId);
  }
  /**
   * verify the ownership of a stake given its id
   * @param owner the supposed owner of the stake
   * @param stakeId the id of the stake in question
   * @notice StakeNotOwned error occurs if owner does not match
   */
  function _verifyStakeOwnership(address owner, uint256 stakeId) internal view {
    if (_stakeIdToOwner(stakeId) != owner) {
      revert StakeNotOwned(owner, _stakeIdToOwner(stakeId));
    }
  }
  /**
   * verify that this contract knows the owner of a given stake id
   * and is acting as custodian for said owner
   * @param stakeId the stake id to verify custodialship over
   * @notice StakeNotCustodied error occurs if owner is not known
   */
  function verifyCustodian(uint256 stakeId) external view {
    _verifyCustodian(stakeId);
  }
  /**
   * verify that this contract knows the owner of a given stake id
   * and is acting as custodian for said owner
   * @param stakeId the stake id to verify custodialship over
   * @notice StakeNotCustodied error occurs if owner is not known
   */
  function _verifyCustodian(uint256 stakeId) internal view {
    if (_stakeIdToOwner(stakeId) == address(0)) {
      revert StakeNotCustodied(stakeId);
    }
  }
  /**
   * get the owner of the stake id - the account that has rights over
   * the stake's settings and ability to end it outright
   * @param stakeId the stake id in question
   * @return owner of the stake at the provided id
   * @notice value will be address(0) for unknown
   */
  function stakeIdToOwner(uint256 stakeId) external view returns(address owner) {
    return _stakeIdToOwner(stakeId);
  }
  /**
   * access the owner of a given stake id
   * @param stakeId the stake id in question
   * @return owner of a given stake id
   * @notice value will be address(0) for unknown
   */
  function _stakeIdToOwner(uint256 stakeId) internal view returns(address owner) {
    unchecked {
      return address(uint160(stakeIdInfo[stakeId]));
    }
  }
  /**
   * get the info of a stake given it's id. The index must match
   * the index of the stake in the hex/hedron contract
   * @param stakeId the stake id to get info for
   * @return index of the stake id in the hex list
   * @return owner of the stake
   */
  function stakeIdToInfo(uint256 stakeId) external view returns(uint256 index, address owner) {
    return _stakeIdToInfo(stakeId);
  }
  /**
   * retrieve the index and owner of a stake id
   * @param stakeId the id of the stake in question
   * @return index the index of the stake in the hex list or the hsim list
   * @return owner the owner of the stake
   * @notice for a non custodied stake, the index is 0 and the owner is address(0)
   */
  function _stakeIdToInfo(uint256 stakeId) internal view returns(uint256 index, address owner) {
    uint256 info = stakeIdInfo[stakeId];
    unchecked {
      return (info >> ADDRESS_BIT_LENGTH, address(uint160(info)));
    }
  }
  /**
   * the index of the stake id - useful when indexes are moving around
   * and could be moved by other people
   * @param stakeId the stake id to target
   * @return index of the stake in the targeted list
   */
  function stakeIdToIndex(uint256 stakeId) external view returns(uint256 index) {
    return _stakeIdToIndex(stakeId);
  }
  /**
   * the index of the stake id - useful when indexes are moving around
   * and could be moved by other people
   * @param stakeId the stake id to target
   * @return index of the stake in the targeted list
   */
  function _stakeIdToIndex(uint256 stakeId) internal view returns(uint256 index) {
    unchecked {
      return stakeIdInfo[stakeId] >> ADDRESS_BIT_LENGTH;
    }
  }
  /**
   * encode an index and owner pair to track under a single sload
   * @param index index of a stake
   * @param owner the owner of a stake
   * @return info the encoded uint256 that can be decoded to the index and owner
   */
  function encodeInfo(uint256 index, address owner) external pure returns(uint256 info) {
    return _encodeInfo({
      index: index,
      owner: owner
    });
  }
  /**
   * encode an index and owner pair to track under a single sload
   * @param index index of a stake
   * @param owner the owner of a stake
   * @return info the encoded uint256 that can be decoded to the index and owner
   */
  function _encodeInfo(uint256 index, address owner) internal pure returns(uint256 info) {
    unchecked {
      return (index << ADDRESS_BIT_LENGTH) | uint160(owner);
    }
  }
}
