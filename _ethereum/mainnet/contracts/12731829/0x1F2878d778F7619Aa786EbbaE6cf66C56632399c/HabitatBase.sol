// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./NutBerryFlavorV1.sol";
import "./UpgradableRollup.sol";

/// @notice Global state and public utiltiy functions for the Habitat Rollup
// Audit-1: ok
contract HabitatBase is NutBerryFlavorV1, UpgradableRollup {
  // Useful for fetching (compressed) metadata about a specific topic.
  event MetadataUpdated(uint256 indexed topic, bytes metadata);

  /// @dev The maximum time drift between the time of block submission and a proposal's start date.
  /// This is here to avoid keeping proposals off-chain, accumulating votes and finalizing the proposal
  /// all at once on block submission without anyone being aware of it.
  function _PROPOSAL_DELAY () internal pure virtual returns (uint256) {
    // in seconds - 32 hrs
    return 3600 * 32;
  }

  function EPOCH_GENESIS () public pure virtual returns (uint256) {
  }

  function SECONDS_PER_EPOCH () public pure virtual returns (uint256) {
  }

  /// @notice The divisor for every tribute. A fraction of the operator tribute always goes into the staking pool.
  function STAKING_POOL_FEE_DIVISOR () public pure virtual returns (uint256) {
  }

  /// @dev Includes common checks for rollup transactions.
  function _commonChecks () internal view {
    // only allow calls from self
    require(msg.sender == address(this));
  }

  /// @dev Verifies and updates the account nonce for `msgSender`.
  function _checkUpdateNonce (address msgSender, uint256 nonce) internal {
    require(nonce == txNonces(msgSender), 'NONCE');

    _incrementStorage(_TX_NONCE_KEY(msgSender));
  }

  /// @dev Helper function to calculate a unique seed. Primarily used for deriving addresses.
  function _calculateSeed (address msgSender, uint256 nonce) internal pure returns (bytes32 ret) {
    assembly {
      mstore(0, msgSender)
      mstore(32, nonce)
      ret := keccak256(0, 64)
    }
  }

  // Storage helpers, functions will be replaced with special getters/setters to retrieve/store on the rollup
  /// @dev Increments `key` by `value`. Reverts on overflow or if `value` is zero.
  function _incrementStorage (uint256 key, uint256 value) internal returns (uint256 newValue) {
    uint256 oldValue = _sload(key);
    newValue = oldValue + value;
    require(newValue >= oldValue, 'INCR');
    _sstore(key, newValue);
  }

  function _incrementStorage (uint256 key) internal returns (uint256 newValue) {
    newValue = _incrementStorage(key, 1);
  }

  /// @dev Decrements `key` by `value`. Reverts on underflow or if `value` is zero.
  function _decrementStorage (uint256 key, uint256 value) internal returns (uint256 newValue) {
    uint256 oldValue = _sload(key);
    newValue = oldValue - value;
    require(newValue <= oldValue, 'DECR');
    _sstore(key, newValue);
  }

  function _getStorage (uint256 key) internal returns (uint256 ret) {
    return _sload(key);
  }

  function _setStorage (uint256 key, uint256 value) internal {
    _sstore(key, value);
  }

  function _setStorage (uint256 key, bytes32 value) internal {
    _sstore(key, uint256(value));
  }

  function _setStorage (uint256 key, address value) internal {
    _sstore(key, uint256(value));
  }

  /// @dev Helper for `_setStorage`. Writes `uint256(-1)` if `value` is zero.
  function _setStorageInfinityIfZero (uint256 key, uint256 value) internal {
    if (value == 0) {
      value = uint256(-1);
    }

    _setStorage(key, value);
  }

  /// @dev Decrements storage for `key` if `a > b` else increments the delta between `a` and `b`.
  /// Reverts on over-/underflow and if `a` equals `b`.
  function _setStorageDelta (uint256 key, uint256 a, uint256 b) internal {
    uint256 newValue;
    {
      uint256 oldValue = _sload(key);
      if (a > b) {
        uint256 delta = a - b;
        newValue = oldValue - delta;
        require(newValue < oldValue, 'DECR');
      } else {
        uint256 delta = b - a;
        newValue = oldValue + delta;
        require(newValue > oldValue, 'INCR');
      }
    }
    _sstore(key, newValue);
  }
  // end of storage helpers

  function _TX_NONCE_KEY (address a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x1baf1b358a7f0088724e8c8008c24c8182cafadcf6b7d0da2db2b55b40320fbf)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _ERC20_KEY (address tkn, address account) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x24de14bddef9089376483557827abada7f1c6135d6d379c3519e56e7bc9067b9)
      mstore(32, tkn)
      let tmp := mload(64)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _ERC721_KEY (address tkn, uint256 b) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x0b0adec1d909ec867fdb1853ca8d859f7b8137ab9c01f734b3fbfc40d9061ded)
      mstore(32, tkn)
      let tmp := mload(64)
      mstore(64, b)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _VOTING_SHARES_KEY (bytes32 proposalId, address account) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x24ce236379086842ae19f4302972c7dd31f4c5054826cd3e431fd503205f3b67)
      mstore(32, proposalId)
      let tmp := mload(64)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _VOTING_SIGNAL_KEY (bytes32 proposalId, address account) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x12bc1ed237026cb917edecf1ca641d1047e3fc382300e8b3fab49ae10095e490)
      mstore(32, proposalId)
      let tmp := mload(64)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _VOTING_COUNT_KEY (bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x637730e93bbd8200299f72f559c841dfae36a36f86ace777eac8fe48f977a46d)
      mstore(32, proposalId)
      ret := keccak256(0, 64)
    }
  }

  function _VOTING_TOTAL_SHARE_KEY (bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x847f5cbc41e438ef8193df4d65950ec6de3a1197e7324bffd84284b7940b2d4a)
      mstore(32, proposalId)
      ret := keccak256(0, 64)
    }
  }

  function _VOTING_TOTAL_SIGNAL_KEY (bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x3a5afbb81b36a1a15e90db8cc0deb491bf6379592f98c129fd8bdf0b887f82dc)
      mstore(32, proposalId)
      ret := keccak256(0, 64)
    }
  }

  function _MEMBER_OF_COMMUNITY_KEY (bytes32 communityId, address account) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x0ff6c2ccfae404e7ec55109209ac7c793d30e6818af453a7c519ca59596ccde1)
      mstore(32, communityId)
      let tmp := mload(64)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _MEMBERS_TOTAL_COUNT_KEY (bytes32 communityId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xe1338c6a5be626513cff1cb54a827862ae2ab4810a79c8dfd1725e69363f4247)
      mstore(32, communityId)
      ret := keccak256(0, 64)
    }
  }

  function _NAME_TO_ADDRESS_KEY (bytes32 shortString) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x09ec9a99acfe90ba324ac042a90e28c5458cfd65beba073b0a92ea7457cdfc56)
      mstore(32, shortString)
      ret := keccak256(0, 64)
    }
  }

  function _ADDRESS_TO_NAME_KEY (address account) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x83cb99259282c2842186d0db03ab6fdfc530b2afa0eb2a4fe480c4815a5e1f34)
      mstore(32, account)
      ret := keccak256(0, 64)
    }
  }

  function _PROPOSAL_VAULT_KEY (bytes32 a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x622061f2b694ba7aa754d63e7f341f02ac8341e2b36ccbb1d3fc1bf00b57162d)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _PROPOSAL_START_DATE_KEY (bytes32 a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x539a579b21c2852f7f3a22630162ab505d3fd0b33d6b46f926437d8082d494c1)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _TOKEN_OF_COMMUNITY_KEY (bytes32 a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xeadaeda4a4005f296730d16d047925edeb6f21ddc028289ebdd9904f9d65a662)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _COMMUNITY_OF_VAULT_KEY (address a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xf659eca1f5df040d1f35ff0bac6c4cd4017c26fe0dbe9317b2241af59edbfe06)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _MODULE_HASH_KEY (address a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xe6ab7761f522dca2c6f74f7f7b1083a1b184fec6b893cb3418cb3121c5eda5aa)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _VAULT_CONDITION_KEY (address a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x615e61b2f7f9d8ca18a90a9b0d27a62ae27581219d586cb9aeb7c695bc7b92c8)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _PROPOSAL_STATUS_KEY (bytes32 a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x40e11895caf89e87d4485af91bd7e72b6a6e56b94f6ea4b7edb16e869adb7fe9)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _TOKEN_TVL_KEY (address a) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x4e7484f055e36257052a570831d7e3114ad145e0c8d8de63ded89925c7e17cb6)
      mstore(32, a)
      ret := keccak256(0, 64)
    }
  }

  function _PROPOSAL_HASH_INTERNAL_KEY (bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x9f6ffbe6bd26bda84ec854c7775d819340fd4340bc8fa1ab853cdee0d60e7141)
      mstore(32, proposalId)
      ret := keccak256(0, 64)
    }
  }

  function _PROPOSAL_HASH_EXTERNAL_KEY (bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0xcd566f7f1fd69d79df8b7e0a3e28a2b559ab3e7f081db4a0c0640de4db78de9a)
      mstore(32, proposalId)
      ret := keccak256(0, 64)
    }
  }

  function _EXECUTION_PERMIT_KEY (address vault, bytes32 proposalId) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x8d47e278a5e048b636a1e1724246c4617684aff8b922d0878d0da2fb553d104e)
      mstore(32, vault)
      mstore(64, proposalId)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  function _VOTING_ACTIVE_STAKE_KEY (address token, address account) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x2a8a915836beef625eda7be8c32e4f94152e89551893f0eae870e80cab73c496)
      mstore(32, token)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  /// @dev Tracks account owner > delegatee allowance for `token`
  function _DELEGATED_ACCOUNT_ALLOWANCE_KEY (address account, address delegatee, address token) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0xf8affafdc89531391d5ba543f3f243d05d9f0325e7bebb13e50d0158dfe7ff74)
      mstore(32, account)
      mstore(64, delegatee)
      mstore(96, token)
      ret := keccak256(0, 128)
      mstore(64, backup)
      mstore(96, 0)
    }
  }

  /// @dev Tracks account owner > total delegated amount of `token`.
  function _DELEGATED_ACCOUNT_TOTAL_ALLOWANCE_KEY (address account, address token) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x5f823da33b83835d30bb64c6b6539db24009aecef661452e8903ad12aee6bf8d)
      mstore(32, account)
      mstore(64, token)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  /// @dev Tracks delegatee > total delegated amount of `token`.
  function _DELEGATED_ACCOUNT_TOTAL_AMOUNT_KEY (address delegatee, address token) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x82dffec7bb13e333bbe061529a9dc24cdad0f5d0900f144abb0bf82b70e68452)
      mstore(32, delegatee)
      mstore(64, token)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  function _DELEGATED_VOTING_SHARES_KEY (bytes32 proposalId, address delegatee) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x846d3c69e4bfb41c345a501556d4ab5cfb40fa2bbfa478d2d6863adb6a612ce7)
      mstore(32, proposalId)
      let tmp := mload(64)
      mstore(64, delegatee)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _DELEGATED_VOTING_SIGNAL_KEY (bytes32 proposalId, address delegatee) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x785294304b174fede6de17c61b65e5b77d3e5ad5a71821b78dad3e2dab50d10f)
      mstore(32, proposalId)
      let tmp := mload(64)
      mstore(64, delegatee)
      ret := keccak256(0, 96)
      mstore(64, tmp)
    }
  }

  function _DELEGATED_VOTING_ACTIVE_STAKE_KEY (address token, address delegatee) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0xbe24be1148878e5dc0cfaecb52c8dd418ecc98483a44968747d43843653a5754)
      mstore(32, token)
      mstore(64, delegatee)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  /// @dev The last total value locked of `token` in `epoch`.
  function _STAKING_EPOCH_TVL_KEY (uint256 epoch, address token) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x8975800e5c219c77b3263a2c64fd28d02cabe02e45f8f9463d035b3c1aae8a62)
      mstore(32, epoch)
      mstore(64, token)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  /// @dev The last total user balance for `account` in `epoch` of `token`.
  function _STAKING_EPOCH_TUB_KEY (uint256 epoch, address token, address account) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x6094318105f3510ea893d7758a4f394f18bfa74ee039be1ce39d67a0ab12524c)
      mstore(32, epoch)
      mstore(64, token)
      mstore(96, account)
      ret := keccak256(0, 128)
      mstore(64, backup)
      mstore(96, 0)
    }
  }

  function _STAKING_EPOCH_LAST_CLAIMED_KEY (address token, address account) internal pure returns (uint256 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x6094318105f3510ea893d7758a4f394f18bfa74ee039be1ce39d67a0ab12524f)
      mstore(32, token)
      mstore(64, account)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  /// @notice Execution permit for <vault, proposalId> = keccak256(actions).
  function executionPermit (address vault, bytes32 proposalId) external virtual view returns (bytes32 ret) {
    uint256 key = _EXECUTION_PERMIT_KEY(vault, proposalId);
    assembly {
      ret := sload(key)
    }
  }

  /// @dev Setter for `executionPermit`.
  /// Reflects the storage slot for `executionPermit` on L1.
  function _setExecutionPermit (address vault, bytes32 proposalId, bytes32 hash) internal {
    bytes32 key = bytes32(_EXECUTION_PERMIT_KEY(vault, proposalId));
    _setStorageL1(key, uint256(hash));
  }

  /// @dev Updates the member count for the community if `account` is a new member.
  function _maybeUpdateMemberCount (bytes32 proposalId, address account) internal {
    address vault = address(_getStorage(_PROPOSAL_VAULT_KEY(proposalId)));
    bytes32 communityId = communityOfVault(vault);
    if (_getStorage(_MEMBER_OF_COMMUNITY_KEY(communityId, account)) == 0) {
      _setStorage(_MEMBER_OF_COMMUNITY_KEY(communityId, account), 1);
      _incrementStorage(_MEMBERS_TOTAL_COUNT_KEY(communityId));
    }
  }

  /// @notice The nonce of account `a`.
  function txNonces (address a) public virtual returns (uint256) {
    uint256 key = _TX_NONCE_KEY(a);
    return _sload(key);
  }

  /// @notice The token balance of `tkn` for `account. This works for ERC-20 and ERC-721.
  function getBalance (address tkn, address account) public virtual returns (uint256) {
    uint256 key = _ERC20_KEY(tkn, account);
    return _sload(key);
  }

  /// @notice Returns the owner of a ERC-721 token.
  function getErc721Owner (address tkn, uint256 b) public virtual returns (address) {
    uint256 key = _ERC721_KEY(tkn, b);
    return address(_sload(key));
  }

  /// @notice Returns the cumulative voted shares on `proposalId`.
  function getTotalVotingShares (bytes32 proposalId) public returns (uint256) {
    uint256 key = _VOTING_TOTAL_SHARE_KEY(proposalId);
    return _sload(key);
  }

  /// @notice Returns the member count for `communityId`.
  /// An account automatically becomes a member if it interacts with community vaults & proposals.
  function getTotalMemberCount (bytes32 communityId) public returns (uint256) {
    uint256 key = _MEMBERS_TOTAL_COUNT_KEY(communityId);
    return _sload(key);
  }

  /// @notice Governance Token of community.
  function tokenOfCommunity (bytes32 a) public virtual returns (address) {
    uint256 key = _TOKEN_OF_COMMUNITY_KEY(a);
    return address(_sload(key));
  }

  /// @notice Returns the `communityId` of `vault`.
  function communityOfVault (address vault) public virtual returns (bytes32) {
    uint256 key = _COMMUNITY_OF_VAULT_KEY(vault);
    return bytes32(_sload(key));
  }

  /// @notice Returns the voting status of proposal id `a`.
  function getProposalStatus (bytes32 a) public virtual returns (uint256) {
    uint256 key = _PROPOSAL_STATUS_KEY(a);
    return _sload(key);
  }

  function getTotalValueLocked (address token) public virtual returns (uint256) {
    uint256 key = _TOKEN_TVL_KEY(token);
    return _sload(key);
  }

  function getActiveVotingStake (address token, address account) public returns (uint256) {
    uint256 key = _VOTING_ACTIVE_STAKE_KEY(token, account);
    return _sload(key);
  }

  function getActiveDelegatedVotingStake (address token, address account) public returns (uint256) {
    uint256 key = _DELEGATED_VOTING_ACTIVE_STAKE_KEY(token, account);
    return _sload(key);
  }

  function _secondsUntilNextEpoch () internal virtual returns (uint256) {
    uint256 genesis = EPOCH_GENESIS();
    return ((SECONDS_PER_EPOCH() - _getTime()) - genesis) % genesis;
  }

  /// @notice Epoch should be greater than 0.
  function getCurrentEpoch () public virtual returns (uint256) {
    return ((_getTime() - EPOCH_GENESIS()) / SECONDS_PER_EPOCH()) + 1;
  }

  /// @notice Used for testing purposes.
  function onModifyRollupStorage (address msgSender, uint256 nonce, bytes calldata data) external virtual {
    revert('OMRS1');
  }

  /// @dev Returns true on Layer 2.
  function _shouldEmitEvents () internal returns (bool ret) {
    assembly {
      ret := iszero(origin())
    }
  }

  function getLastClaimedEpoch (address token, address account) external returns (uint256) {
    return _getStorage(_STAKING_EPOCH_LAST_CLAIMED_KEY(token, account));
  }

  function getHistoricTub (address token, address account, uint256 epoch) external returns (uint256) {
    return _getStorage(_STAKING_EPOCH_TUB_KEY(epoch, token, account));
  }

  function getHistoricTvl (address token, uint256 epoch) external returns (uint256) {
    return _getStorage(_STAKING_EPOCH_TVL_KEY(epoch, token));
  }
}
