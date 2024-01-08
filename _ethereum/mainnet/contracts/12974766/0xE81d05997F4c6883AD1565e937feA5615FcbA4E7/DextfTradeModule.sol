/*
    Copyright 2021 Memento Blockchain Pte. Ltd. 

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
pragma experimental "ABIEncoderV2";

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";
import "./AddressArrayUtils.sol";
import "./IController.sol";
import "./IERC20.sol";
import "./IIntegrationRegistry.sol";
import "./Invoke.sol";
import "./ISetToken.sol";
import "./ModuleBase.sol";
import "./Position.sol";
import "./PreciseUnitMath.sol";

/**
 * @title DextfTradeModule
 * @author DEXTF Protocol
 *
 * Module that enables DEXTF fund managers to propose a new trade. If this trade is approved and
 * not blocked, after the proposal period, the fund manager can transition to the fund to the trading
 * state, where market makers can rebalance the fund by sending inbound components and recieving the
 * outbound ones as specified by the proposed trade.
 */

contract DextfTradeModule is ModuleBase, ReentrancyGuard, AccessControl {
  using AddressArrayUtils for address[];
  using Invoke for ISetToken;
  using Position for ISetToken;
  using PreciseUnitMath for uint256;
  using SafeCast for int256;
  using SafeMath for uint256;

  // **** Enumerations
  enum FundState {
    REGULAR,
    PROPOSAL,
    TRADING
  }

  // **** Data structures
  struct ProposalConstraints {
    // The minimum time delay between the proposal state and the trading state
    uint256 minimumDelay;
    // The minimum number of approver votes to transition to the trading state
    uint256 minimumApproverVotes;
    // The minimum number of blocker votes needed to stop a trade proposal
    uint256 minimumBlockerVotes;
  }

  struct TradeComponent {
    // The address of the component to be traded
    address componentAddress;
    // The traded quantity, in real units
    uint256 tradeRealUnits;
  }

  struct ProposedTrade {
    // The Specific contraints for this proposal
    ProposalConstraints proposalConstraints;
    // The list of trade components that will be sent to the fund when trading
    TradeComponent[] inboundTradeComponents;
    // The list of trade components that will be sent to the trader when trading
    TradeComponent[] outboundTradeComponents;
    // The maximum number of fund tokens that can be traded
    uint256 maxTradedFundTokens;
    // The number of fund tokens that have been traded so far
    uint256 tradedFundTokens;
    // The timestamp of the most-recent trade proposal
    uint256 proposalTimestamp;
    // The list of approvers that voted for the proposal, empty at the beginning of the proposal
    address[] approverVotes;
    // The list of blockers that voted against the proposal, empty at the beginning of the proposal
    address[] blockerVotes;
  }

  // **** Events
  event ProposalConstraintsUpdated(
    uint256 minimumDelay,
    uint256 minimumApproverVotes,
    uint256 minimumBlockerVotes
  );

  event TradeProposed(
    ISetToken indexed fund,
    uint256 indexed proposalTimestamp,
    uint256 maxTradedFundTokens,
    uint256 minimumDelay,
    uint256 minimumApproverVotes,
    uint256 minimumBlockerVotes,
    uint256 inboundComponentsCount,
    uint256 outboundComponentsCount
  );

  event ApprovalVoteCast(
    ISetToken indexed fund,
    uint256 indexed proposalTimestamp,
    address indexed voter
  );

  event BlockerVoteCast(
    ISetToken indexed fund,
    uint256 indexed proposalTimestamp,
    address indexed voter
  );

  event TradingStarted(ISetToken indexed fund, uint256 indexed proposalTimestamp);

  event InboundComponentReceived(
    ISetToken indexed setToken,
    uint256 indexed proposalTimestamp,
    address indexed marketMaker,
    address inToken,
    uint256 inboundAmount
  );

  event OutboundComponentSent(
    ISetToken indexed setToken,
    uint256 indexed proposalTimestamp,
    address indexed marketMaker,
    address outToken,
    uint256 outboundAmount
  );

  // **** Constants
  bytes32 public constant TRADE_ADMIN_ROLE = keccak256("TRADE_ADMIN_ROLE");
  bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");
  bytes32 public constant BLOCKER_ROLE = keccak256("BLOCKER_ROLE");
  bytes32 public constant MARKET_MAKER_ROLE = keccak256("MARKET_MAKER_ROLE");

  // **** State variables

  // These are the minimum values to be enforced for all trade proposal for all funds
  ProposalConstraints public moduleConstraints;

  // For each fund the relevant data for the current propsed trade
  mapping(ISetToken => ProposedTrade) public proposalDetails;

  // The state of each fund
  mapping(ISetToken => FundState) public fundState;

  // **** Constructor
  constructor(
    IController _controller,
    uint256 _minimumDelay,
    uint256 _minimumApproverVotes,
    uint256 _minimumBlockerVotes,
    address[] memory _administrators,
    address[] memory _approvers,
    address[] memory _blockers,
    address[] memory _marketMakers
  ) ModuleBase(_controller) {
    _setRoleAdmin(TRADE_ADMIN_ROLE, TRADE_ADMIN_ROLE);
    _setRoleAdmin(APPROVER_ROLE, TRADE_ADMIN_ROLE);
    _setRoleAdmin(BLOCKER_ROLE, TRADE_ADMIN_ROLE);
    _setRoleAdmin(MARKET_MAKER_ROLE, TRADE_ADMIN_ROLE);

    require(_administrators.length > 0, "At least one administrator is required");

    // Register administrators
    for (uint256 i = 0; i < _administrators.length; ++i) {
      _setupRole(TRADE_ADMIN_ROLE, _administrators[i]);
    }

    // Register approvers
    for (uint256 i = 0; i < _approvers.length; ++i) {
      _setupRole(APPROVER_ROLE, _approvers[i]);
    }

    // Register blockers
    for (uint256 i = 0; i < _blockers.length; ++i) {
      _setupRole(BLOCKER_ROLE, _blockers[i]);
    }

    // Register market makers
    for (uint256 i = 0; i < _marketMakers.length; ++i) {
      _setupRole(MARKET_MAKER_ROLE, _marketMakers[i]);
    }

    _updateProposalConstraints(_minimumDelay, _minimumApproverVotes, _minimumBlockerVotes);
  }

  // **** Modifiers
  /**
   * @dev Modifier to make a function callable only by a certain role.
   */
  modifier onlyRole(bytes32 role) {
    require(hasRole(role, _msgSender()), "Sender requires permission");
    _;
  }

  /**
   * @dev Modifier to make a function callable only by a certain role. In
   * addition to checking the sender's role, `address(0)` 's role is also
   * considered. Granting a role to `address(0)` is equivalent to enabling
   * this role for everyone.
   */
  modifier onlyRoleOrOpenRole(bytes32 role) {
    require(
      hasRole(role, _msgSender()) || hasRole(role, address(0)),
      "Sender requires permission, or open role"
    );
    _;
  }

  // **** External functions called by the SetToken smart contract

  /**
   * Initializes this module to the SetToken. Only callable by the SetToken's manager.
   *
   * @param _fund         Address of the SetToken
   */
  function initialize(ISetToken _fund)
    external
    onlySetManager(_fund, msg.sender)
    onlyValidAndPendingSet(_fund)
  {
    fundState[_fund] = FundState.REGULAR;
    _fund.initializeModule();
  }

  /**
   * Called by a SetToken to notify that this module was removed.
   * Clears the proposalDetails and the fundState.
   */
  function removeModule() external override {
    delete proposalDetails[ISetToken(msg.sender)];
    delete fundState[ISetToken(msg.sender)];
  }

  // **** External functions called only by the trade administrator
  /**
   * ONLY BY ADMINISTRATOR: updates the module-wide proposal constraints.
   *
   * @param _minimumDelay          The minimum time delay between the proposal state and the trading state
   * @param _minimumApproverVotes  The minimum number of approver votes to transition to the trading state
   * @param _minimumBlockerVotes   The minimum number of blocker votes needed to stop a trade proposal
   */

  function updateProposalConstraints(
    uint256 _minimumDelay,
    uint256 _minimumApproverVotes,
    uint256 _minimumBlockerVotes
  ) external nonReentrant onlyRole(TRADE_ADMIN_ROLE) {
    _updateProposalConstraints(_minimumDelay, _minimumApproverVotes, _minimumBlockerVotes);
  }

  // **** External functions called by the fund manager
  /**
   * ONLY FUND MANAGER: regardless of the current fund state, transition the fund to the regular state.
   * It can be use both to cancel a prposal or to cancel trading.
   *
   * @param _fund   Address of the fund to be transitioned to the regular state
   */
  function revertToRegularState(ISetToken _fund) external onlyManagerAndValidSet(_fund) {
    require(fundState[_fund] != FundState.REGULAR, "Already in regular state");
    fundState[_fund] = FundState.REGULAR;
  }

  /**
   * ONLY FUND MANAGER: propose a new trade together with new constraint and transition a fund
   * from the regular state to the proposal state. There are no checks on the proposed trade as
   * these checks are left to the approvers and blockers.
   *
   * @param _fund                    Address of the fund subject of the trade
   * @param _maxTradedFundTokens     The maximum number of fund tokens that can be traded
   * @param _proposalConstraints     The constraints for this proposal
   * @param _inboundAddresses        The component addresses entering the fund
   * @param _outboundAddresses       The component addresses exiting the fund
   * @param _inboundRealUnitsArray   The value of the incoming tokens per fund token, in real units
   * @param _outboundRealUnitsArray  The value of the outgoing tokens per fund token, in real units
   */

  function proposeTrade(
    ISetToken _fund,
    uint256 _maxTradedFundTokens,
    ProposalConstraints calldata _proposalConstraints,
    address[] calldata _inboundAddresses,
    uint256[] calldata _inboundRealUnitsArray,
    address[] calldata _outboundAddresses,
    uint256[] calldata _outboundRealUnitsArray
  ) external onlyManagerAndValidSet(_fund) {
    // Check that the fund was in the regular state
    require(fundState[_fund] == FundState.REGULAR, "Fund must be in the regular state");

    // Check that the proposal constraints are compatible with the module-wise constraints
    require(
      _proposalConstraints.minimumDelay >= moduleConstraints.minimumDelay,
      "minimum delay too short"
    );
    require(
      _proposalConstraints.minimumApproverVotes >= moduleConstraints.minimumApproverVotes,
      "minimum approvers too small"
    );
    require(
      _proposalConstraints.minimumBlockerVotes >= moduleConstraints.minimumBlockerVotes,
      "minimum blockers too small"
    );

    // Check that the proposed trade is not empty
    require(_inboundAddresses.length > 0, "Inbound addresses cannot be empty");
    require(_outboundAddresses.length > 0, "Outbound addresses cannot be empty");
    // Check for vector consistency
    require(_inboundRealUnitsArray.length == _inboundAddresses.length, "Mismatch inbound lenghts");
    require(
      _outboundAddresses.length == _outboundRealUnitsArray.length,
      "Mismatch outbound lenghts"
    );

    // Make sure there is no null address in either inbound or outbound components
    require(!_inboundAddresses.contains(address(0)), "Null address in inbound componets");
    require(!_outboundAddresses.contains(address(0)), "Null address in outbound componets");

    // Check that there are non duplicate in the component addresses
    require(
      !_inboundAddresses.extend(_outboundAddresses).hasDuplicate(),
      "Duplicate components are not allowed"
    );

    // Check that max number of fund tokens traded is bigger than 0
    require(_maxTradedFundTokens > 0, "Max number of traded tokens must be bigger than 0");

    // Keep track of the maxium tokens to be traded
    proposalDetails[_fund].maxTradedFundTokens = _maxTradedFundTokens;

    // Reset the number of fund tokens that have been traded so far
    proposalDetails[_fund].tradedFundTokens = 0;

    // Save the current block timestamp as the proposal timestamp
    // solhint-disable-next-line not-rely-on-time
    proposalDetails[_fund].proposalTimestamp = block.timestamp;

    // Update the proposal constraints and the new allocation components
    proposalDetails[_fund].proposalConstraints.minimumDelay = _proposalConstraints.minimumDelay;

    proposalDetails[_fund].proposalConstraints.minimumApproverVotes = _proposalConstraints
    .minimumApproverVotes;

    proposalDetails[_fund].proposalConstraints.minimumBlockerVotes = _proposalConstraints
    .minimumBlockerVotes;

    // Reset the previous proposal votes
    delete proposalDetails[_fund].approverVotes;
    delete proposalDetails[_fund].blockerVotes;

    // Destroy the previous and create the new inboundTradeComponents vector
    delete proposalDetails[_fund].inboundTradeComponents;

    // Loop and push the inbound components
    for (uint256 i = 0; i < _inboundAddresses.length; i++) {
      proposalDetails[_fund].inboundTradeComponents.push(
        TradeComponent({
          componentAddress: _inboundAddresses[i],
          tradeRealUnits: _inboundRealUnitsArray[i]
        })
      );
    }

    // Destroy the previous and create the new outboundTradeComponents vector
    delete proposalDetails[_fund].outboundTradeComponents;

    // Loop and push the outbound components
    for (uint256 i = 0; i < _outboundAddresses.length; i++) {
      proposalDetails[_fund].outboundTradeComponents.push(
        TradeComponent({
          componentAddress: _outboundAddresses[i],
          tradeRealUnits: _outboundRealUnitsArray[i]
        })
      );
    }

    // Check that outboud components are compatible with the current fund holdings
    _checkOutboundComponents(_fund);

    fundState[_fund] = FundState.PROPOSAL;

    emit TradeProposed(
      _fund,
      block.timestamp,
      _maxTradedFundTokens,
      _proposalConstraints.minimumDelay,
      _proposalConstraints.minimumApproverVotes,
      _proposalConstraints.minimumBlockerVotes,
      _inboundAddresses.length,
      _outboundAddresses.length
    );
  }

  /**
   * ONLY FUND MANAGER: Transition the fund from the proposal state to the trading state if all
   * constranits are satifid: the minimum proposal time has elapsed, there are enough approval votes
   * and there are not too many blocker votes.
   *
   * @param _fund             Address of the fund for which trading can start
   */
  function startTrading(ISetToken _fund) external onlyManagerAndValidSet(_fund) {
    // Check that the fund was in the proposal state
    require(fundState[_fund] == FundState.PROPOSAL, "Fund must be in the proposal state");

    // Check that we are after the proposed period
    require(
      block.timestamp >=
        proposalDetails[_fund].proposalTimestamp.add(
          proposalDetails[_fund].proposalConstraints.minimumDelay
        ),
      "Proposal period not over yet"
    );

    // Check that there are not enough blocker votes
    if (proposalDetails[_fund].proposalConstraints.minimumBlockerVotes > 0) {
      require(
        proposalDetails[_fund].blockerVotes.length <
          proposalDetails[_fund].proposalConstraints.minimumBlockerVotes,
        "Too many blocker votes"
      );
    }

    // Check that there are enough approval votes
    require(
      proposalDetails[_fund].approverVotes.length >=
        proposalDetails[_fund].proposalConstraints.minimumApproverVotes,
      "Not enough approval votes"
    );

    // Transition the fund to the trading state
    fundState[_fund] = FundState.TRADING;

    emit TradingStarted(_fund, proposalDetails[_fund].proposalTimestamp);
  }

  // **** External functions called by approvers
  /**
   * ONLY APPROVERS: called by an approver to cast an approval vote to the latest proposal on a certain fund.
   * Once the vote is cast it cannot be retracted.
   *
   * @param _fund      Address of the fund for which the approval vote is cast
   */
  function castApprovalVote(ISetToken _fund) external onlyRole(APPROVER_ROLE) {
    // Check that the fund is in the proposal state
    require(fundState[_fund] == FundState.PROPOSAL, "Fund must be in proposal state");

    // Check that this approver hasn't voted yet
    require(
      !proposalDetails[_fund].approverVotes.contains(msg.sender),
      "Approver has already voted"
    );

    // Add the approval vote to the tally
    proposalDetails[_fund].approverVotes.push(msg.sender);

    emit ApprovalVoteCast(_fund, proposalDetails[_fund].proposalTimestamp, msg.sender);
  }

  // **** External functions called by blockers
  /**
   * ONLY BLOCKERS: called by a blocker to cast a blocking vote to the latest proposal on a certain fund.
   * Once the vote is cast it cannot be retracted.
   *
   * @param _fund      Address of the fund for which the blocker vote is cast
   */
  function castBlockerVote(ISetToken _fund) external onlyRole(BLOCKER_ROLE) {
    // Check that the fund is in the proposal state
    require(fundState[_fund] == FundState.PROPOSAL, "Fund must be in proposal state");

    // Check that this blocker hasn't voted yet
    require(!proposalDetails[_fund].blockerVotes.contains(msg.sender), "Blocker has already voted");

    // Add the approval vote to the tally
    proposalDetails[_fund].blockerVotes.push(msg.sender);

    emit BlockerVoteCast(_fund, proposalDetails[_fund].proposalTimestamp, msg.sender);
  }

  // **** External functions called by market makers
  /**
   * ONLY MARKET MAKERS: called by market makers to perform the actual trade by sending inboud components
   * and receiveing outbound ones.
   *
   * @param _fund      Address of the fund for which want to perform the trade
   * @param _quantity  The equivalent number of fund tokens to be traded
   *
   */
  function performTrade(ISetToken _fund, uint256 _quantity)
    external
    nonReentrant
    onlyRoleOrOpenRole(MARKET_MAKER_ROLE)
  {
    // Check that the fund is in the trading state
    require(fundState[_fund] == FundState.TRADING, "Fund must be in trading state");

    // Check that the quantity is positive
    require(_quantity > 0, "Quantity must be positive");

    // Compute total fund supply
    uint256 fundTotalSupply = _fund.totalSupply();

    // Check that the quantity is not larger than the total supply
    require(_quantity <= fundTotalSupply, "Quantity exceeds total supply");

    // Check that we do traded more fund tokens than originally intended
    uint256 newTotalQuantity = proposalDetails[_fund].tradedFundTokens.add(_quantity);
    require(
      newTotalQuantity <= proposalDetails[_fund].maxTradedFundTokens,
      "Maximum quantity of traded fund tokens exceeded"
    );

    // We need to perform this check again because the positions might have changed since proposal
    _checkOutboundComponents(_fund);

    // We store the component current balances before trading, to keep track of airdrops
    uint256[] memory preTradeInboundBalances = _computePreTradeBalances(
      _fund,
      proposalDetails[_fund].inboundTradeComponents
    );

    uint256[] memory preTradeOutboundBalances = _computePreTradeBalances(
      _fund,
      proposalDetails[_fund].outboundTradeComponents
    );

    // Compute quantity-scaled inbound/outbound components
    (
      TradeComponent[] memory scaledInboundComponents,
      TradeComponent[] memory scaledOutboundComponents
    ) = _scaleComponents(_fund, _quantity);

    // Trade the outbound components for the inbound ones
    _tradeInboundComponents(_fund, scaledInboundComponents);
    _tradeOutboundComponents(_fund, scaledOutboundComponents);

    // Update the fund positions after the trade
    _updateFundPositions(
      _fund,
      proposalDetails[_fund].inboundTradeComponents,
      fundTotalSupply,
      preTradeInboundBalances
    );
    _updateFundPositions(
      _fund,
      proposalDetails[_fund].outboundTradeComponents,
      fundTotalSupply,
      preTradeOutboundBalances
    );

    // Update the quanity if tokens traded so far
    proposalDetails[_fund].tradedFundTokens = newTotalQuantity;
  }

  // **** External views

  /**
   * Returns the latest proposal details for a given fund.
   *
   * @param _fund Address of the fund for which the proposal details are needed
   *
   * @return proposalDetails The latest trade proposal details for the given fund
   */
  function getProposalDetails(ISetToken _fund)
    external
    view
    onlyValidAndInitializedSet(_fund)
    returns (ProposedTrade memory)
  {
    return proposalDetails[_fund];
  }

  /**
   * Retrieves the timestamp of the current fund proposal.
   *
   * @param _fund  Fund for which we want to query the proposal timestamp
   *
   * @return proposalTimestamp    The latest proposal timestamp for the given fund
   */
  function getProposalTimestamp(ISetToken _fund)
    external
    view
    onlyValidAndInitializedSet(_fund)
    returns (uint256)
  {
    return proposalDetails[_fund].proposalTimestamp;
  }

  /**
   * Retrieves the constraints of the current fund proposal.
   *
   * @param _fund                  Fund for which we want to query the proposal constraints
   *
   * @return minimumDelay          The minimum time delay between the proposal state and the trading state
   * @return minimumApproverVotes  The minimum number of approver votes to transition to the trading state
   * @return minimumBlockerVotes   he minimum number of blocker votes needed to stop a proposal
   */
  function getProposalConstraints(ISetToken _fund)
    external
    view
    onlyValidAndInitializedSet(_fund)
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (
      proposalDetails[_fund].proposalConstraints.minimumDelay,
      proposalDetails[_fund].proposalConstraints.minimumApproverVotes,
      proposalDetails[_fund].proposalConstraints.minimumBlockerVotes
    );
  }

  /**
   * Retrieves the proposed inbound allocation components, in real units.
   *
   * @param _fund                 Fund for which we want to query the inbound components
   *
   * @return _componentAddresses      The addresses of the proposed inbound components
   * @return _positionRealUnitsArray  The value of the inbound component flow
   */
  function getProposedInboundComponents(ISetToken _fund)
    external
    view
    onlyValidAndInitializedSet(_fund)
    returns (address[] memory, uint256[] memory)
  {
    // Allocate the memory for the arrays
    address[] memory componentAddresses = new address[](
      proposalDetails[_fund].inboundTradeComponents.length
    );
    uint256[] memory tradeRealUnitsArray = new uint256[](
      proposalDetails[_fund].inboundTradeComponents.length
    );

    // Transpose the inboundTradeComponents array
    for (uint256 i = 0; i < proposalDetails[_fund].inboundTradeComponents.length; i++) {
      componentAddresses[i] = proposalDetails[_fund].inboundTradeComponents[i].componentAddress;
      tradeRealUnitsArray[i] = proposalDetails[_fund].inboundTradeComponents[i].tradeRealUnits;
    }

    return (componentAddresses, tradeRealUnitsArray);
  }

  /**
   * Retrieves the proposed outbound allocation components, in real units.
   *
   * @param _fund                 Fund for which we want to query the outbound components
   *
   * @return _componentAddresses      The addresses of the proposed outbound components
   * @return _positionRealUnitsArray  The value of the outbound component flow
   */
  function getProposedOutboundComponents(ISetToken _fund)
    external
    view
    onlyValidAndInitializedSet(_fund)
    returns (address[] memory, uint256[] memory)
  {
    // Allocate the memory for the arrays
    address[] memory componentAddresses = new address[](
      proposalDetails[_fund].outboundTradeComponents.length
    );
    uint256[] memory tradeRealUnitsArray = new uint256[](
      proposalDetails[_fund].outboundTradeComponents.length
    );

    // Transpose the outboundTradeComponents array
    for (uint256 i = 0; i < proposalDetails[_fund].outboundTradeComponents.length; i++) {
      componentAddresses[i] = proposalDetails[_fund].outboundTradeComponents[i].componentAddress;
      tradeRealUnitsArray[i] = proposalDetails[_fund].outboundTradeComponents[i].tradeRealUnits;
    }

    return (componentAddresses, tradeRealUnitsArray);
  }

  /**
   * Retrieves the latest tally of the approver votes cast on the most recent proposal.
   *
   * @param _fund                 Fund for which we want to query the approver votes
   *
   * @return approverVotes        The array of approvers that cast a vote on the latest proposal
   */
  function getApprovalVotes(ISetToken _fund)
    external
    view
    onlyValidAndInitializedSet(_fund)
    returns (address[] memory)
  {
    return proposalDetails[_fund].approverVotes;
  }

  /**
   * Retrieves the latest tally of the blocker votes cast on the most recent proposal.
   *
   * @param _fund                 Fund for which we want to query the blocker votes
   *
   * @return blockerVotes        The array of blockers that cast a vote on the latest proposal
   */
  function getBlockerVotes(ISetToken _fund)
    external
    view
    onlyValidAndInitializedSet(_fund)
    returns (address[] memory)
  {
    return proposalDetails[_fund].blockerVotes;
  }

  /**
   * Retrieves the currently and maximum equivalent traded fund tokens
   *
   * @param _fund                 Fund for which we want to query the equivalent traded fund tokens
   *
   * @return tradedFundTokens     The equivalent number of fund tokens that have been traded so far
   * @return maxTradedFundTokens  The maximum number of equivalent fund tokens that can be traded
   */
  function getTradedFundTokens(ISetToken _fund)
    external
    view
    onlyValidAndInitializedSet(_fund)
    returns (uint256, uint256)
  {
    return (proposalDetails[_fund].tradedFundTokens, proposalDetails[_fund].maxTradedFundTokens);
  }

  /**
   * Compute the proposed/actual trade components according to the given quantity
   *
   * @param _fund         Address of the fund subject of the trade
   * @param _quantity     The number of fund base units to be traded
   *
   * @return address[]           The array of inbound addresses
   * @return uint256[]           The array of inbound quantities in real units
   * @return address[]           The array of outbound addresses
   * @return uint256[]           The array of outbound quantities in real units
   */
  function computeInboundOutboundComponents(ISetToken _fund, uint256 _quantity)
    public
    view
    onlyValidAndInitializedSet(_fund)
    returns (
      address[] memory,
      uint256[] memory,
      address[] memory,
      uint256[] memory
    )
  {
    // Compute quantity-scaled inbound/outbound components
    (
      TradeComponent[] memory scaledInboundComponents,
      TradeComponent[] memory scaledOutboundComponents
    ) = _scaleComponents(_fund, _quantity);

    // Reserve the correct memory space for all arrays
    address[] memory inboundAddresses = new address[](scaledInboundComponents.length);
    uint256[] memory inboundRealUnitsArray = new uint256[](scaledInboundComponents.length);
    address[] memory outboundAddresses = new address[](scaledOutboundComponents.length);
    uint256[] memory outboundRealUnitsArray = new uint256[](scaledOutboundComponents.length);

    // Traspose the inbound vectors
    for (uint256 i = 0; i < inboundAddresses.length; i++) {
      inboundAddresses[i] = scaledInboundComponents[i].componentAddress;
      inboundRealUnitsArray[i] = scaledInboundComponents[i].tradeRealUnits;
    }

    // Traspose the outbound vectors
    for (uint256 i = 0; i < outboundAddresses.length; i++) {
      outboundAddresses[i] = scaledOutboundComponents[i].componentAddress;
      outboundRealUnitsArray[i] = scaledOutboundComponents[i].tradeRealUnits;
    }

    return (inboundAddresses, inboundRealUnitsArray, outboundAddresses, outboundRealUnitsArray);
  }

  // **** Internal functions

  /**
   * Private function to update the module-wide minimum proposal constraints.
   *
   * @param _minimumDelay          The minimum time delay between the proposal state and the trading state
   * @param _minimumApproverVotes  The minimum number of approver votes to transition to the trading state
   * @param _minimumBlockerVotes   The minimum number of blocker votes needed to stop a proposal
   */
  function _updateProposalConstraints(
    uint256 _minimumDelay,
    uint256 _minimumApproverVotes,
    uint256 _minimumBlockerVotes
  ) internal {
    moduleConstraints.minimumDelay = _minimumDelay;
    moduleConstraints.minimumApproverVotes = _minimumApproverVotes;
    moduleConstraints.minimumBlockerVotes = _minimumBlockerVotes;

    emit ProposalConstraintsUpdated(_minimumDelay, _minimumApproverVotes, _minimumBlockerVotes);
  }

  /**
   * Trades the inbound components from the transaction sender to the fund contract.
   * Note that the tokens need to be approved before they can be transferred.
   *
   * @param _fund                     Address of the fund subject of the trade
   * @param _scaledInboundComponents  The inbound components to be received
   */
  function _tradeInboundComponents(
    ISetToken _fund,
    TradeComponent[] memory _scaledInboundComponents
  ) internal {
    // Transfer the inbound components
    for (uint256 i = 0; i < _scaledInboundComponents.length; i++) {
      transferFrom(
        IERC20(_scaledInboundComponents[i].componentAddress),
        msg.sender,
        address(_fund),
        _scaledInboundComponents[i].tradeRealUnits
      );

      emit InboundComponentReceived(
        _fund,
        proposalDetails[_fund].proposalTimestamp,
        msg.sender,
        _scaledInboundComponents[i].componentAddress,
        _scaledInboundComponents[i].tradeRealUnits
      );
    }
  }

  /**
   * Trades the outbound components from the fund contract to the transaction sender
   *
   * @param _fund                Address of the fund subject of the trade
   * @param _scaledOutboundComponents  The outbound components to be sent out
   */
  function _tradeOutboundComponents(
    ISetToken _fund,
    TradeComponent[] memory _scaledOutboundComponents
  ) internal {
    // Transfer the outbound components
    for (uint256 i = 0; i < _scaledOutboundComponents.length; i++) {
      _fund.strictInvokeTransfer(
        _scaledOutboundComponents[i].componentAddress,
        msg.sender,
        _scaledOutboundComponents[i].tradeRealUnits
      );
      emit OutboundComponentSent(
        _fund,
        proposalDetails[_fund].proposalTimestamp,
        msg.sender,
        _scaledOutboundComponents[i].componentAddress,
        _scaledOutboundComponents[i].tradeRealUnits
      );
    }
  }

  /**
   * Update the fund positions according to the trades just executed
   *
   * @param _fund                Address of the fund subject of the position update
   * @param _tradeComponents     The components to be updated
   * @param _fundTotalSupply          The observed fund total supply
   * @param _preTradePositionBalances The fund balance for each given component, observed before the trade
   */
  function _updateFundPositions(
    ISetToken _fund,
    TradeComponent[] memory _tradeComponents,
    uint256 _fundTotalSupply,
    uint256[] memory _preTradePositionBalances
  ) internal {
    // Edit the inbound-component positions
    for (uint256 i = 0; i < _tradeComponents.length; i++) {
      _fund.calculateAndEditDefaultPosition(
        _tradeComponents[i].componentAddress,
        _fundTotalSupply,
        _preTradePositionBalances[i]
      );
    }
  }

  /**
   * Makes sure that the requested outbound components do not exceed the current positions
   *
   * @param _fund    Address of the fund subject of the trade
   */
  function _checkOutboundComponents(ISetToken _fund) internal view {
    for (uint256 i = 0; i < proposalDetails[_fund].outboundTradeComponents.length; i++) {
      address tradeComponentAddress = proposalDetails[_fund]
      .outboundTradeComponents[i]
      .componentAddress;
      if (_fund.isComponent(tradeComponentAddress)) {
        uint256 outboundComponentRealUnits = proposalDetails[_fund]
        .outboundTradeComponents[i]
        .tradeRealUnits;
        uint256 currentRealUnits = _fund
        .getDefaultPositionRealUnit(tradeComponentAddress)
        .toUint256();

        require(
          outboundComponentRealUnits <= currentRealUnits,
          "Insufficient balance for outbound component"
        );
      } else {
        revert("Outbound component not in the fund");
      }
    }
  }

  // **** Internal views

  /**
   * Computes the component balance before the trades.
   *
   * @param _fund                Address of the fund subject of the trade
   * @param _tradeComponents     The components to be traded and their quantities
   *
   * @return uint256[]           The array if pre-trade balances
   */
  function _computePreTradeBalances(ISetToken _fund, TradeComponent[] memory _tradeComponents)
    internal
    view
    returns (uint256[] memory)
  {
    // Allocate the memory array first
    uint256[] memory preTradeBalances = new uint256[](_tradeComponents.length);

    // Fetch the position balance and store it in the array
    for (uint256 i = 0; i < _tradeComponents.length; i++) {
      preTradeBalances[i] = IERC20(_tradeComponents[i].componentAddress).balanceOf(address(_fund));
    }

    return preTradeBalances;
  }

  /**
   * Rescale the fund proposed/actual trade components according to the given quantity
   *
   * @param _fund         Address of the fund subject of the trade
   * @param _quantity     The number of fund base units to be traded
   *
   * @return TradeComponent[]    The scaled inbound trade components
   * @return TradeComponent[]    The scaled outbound trade components
   */
  function _scaleComponents(ISetToken _fund, uint256 _quantity)
    internal
    view
    returns (TradeComponent[] memory, TradeComponent[] memory)
  {
    // Reserve the correct memory space for both inbound and outbound vectors
    TradeComponent[] memory _scaledInboundComponents = new TradeComponent[](
      proposalDetails[_fund].inboundTradeComponents.length
    );

    TradeComponent[] memory _scaledOutboundComponents = new TradeComponent[](
      proposalDetails[_fund].outboundTradeComponents.length
    );

    // Compute the scaled inbound components
    for (uint256 i = 0; i < _scaledInboundComponents.length; i++) {
      uint256 realUnit = proposalDetails[_fund].inboundTradeComponents[i].tradeRealUnits;

      // Use preciseMulCeil to be consistent with the BasicIssuance module issuance
      _scaledInboundComponents[i].tradeRealUnits = realUnit.preciseMulCeil(_quantity);

      _scaledInboundComponents[i].componentAddress = proposalDetails[_fund]
      .inboundTradeComponents[i]
      .componentAddress;
    }

    // Compute the scaled outbound components
    for (uint256 i = 0; i < _scaledOutboundComponents.length; i++) {
      uint256 realUnit = proposalDetails[_fund].outboundTradeComponents[i].tradeRealUnits;

      // Use preciseMul to be consistent with the BasicIssuance module redemption
      _scaledOutboundComponents[i].tradeRealUnits = _quantity.preciseMul(realUnit);
      _scaledOutboundComponents[i].componentAddress = proposalDetails[_fund]
      .outboundTradeComponents[i]
      .componentAddress;
    }
    return (_scaledInboundComponents, _scaledOutboundComponents);
  }
}