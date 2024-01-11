// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./AccessControlEnumerable.sol";
import "./GlobalProposal.sol";
import "./IQuorum.sol";
import "./IWeightedValidator.sol";
import "./ProposalGovernance.sol";
import "./GlobalProposalGovernance.sol";
import "./TransparentUpgradeableProxyV2.sol";

contract GovernanceAdmin is AccessControlEnumerable, ProposalGovernance, GlobalProposalGovernance {
  using Proposal for Proposal.ProposalDetail;
  using GlobalProposal for GlobalProposal.GlobalProposalDetail;

  /// @dev Emitted when the validator contract address is updated.
  event ValidatorContractUpdated(address);
  /// @dev Emitted when the gateway contract address is updated.
  event GatewayContractUpdated(address);

  /// @dev Domain separator
  bytes32 public constant DOMAIN_SEPARATOR = 0xf8704f8860d9e985bf6c52ec4738bd10fe31487599b36c0944f746ea09dc256b;
  /// @dev Relayer role hash
  bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

  /// @dev Validator contract
  address public validatorContract;
  /// @dev Gateway contract
  address public gatewayContract;

  modifier validContract(address _contract) {
    require(
      _contract == validatorContract || _contract == gatewayContract,
      "GovernanceAdmin: query for invalid contract"
    );
    _;
  }

  modifier onlyGovernor() {
    require(_getWeight(msg.sender) > 0, "GovernanceAdmin: sender is not governor");
    _;
  }

  modifier onlySelfCall() {
    require(msg.sender == address(this), "GovernanceAdmin: only allowed self-call");
    _;
  }

  constructor(
    address _roleSetter,
    address _validatorContract,
    address _gatewayContract,
    address[] memory _relayers
  ) {
    require(
      keccak256(
        abi.encode(
          keccak256("EIP712Domain(string name,string version,bytes32 salt)"),
          keccak256("GovernanceAdmin"), // name hash
          keccak256("1"), // version hash
          keccak256(abi.encode("RONIN_GOVERNANCE_ADMIN", 2020)) // salt
        )
      ) == DOMAIN_SEPARATOR,
      "GovernanceAdmin: invalid domain"
    );
    _setupRole(DEFAULT_ADMIN_ROLE, _roleSetter);
    _setValidatorContract(_validatorContract);
    _setGatewayContract(_gatewayContract);
    for (uint256 _i; _i < _relayers.length; _i++) {
      _grantRole(RELAYER_ROLE, _relayers[_i]);
    }
  }

  /**
   * @dev See {Governance-_proposeProposal}.
   *
   * Requirements:
   * - The method caller is governor.
   *
   */
  function propose(
    uint256 _chainId,
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas
  ) external onlyGovernor {
    _proposeProposal(_chainId, _targets, _values, _calldatas, msg.sender);
  }

  /**
   * @dev See {ProposalGovernance-_proposeProposalStructAndCastVotes}.
   *
   * Requirements:
   * - The method caller is governor.
   *
   */
  function proposeProposalStructAndCastVotes(
    Proposal.ProposalDetail calldata _proposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures
  ) external onlyGovernor {
    _proposeProposalStructAndCastVotes(_proposal, _supports, _signatures, DOMAIN_SEPARATOR, msg.sender);
  }

  /**
   * @dev See {ProposalGovernance-_castProposalBySignatures}.
   */
  function castProposalBySignatures(
    Proposal.ProposalDetail calldata _proposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures
  ) external {
    _castProposalBySignatures(_proposal, _supports, _signatures, DOMAIN_SEPARATOR);
  }

  /**
   * @dev See {ProposalGovernance-_relayProposal}.
   *
   * Requirements:
   * - The method caller is relayer.
   *
   */
  function relayProposal(
    Proposal.ProposalDetail calldata _proposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures
  ) external onlyRole(RELAYER_ROLE) {
    _relayProposal(_proposal, _supports, _signatures, DOMAIN_SEPARATOR, msg.sender);
  }

  /**
   * @dev See {Governance-_proposeGlobal}.
   *
   * Requirements:
   * - The method caller is governor.
   *
   */
  function proposeGlobal(
    GlobalProposal.TargetOption[] calldata _targetOptions,
    uint256[] memory _values,
    bytes[] memory _calldatas
  ) external onlyGovernor {
    _proposeGlobal(_targetOptions, _values, _calldatas, validatorContract, gatewayContract, msg.sender);
  }

  /**
   * @dev See {GlobalProposalGovernance-_proposeGlobalProposalStructAndCastVotes}.
   *
   * Requirements:
   * - The method caller is governor.
   *
   */
  function proposeGlobalProposalStructAndCastVotes(
    GlobalProposal.GlobalProposalDetail calldata _globalProposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures
  ) external onlyGovernor {
    _proposeGlobalProposalStructAndCastVotes(
      _globalProposal,
      _supports,
      _signatures,
      DOMAIN_SEPARATOR,
      validatorContract,
      gatewayContract,
      msg.sender
    );
  }

  /**
   * @dev See {GlobalProposalGovernance-_castGlobalProposalBySignatures}.
   */
  function castGlobalProposalBySignatures(
    GlobalProposal.GlobalProposalDetail calldata _globalProposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures
  ) external {
    _castGlobalProposalBySignatures(
      _globalProposal,
      _supports,
      _signatures,
      DOMAIN_SEPARATOR,
      validatorContract,
      gatewayContract
    );
  }

  /**
   * @dev See {GlobalProposalGovernance-_relayGlobalProposal}.
   *
   * Requirements:
   * - The method caller is relayer.
   *
   */
  function relayGlobalProposal(
    GlobalProposal.GlobalProposalDetail calldata _globalProposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures
  ) external onlyRole(RELAYER_ROLE) {
    _relayGlobalProposal(
      _globalProposal,
      _supports,
      _signatures,
      DOMAIN_SEPARATOR,
      validatorContract,
      gatewayContract,
      msg.sender
    );
  }

  /**
   * @dev Returns the voting signatures.
   *
   * @notice Does not verify whether the voter casted vote for the proposal and the returned signature can be empty.
   * Please consider filtering for empty signatures after calling this function.
   *
   */
  function getVotingSignatures(
    uint256 _chainId,
    uint256 _round,
    address[] calldata _voters
  ) external view returns (Ballot.VoteType[] memory _supports, Signature[] memory _signatures) {
    ProposalVote storage _vote = vote[_chainId][_round];

    address _voter;
    _supports = new Ballot.VoteType[](_voters.length);
    _signatures = new Signature[](_voters.length);
    for (uint256 _i; _i < _voters.length; _i++) {
      _voter = _voters[_i];

      if (_vote.againstVoted[_voter]) {
        _supports[_i] = Ballot.VoteType.Against;
      }

      _signatures[_i] = vote[_chainId][_round].sig[_voter];
    }
  }

  /**
   * @dev Returns the current implementation of `_proxy`.
   *
   * Requirements:
   * - This contract must be the admin of `_proxy`.
   *
   */
  function getProxyImplementation(address _proxy) external view returns (address) {
    // We need to manually run the static call since the getter cannot be flagged as view
    // bytes4(keccak256("implementation()")) == 0x5c60da1b
    (bool _success, bytes memory _returndata) = _proxy.staticcall(hex"5c60da1b");
    require(_success, "GovernanceAdmin: proxy call failed");
    return abi.decode(_returndata, (address));
  }

  /**
   * @dev Returns the current admin of `_proxy`.
   *
   * Requirements:
   * - This contract must be the admin of `_proxy`.
   *
   */
  function getProxyAdmin(address _proxy) external view returns (address) {
    // We need to manually run the static call since the getter cannot be flagged as view
    // bytes4(keccak256("admin()")) == 0xf851a440
    (bool _success, bytes memory _returndata) = _proxy.staticcall(hex"f851a440");
    require(_success, "GovernanceAdmin: proxy call failed");
    return abi.decode(_returndata, (address));
  }

  /**
   * @dev Changes the admin of `_proxy` to `newAdmin`.
   *
   * Requirements:
   * - This contract must be the current admin of `_proxy`.
   *
   */
  function changeProxyAdmin(address _proxy, address _newAdmin) external onlySelfCall {
    // bytes4(keccak256("changeAdmin(address)"))
    (bool _success, ) = _proxy.call(abi.encodeWithSelector(0x8f283970, _newAdmin));
    require(_success, "GovernanceAdmin: change admin call failed");
  }

  /**
   * @dev See `_setValidatorContract` function.
   *
   * Requirements:
   * - Only allowed self-call.
   *
   */
  function setValidatorContract(address _validatorContract) external onlySelfCall {
    require(_validatorContract.code.length > 0, "GovernanceAdmin: only contracts are allowed");
    _setValidatorContract(_validatorContract);
  }

  /**
   * @dev See `_setGatewayContract` function.
   *
   * Requirements:
   * - Only allowed self-call.
   *
   */
  function setGatewayContract(address _gatewayContract) public onlySelfCall {
    require(_gatewayContract.code.length > 0, "GovernanceAdmin: only contracts are allowed");
    _setGatewayContract(_gatewayContract);
  }

  /**
   * @dev Sets validator contract address.
   *
   * Emits the `ValidatorContractUpdated` event.
   *
   */
  function _setValidatorContract(address _validatorContract) internal {
    validatorContract = _validatorContract;
    emit ValidatorContractUpdated(_validatorContract);
  }

  /**
   * @dev Sets gateway contract address.
   *
   * Emits the `GatewayContractUpdated` event.
   *
   */
  function _setGatewayContract(address _gatewayContract) internal {
    gatewayContract = _gatewayContract;
    emit GatewayContractUpdated(_gatewayContract);
  }

  /**
   * @dev Override {Governance-_getMinimumVoteWeight}.
   */
  function _getMinimumVoteWeight() internal view override returns (uint256) {
    (bool _success, bytes memory _returndata) = validatorContract.staticcall(
      abi.encodeWithSelector(
        // TransparentUpgradeableProxyV2.functionDelegateCall.selector,
        0x4bb5274a,
        abi.encodeWithSelector(IQuorum.minimumVoteWeight.selector)
      )
    );
    require(_success, "GovernanceAdmin: proxy call failed");
    return abi.decode(_returndata, (uint256));
  }

  /**
   * @dev Override {Governance-_getTotalWeights}.
   */
  function _getTotalWeights() internal view override returns (uint256) {
    (bool _success, bytes memory _returndata) = validatorContract.staticcall(
      abi.encodeWithSelector(
        // TransparentUpgradeableProxyV2.functionDelegateCall.selector,
        0x4bb5274a,
        abi.encodeWithSelector(IWeightedValidator.totalWeights.selector)
      )
    );
    require(_success, "GovernanceAdmin: proxy call failed");
    return abi.decode(_returndata, (uint256));
  }

  /**
   * @dev Override {Governance-_getWeight}.
   */
  function _getWeight(address _governor) internal view override returns (uint256) {
    (bool _success, bytes memory _returndata) = validatorContract.staticcall(
      abi.encodeWithSelector(
        // TransparentUpgradeableProxyV2.functionDelegateCall.selector,
        0x4bb5274a,
        abi.encodeWithSelector(IWeightedValidator.getGovernorWeight.selector, _governor)
      )
    );
    require(_success, "GovernanceAdmin: proxy call failed");
    return abi.decode(_returndata, (uint256));
  }

  /**
   * @dev Override {Governance-_getWeights}.
   */
  function _getWeights(address[] memory _governors) internal view override returns (uint256) {
    (bool _success, bytes memory _returndata) = validatorContract.staticcall(
      abi.encodeWithSelector(
        // TransparentUpgradeableProxyV2.functionDelegateCall.selector,
        0x4bb5274a,
        abi.encodeWithSelector(IWeightedValidator.sumGovernorWeights.selector, _governors)
      )
    );
    require(_success, "GovernanceAdmin: proxy call failed");
    return abi.decode(_returndata, (uint256));
  }

  /**
   * @dev Check whether the signatures is empty.
   */
  function _empty(Signature memory _sig) internal pure returns (bool) {
    return uint256(_sig.v) == 0 && uint256(_sig.r) == 0 && uint256(_sig.s) == 0;
  }
}
