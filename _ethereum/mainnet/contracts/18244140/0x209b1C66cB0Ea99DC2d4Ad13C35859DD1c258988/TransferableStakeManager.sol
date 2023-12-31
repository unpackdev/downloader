// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./StakeStarter.sol";
import "./IStakeReceiver.sol";

contract TransferableStakeManager is StakeStarter {
  event TransferStake(address from, address to, uint256 stakeId);
  /**
   * removes transfer abilities from a stake
   * @param stakeId the stake that the sender owns and wishes to remove transfer abilities from
   */
  function removeTransferrability(uint256 stakeId) external payable returns(uint256 settings) {
    return _removeTransferrability({
      stakeId: stakeId
    });
  }
  /**
   * removes transfer abilities from a stake
   * @param stakeId the stake that the sender owns and wishes to remove transfer abilities from
   */
  function _removeTransferrability(uint256 stakeId) internal returns(uint256 settings) {
    _verifyStakeOwnership({
      owner: msg.sender,
      stakeId: stakeId
    });
    settings = stakeIdToSettings[stakeId];
    settings = _removeTransferrabilityFromEncodedSettings(settings);
    _logSettingsUpdate({
      stakeId: stakeId,
      settings: settings
    });
  }
  /**
   * rewrite encoded settings to remove the transferable flag and leave all other settings in tact
   * @param settings encoded settings to rewrite without a transferable flag
   */
  function removeTransferrabilityFromEncodedSettings(uint256 settings) external pure returns(uint256) {
    return _removeTransferrabilityFromEncodedSettings(settings);
  }
  /**
   * rewrite encoded settings to remove the transferable flag and leave all other settings in tact
   * @param settings encoded settings to rewrite without a transferable flag
   */
  function _removeTransferrabilityFromEncodedSettings(uint256 settings) internal pure returns(uint256) {
    unchecked {
      return (
        (settings >> INDEX_RIGHT_COPY_EXTERNAL_TIPS << INDEX_RIGHT_COPY_EXTERNAL_TIPS)
        | (settings << INDEX_LEFT_STAKE_IS_TRANSFERABLE >> INDEX_LEFT_STAKE_IS_TRANSFERABLE) // wipe transferable
      );
    }
  }
  /**
   * check if a given stake under a stake id can be transferred
   * @param stakeId the stake id to check transferrability settings
   */
  function canTransfer(uint256 stakeId) external view returns(bool) {
    return _canTransfer({
      stakeId: stakeId
    });
  }
  /**
   * check if a given stake under a stake id can be transferred
   * @param stakeId the stake id to check transferrability settings
   */
  function _canTransfer(uint256 stakeId) internal view returns(bool) {
    return _isOneAtIndex({
      settings: stakeIdToSettings[stakeId],
      index: INDEX_RIGHT_STAKE_IS_TRANSFERABLE
    });
  }
  /**
   * transfer a stake from one owner to another
   * @param stakeId the stake id to transfer
   * @param to the account to receive the stake
   * @dev this method is only payable to reduce gas costs.
   * Any value sent to this method will be unattributed
   */
  function stakeTransfer(uint256 stakeId, address to) external payable {
    _verifyStakeOwnership({
      owner: msg.sender,
      stakeId: stakeId
    });
    if (!_canTransfer({ stakeId: stakeId })) {
      revert NotAllowed();
    }
    (uint256 index, ) = _stakeIdToInfo({
      stakeId: stakeId
    });
    stakeIdInfo[stakeId] = _encodeInfo({
      index: index,
      owner: to
    });
    if (tipStakeIdToStaker[stakeId] != address(0)) {
      tipStakeIdToStaker[stakeId] = to;
    }
    (bool success, bytes memory data) = to.call(
      abi.encodeCall(IStakeReceiver.onStakeReceived, (msg.sender, stakeId))
    );
    if (!success) {
      _bubbleRevert(data);
    }
    emit TransferStake({
      from: msg.sender,
      to: to,
      stakeId: stakeId
    });
  }
}
