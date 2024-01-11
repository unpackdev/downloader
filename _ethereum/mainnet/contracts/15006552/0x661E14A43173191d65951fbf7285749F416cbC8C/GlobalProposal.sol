// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Proposal.sol";

library GlobalProposal {
  using ECDSA for bytes32;

  enum TargetOption {
    ValidatorContract,
    GatewayContract
  }

  struct GlobalProposalDetail {
    // Nonce to make sure proposals are executed in order
    uint256 nonce;
    TargetOption[] targetOptions;
    uint256[] values;
    bytes[] calldatas;
  }

  // keccak256("GlobalProposalDetail(uint256 nonce,uint8[] targetOptions,uint256[] values,bytes[] calldatas)");
  bytes32 public constant TYPE_HASH = 0x8c10622d37fe38aa1986961664ce56d7fc08fb17822e2161bf993b3077ef3e35;

  /**
   * @dev Returns struct hash of the proposal.
   */
  function hash(GlobalProposalDetail memory _proposal) internal pure returns (bytes32) {
    bytes32 _targetsHash;
    bytes32 _valuesHash;
    bytes32 _calldatasHash;

    uint256[] memory _values = _proposal.values;
    TargetOption[] memory _targets = _proposal.targetOptions;
    bytes32[] memory _calldataHashList = new bytes32[](_proposal.calldatas.length);
    for (uint256 _i; _i < _calldataHashList.length; _i++) {
      _calldataHashList[_i] = keccak256(_proposal.calldatas[_i]);
    }

    assembly {
      _targetsHash := keccak256(add(_targets, 32), mul(mload(_targets), 32))
      _valuesHash := keccak256(add(_values, 32), mul(mload(_values), 32))
      _calldatasHash := keccak256(add(_calldataHashList, 32), mul(mload(_calldataHashList), 32))
    }

    return keccak256(abi.encode(TYPE_HASH, _proposal.nonce, _targetsHash, _valuesHash, _calldatasHash));
  }

  /**
   * @dev Converts into the normal proposal.
   */
  function into_proposal_detail(
    GlobalProposalDetail memory _proposal,
    address _validatorContract,
    address _gatewayContract
  ) internal pure returns (Proposal.ProposalDetail memory _detail) {
    _detail.nonce = _proposal.nonce;
    _detail.chainId = 0;
    _detail.targets = new address[](_proposal.targetOptions.length);
    _detail.values = _proposal.values;
    _detail.calldatas = _proposal.calldatas;

    for (uint256 _i; _i < _proposal.targetOptions.length; _i++) {
      if (_proposal.targetOptions[_i] == TargetOption.GatewayContract) {
        _detail.targets[_i] = _gatewayContract;
      } else if (_proposal.targetOptions[_i] == TargetOption.ValidatorContract) {
        _detail.targets[_i] = _validatorContract;
      } else {
        revert("GlobalProposal: unsupported target");
      }
    }
  }
}
