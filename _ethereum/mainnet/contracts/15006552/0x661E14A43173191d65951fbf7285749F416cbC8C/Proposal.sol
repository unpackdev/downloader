// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";

library Proposal {
  struct ProposalDetail {
    // Nonce to make sure proposals are executed in order
    uint256 nonce;
    // Value 0: all chain should run this proposal
    // Other values: only specifc chain has to execute
    uint256 chainId;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;
  }

  string internal constant _CALL_ERROR_MESSAGE = "Proposal: call reverted without message";
  // keccak256("ProposalDetail(uint256 nonce,uint256 chainId,address[] targets,uint256[] values,bytes[] calldatas)");
  bytes32 public constant TYPE_HASH = 0x1f0b22dae207031fb7f9f05ebbc84b1d9360145aefb92e75009d6d320f1fc95a;

  /**
   * @dev Validates the proposal.
   */
  function validate(ProposalDetail memory _proposal) internal pure {
    require(
      _proposal.targets.length > 0 &&
        _proposal.targets.length == _proposal.values.length &&
        _proposal.targets.length == _proposal.calldatas.length,
      "Proposal: invalid array length"
    );
  }

  /**
   * @dev Returns struct hash of the proposal.
   */
  function hash(ProposalDetail memory _proposal) internal pure returns (bytes32) {
    bytes32 _targetsHash;
    bytes32 _valuesHash;
    bytes32 _calldatasHash;

    uint256[] memory _values = _proposal.values;
    address[] memory _targets = _proposal.targets;
    bytes32[] memory _calldataHashList = new bytes32[](_proposal.calldatas.length);
    for (uint256 _i; _i < _calldataHashList.length; _i++) {
      _calldataHashList[_i] = keccak256(_proposal.calldatas[_i]);
    }

    assembly {
      _targetsHash := keccak256(add(_targets, 32), mul(mload(_targets), 32))
      _valuesHash := keccak256(add(_values, 32), mul(mload(_values), 32))
      _calldatasHash := keccak256(add(_calldataHashList, 32), mul(mload(_calldataHashList), 32))
    }

    return
      keccak256(abi.encode(TYPE_HASH, _proposal.nonce, _proposal.chainId, _targetsHash, _valuesHash, _calldatasHash));
  }

  /**
   * @dev Returns whether the proposal is executable for the current chain.
   *
   * @notice Does not check whether the call result is successful or not. Please use `execute` instead.
   *
   */
  function executable(ProposalDetail memory _proposal) internal view returns (bool _result) {
    return _proposal.chainId == 0 || _proposal.chainId == block.chainid;
  }

  /**
   * @dev Executes the proposal.
   */
  function execute(ProposalDetail memory _proposal) internal {
    require(executable(_proposal), "Proposal: query for invalid chainId");
    for (uint256 i = 0; i < _proposal.targets.length; ++i) {
      (bool _success, bytes memory _returndata) = _proposal.targets[i].call{ value: _proposal.values[i] }(
        _proposal.calldatas[i]
      );
      Address.verifyCallResult(_success, _returndata, _CALL_ERROR_MESSAGE);
    }
  }
}
