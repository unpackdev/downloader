// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";

import "./IVerifier.sol";

contract PoofBase {
  using SafeMath for uint256;

  IVerifier public depositVerifier;
  IVerifier public withdrawVerifier;
  IVerifier public inputRootVerifier;
  IVerifier public outputRootVerifier;
  IVerifier public treeUpdateVerifier;

  mapping(bytes32 => bool) public accountNullifiers;

  uint256 public accountCount;
  uint256 public constant ACCOUNT_ROOT_HISTORY_SIZE = 100;
  bytes32[ACCOUNT_ROOT_HISTORY_SIZE] public accountRoots;

  event NewAccount(bytes32 commitment, bytes32 nullifier, bytes encryptedAccount, uint256 index);

  struct TreeUpdateArgs {
    bytes32 oldRoot;
    bytes32 newRoot;
    bytes32 leaf;
    uint256 pathIndices;
  }

  struct AccountUpdate {
    bytes32 inputRoot;
    bytes32 inputNullifierHash;
    bytes32 inputAccountHash;
    bytes32 outputRoot;
    uint256 outputPathIndices;
    bytes32 outputCommitment;
    bytes32 outputAccountHash;
  }

  struct DepositExtData {
    bytes encryptedAccount;
  }

  struct DepositArgs {
    uint256 amount;
    uint256 debt;
    uint256 unitPerUnderlying;
    bytes32 extDataHash;
    DepositExtData extData;
    AccountUpdate account;
  }

  struct WithdrawExtData {
    uint256 fee;
    address recipient;
    address relayer;
    bytes encryptedAccount;
  }

  struct WithdrawArgs {
    uint256 amount;
    uint256 debt;
    uint256 unitPerUnderlying;
    bytes32 extDataHash;
    WithdrawExtData extData;
    AccountUpdate account;
  }

  constructor(
    IVerifier[5] memory _verifiers,
    bytes32 _accountRoot
  ) {
    accountRoots[0] = _accountRoot;
    depositVerifier = _verifiers[0];
    withdrawVerifier = _verifiers[1];
    inputRootVerifier = _verifiers[2];
    outputRootVerifier = _verifiers[3];
    treeUpdateVerifier = _verifiers[4];
  }

  function toDynamicArray(uint256[3] memory arr) internal pure returns (uint256[] memory) {
    uint256[] memory res = new uint256[](3);
    uint256 length = arr.length;
    for (uint i = 0; i < length; i++) {
      res[i] = arr[i];
    }
    return res;
  }

  function toDynamicArray(uint256[4] memory arr) internal pure returns (uint256[] memory) {
    uint256[] memory res = new uint256[](4);
    uint256 length = arr.length;
    for (uint i = 0; i < length; i++) {
      res[i] = arr[i];
    }
    return res;
  }

  function toDynamicArray(uint256[5] memory arr) internal pure returns (uint256[] memory) {
    uint256[] memory res = new uint256[](5);
    uint256 length = arr.length;
    for (uint i = 0; i < length; i++) {
      res[i] = arr[i];
    }
    return res;
  }

  function toDynamicArray(uint256[6] memory arr) internal pure returns (uint256[] memory) {
    uint256[] memory res = new uint256[](6);
    uint256 length = arr.length;
    for (uint i = 0; i < length; i++) {
      res[i] = arr[i];
    }
    return res;
  }

  function beforeDeposit(
    bytes[3] memory _proofs,
    DepositArgs memory _args,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) internal {
    validateAccountUpdate(_args.account, _treeUpdateProof, _treeUpdateArgs);
    require(_args.extDataHash == keccak248(abi.encode(_args.extData)), "Incorrect external data hash");
    require(_args.unitPerUnderlying >= unitPerUnderlying(), "Underlying per unit is overstated");
    require(
      depositVerifier.verifyProof(
        _proofs[0],
        toDynamicArray([
          uint256(_args.amount),
          uint256(_args.debt),
          uint256(_args.unitPerUnderlying),
          uint256(_args.extDataHash),
          uint256(_args.account.inputAccountHash),
          uint256(_args.account.outputAccountHash)
        ])
      ),
      "Invalid deposit proof"
    );
    require(
      inputRootVerifier.verifyProof(
        _proofs[1],
        toDynamicArray([
          uint256(_args.account.inputRoot),
          uint256(_args.account.inputNullifierHash),
          uint256(_args.account.inputAccountHash)
        ])
      ),
      "Invalid input root proof"
    );
    require(
      outputRootVerifier.verifyProof(
        _proofs[2],
        toDynamicArray([
          uint256(_args.account.inputRoot),
          uint256(_args.account.outputRoot),
          uint256(_args.account.outputPathIndices),
          uint256(_args.account.outputCommitment),
          uint256(_args.account.outputAccountHash)
        ])
      ),
      "Invalid output root proof"
    );

    accountNullifiers[_args.account.inputNullifierHash] = true;
    insertAccountRoot(_args.account.inputRoot == getLastAccountRoot() ? _args.account.outputRoot : _treeUpdateArgs.newRoot);

    emit NewAccount(
      _args.account.outputCommitment,
      _args.account.inputNullifierHash,
      _args.extData.encryptedAccount,
      accountCount - 1
    );
  }

  function beforeWithdraw(
    bytes[3] memory _proofs,
    WithdrawArgs memory _args,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) internal {
    validateAccountUpdate(_args.account, _treeUpdateProof, _treeUpdateArgs);
    require(_args.extDataHash == keccak248(abi.encode(_args.extData)), "Incorrect external data hash");
    // Input check because zkSNARKs work modulo p
    require(_args.amount < 2**248, "Amount value out of range");
    require(_args.debt < 2**248, "Debt value out of range");
    require(_args.amount >= _args.extData.fee, "Amount should be >= than fee");
    require(_args.unitPerUnderlying >= unitPerUnderlying(), "Underlying per unit is overstated");
    require(
      withdrawVerifier.verifyProof(
        _proofs[0],
        toDynamicArray([
          uint256(_args.amount),
          uint256(_args.debt),
          uint256(_args.unitPerUnderlying),
          uint256(_args.extDataHash),
          uint256(_args.account.inputAccountHash),
          uint256(_args.account.outputAccountHash)
        ])
      ),
      "Invalid withdrawal proof"
    );
    require(
      inputRootVerifier.verifyProof(
        _proofs[1],
        toDynamicArray([
          uint256(_args.account.inputRoot),
          uint256(_args.account.inputNullifierHash),
          uint256(_args.account.inputAccountHash)
        ])
      ),
      "Invalid input root proof"
    );
    require(
      outputRootVerifier.verifyProof(
        _proofs[2],
        toDynamicArray([
          uint256(_args.account.inputRoot),
          uint256(_args.account.outputRoot),
          uint256(_args.account.outputPathIndices),
          uint256(_args.account.outputCommitment),
          uint256(_args.account.outputAccountHash)
        ])
      ),
      "Invalid output root proof"
    );

    insertAccountRoot(_args.account.inputRoot == getLastAccountRoot() ? _args.account.outputRoot : _treeUpdateArgs.newRoot);
    accountNullifiers[_args.account.inputNullifierHash] = true;

    emit NewAccount(
      _args.account.outputCommitment,
      _args.account.inputNullifierHash,
      _args.extData.encryptedAccount,
      accountCount - 1
    );
  }

  // ------VIEW-------

  /**
    @dev Whether the root is present in the root history
    */
  function isKnownAccountRoot(bytes32 _root, uint256 _index) public view returns (bool) {
    return _root != 0 && accountRoots[_index % ACCOUNT_ROOT_HISTORY_SIZE] == _root;
  }

  /**
    @dev Returns the last root
    */
  function getLastAccountRoot() public view returns (bytes32) {
    return accountRoots[accountCount % ACCOUNT_ROOT_HISTORY_SIZE];
  }

  function unitPerUnderlying() public view virtual returns (uint256) {
    return 1;
  }

  // -----INTERNAL-------

  function keccak248(bytes memory _data) internal pure returns (bytes32) {
    return keccak256(_data) & 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  }

  function validateTreeUpdate(
    bytes memory _proof,
    TreeUpdateArgs memory _args,
    bytes32 _commitment
  ) internal view {
    require(_proof.length > 0, "Outdated account merkle root");
    require(_args.oldRoot == getLastAccountRoot(), "Outdated tree update merkle root");
    require(_args.leaf == _commitment, "Incorrect commitment inserted");
    require(_args.pathIndices == accountCount, "Incorrect account insert index");
    require(
      treeUpdateVerifier.verifyProof(
        _proof,
        toDynamicArray([uint256(_args.oldRoot), uint256(_args.newRoot), uint256(_args.leaf), uint256(_args.pathIndices)])
      ),
      "Invalid tree update proof"
    );
  }

  function validateAccountUpdate(
    AccountUpdate memory _account,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) internal view {
    // Has to be a new nullifier hash
    require(!accountNullifiers[_account.inputNullifierHash], "Outdated account state");
    if (_account.inputRoot != getLastAccountRoot()) {
      // _account.outputPathIndices (= last tree leaf index) is always equal to root index in the history mapping
      // because we always generate a new root for each new leaf
      require(isKnownAccountRoot(_account.inputRoot, _account.outputPathIndices), "Invalid account root");
      validateTreeUpdate(_treeUpdateProof, _treeUpdateArgs, _account.outputCommitment);
    } else {
      require(_account.outputPathIndices == accountCount, "Incorrect account insert index");
    }
  }

  function insertAccountRoot(bytes32 _root) internal {
    accountRoots[++accountCount % ACCOUNT_ROOT_HISTORY_SIZE] = _root;
  }
}
