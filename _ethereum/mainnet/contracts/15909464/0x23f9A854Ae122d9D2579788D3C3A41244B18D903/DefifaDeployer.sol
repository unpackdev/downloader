// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IERC721Receiver.sol";
import "./JBConstants.sol";
import "./JBSplitsGroups.sol";
import "./JBFundAccessConstraints.sol";
import "./JBTiered721FundingCycleMetadataResolver.sol";
import "./IDefifaDeployer.sol";
import "./DefifaStoredOpsData.sol";
import "./DefifaDelegate.sol";

/**
  @title
  DefifaDeployer

  @notice
  Deploys a Defifa game.

  @dev
  Adheres to -
  IDefifaDeployer: General interface for the generic controller methods in this contract that interacts with funding cycles and tokens according to the protocol's rules.
*/
contract DefifaDeployer is IDefifaDeployer, IERC721Receiver {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_GAME_CONFIGURATION();
  error PHASE_ALREADY_QUEUED();
  error GAME_OVER();
  error UNEXPECTED_TERMINAL_CURRENCY();

  //*********************************************************************//
  // ----------------------- private constants ------------------------- //
  //*********************************************************************//

  /**
    @notice
    The ID of the project that takes fees upon distribution.
  */
  uint256 internal constant _PROTOCOL_FEE_PROJECT = 1;

  /**
    @notice
    Useful for the deploy flow to get memory management right.
  */
  uint256 internal constant _DEPLOY_BYTECODE_LENGTH = 13;

  //*********************************************************************//
  // ----------------------- internal proprties ------------------------ //
  //*********************************************************************//

  /**
    @notice
    Start time of the 2nd fc when re-configuring the fc.
  */
  mapping(uint256 => DefifaTimeData) internal _timesFor;

  /**
    @notice
    Operations variables for a game.

    @dev
    Includes the payment terminal being used, the distribution limit, and wether or not fees should be held.
  */
  mapping(uint256 => DefifaStoredOpsData) internal _opsFor;

  //*********************************************************************//
  // ------------------------ public constants ------------------------- //
  //*********************************************************************//

  /**
    @notice
    The project ID relative to which splits are stored.

    @dev
    The owner of this project ID must give this contract operator permissions over the SET_SPLITS operation.
  */
  uint256 public constant override SPLIT_PROJECT_ID = 1;

  /**
    @notice
    The domain relative to which splits are stored.

    @dev
    This could be any fixed number.
  */
  uint256 public constant override SPLIT_DOMAIN = 0;

  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  /**
   * @notice
   */
  address public immutable defifaCodeOrigin;

  /**
    @notice
    The token this game is played with.
  */
  address public immutable override token;

  /**
    @notice
    The controller with which new projects should be deployed.
  */
  IJBController public immutable override controller;

  /**
    @notice
    The address that should be forwarded JBX accumulated in this contract from game fund distributions.
  */
  address public override protocolFeeProjectTokenAccount;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  function timesFor(uint256 _gameId) external view override returns (DefifaTimeData memory) {
    return _timesFor[_gameId];
  }

  function mintDurationOf(uint256 _gameId) external view override returns (uint256) {
    return _timesFor[_gameId].mintDuration;
  }

  function startOf(uint256 _gameId) external view override returns (uint256) {
    return _timesFor[_gameId].start;
  }

  function tradeDeadlineOf(uint256 _gameId) external view override returns (uint256) {
    return _timesFor[_gameId].tradeDeadline;
  }

  function endOf(uint256 _gameId) external view override returns (uint256) {
    return _timesFor[_gameId].end;
  }

  function terminalOf(uint256 _gameId) external view override returns (IJBPaymentTerminal) {
    return _opsFor[_gameId].terminal;
  }

  function distributionLimit(uint256 _gameId) external view override returns (uint256) {
    return uint256(_opsFor[_gameId].distributionLimit);
  }

  function holdFeesDuring(uint256 _gameId) external view override returns (bool) {
    return _opsFor[_gameId].holdFees;
  }

  /**
    @notice
    Returns the number of the game phase.

    @dev
    The game phase corresponds to the game's current funding cycle number.

    @param _gameId The ID of the game to get the phase number of.

    @return The game phase number.
  */
  function currentGamePhaseOf(uint256 _gameId) external view override returns (uint256) {
    // Get the project's current funding cycle along with its metadata.
    JBFundingCycle memory _currentFundingCycle = controller.fundingCycleStore().currentOf(_gameId);

    // The phase is the current funding cycle number.
    return _currentFundingCycle.number;
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _controller The controller with which new projects should be deployed. 
    @param _token The token that games deployed through this contract accept.
    @param _protocolFeeProjectTokenAccount The address that should be forwarded JBX accumulated in this contract from game fund distributions. 
  */
  constructor(
    address _defifaCodeOrigin,
    IJBController _controller,
    address _token,
    address _protocolFeeProjectTokenAccount
  ) {
    defifaCodeOrigin = _defifaCodeOrigin;
    controller = _controller;
    token = _token;
    protocolFeeProjectTokenAccount = _protocolFeeProjectTokenAccount;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice
    Launches a new project with a Defifa data source attached.

    @param _delegateData Data necessary to fulfill the transaction to deploy a delegate.
    @param _launchProjectData Data necessary to fulfill the transaction to launch a project.

    @return gameId The ID of the newly configured game.
  */
  function launchGameWith(
    DefifaDelegateData memory _delegateData,
    DefifaLaunchProjectData memory _launchProjectData
  ) external override returns (uint256 gameId) {
    // Make sure the provided gameplay timestamps are sequential.
    if (
      _launchProjectData.start - _launchProjectData.mintDuration < block.timestamp ||
      _launchProjectData.tradeDeadline < _launchProjectData.start ||
      _launchProjectData.end < _launchProjectData.start ||
      _launchProjectData.end < _launchProjectData.tradeDeadline
    ) revert INVALID_GAME_CONFIGURATION();

    // Get the game ID, optimistically knowing it will be one greater than the current count.
    gameId = controller.projects().count() + 1;

    // Make sure the provided terminal accepts the same currency as this game is being played in.
    if (!_launchProjectData.terminal.acceptsToken(token, gameId)) revert UNEXPECTED_TERMINAL_CURRENCY();

    {
      // Store the timestamps that'll define the game phases.
      _timesFor[gameId] = DefifaTimeData({
        mintDuration: _launchProjectData.mintDuration,
        start: _launchProjectData.start,
        tradeDeadline: _launchProjectData.tradeDeadline,
        end: _launchProjectData.end
      });

      // Store the terminal, distribution limit, and hold fees flag.
      _opsFor[gameId] = DefifaStoredOpsData({
        terminal:_launchProjectData.terminal,
        distributionLimit: _launchProjectData.distributionLimit,
        holdFees: _launchProjectData.holdFees
      });

      if (_launchProjectData.splits.length != 0) {
        // Store the splits. They'll be used when queueing phase 2.
        JBGroupedSplits[] memory _groupedSplits = new JBGroupedSplits[](1);
        _groupedSplits[0] = JBGroupedSplits({group: gameId, splits: _launchProjectData.splits});
        // This contract must have SET_SPLITS operator permissions.
        controller.splitsStore().set(SPLIT_PROJECT_ID, SPLIT_DOMAIN, _groupedSplits);
      }
    }

    JB721PricingParams memory _pricingParams = JB721PricingParams({
        tiers: _delegateData.tiers,
        currency: _launchProjectData.terminal.currencyForToken(token),
        decimals: _launchProjectData.terminal.decimalsForToken(token),
        prices: IJBPrices(address(0))
      });

    // Clone and initialize the new delegate
    DefifaDelegate _delegate = DefifaDelegate(_clone(defifaCodeOrigin));
    _delegate.initialize(
      gameId,
      controller.directory(),
      _delegateData.name,
      _delegateData.symbol,
      controller.fundingCycleStore(),
      _delegateData.baseUri,
      IJBTokenUriResolver(address(0)),
      _delegateData.contractUri,
      _pricingParams,
      _delegateData.store,
      JBTiered721Flags({
          lockReservedTokenChanges: false,
          lockVotingUnitChanges: false,
          lockManualMintingChanges: false
      })
    );

    // Transfer ownership to the specified owner.
    _delegate.transferOwnership(_delegateData.owner);

    // Queue the first phase of the game.
    _queuePhase1(_launchProjectData, address(_delegate));
  }

  /**
    @notice
    Queues the funding cycle that represents the next phase of the game, if it isn't queued already.

    @param _gameId The ID of the project having funding cycles reconfigured.

    @return configuration The configuration of the funding cycle that was successfully reconfigured.
  */
  function queueNextPhaseOf(uint256 _gameId)
    external
    override
    returns (uint256 configuration)
  {
    // Get the project's current funding cycle along with its metadata.
    (JBFundingCycle memory _currentFundingCycle, JBFundingCycleMetadata memory _metadata) = controller
      .currentFundingCycleOf(_gameId);

    // There are only 4 phases.
    if (_currentFundingCycle.number >= 4) revert GAME_OVER();

    // Get the project's queued funding cycle.
    (JBFundingCycle memory queuedFundingCycle, ) = controller.queuedFundingCycleOf(_gameId);

    // Make sure the next game phase isn't already queued.
    if (_currentFundingCycle.configuration != queuedFundingCycle.configuration)
      revert PHASE_ALREADY_QUEUED();

    // Queue the next phase of the game.
    if (_currentFundingCycle.number == 1) return _queuePhase2(_gameId, _metadata.dataSource);
    else if (_currentFundingCycle.number == 2) return _queuePhase3(_gameId, _metadata.dataSource);
    else return _queuePhase4(_gameId, _metadata.dataSource);
  }

  /** 
    @notice
    Move accumulated protocol project tokens from paying fees into the recipient. 

    @dev
    This contract accumulated JBX as games distribute payouts.
  */
  function claimProtocolProjectToken() external override {
    // Get the number of protocol project tokens this contract has allocated.
    // Send the token from the protocol project to the specified account.
    controller.tokenStore().transferFrom(
      address(this),
      _PROTOCOL_FEE_PROJECT,
      protocolFeeProjectTokenAccount,
      controller.tokenStore().unclaimedBalanceOf(address(this), _PROTOCOL_FEE_PROJECT)
    );
  }

  /**
    @notice
    Allows this contract to receive 721s.
  */
  function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
     return IERC721Receiver.onERC721Received.selector;
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /**
    @notice
    Launches a Defifa project with phase 1 configured.

    @param _launchProjectData Project data used for launching a Defifa game.
    @param _dataSource The address of the Defifa data source.
  */
  function _queuePhase1(DefifaLaunchProjectData memory _launchProjectData, address _dataSource)
    internal
  {
    // Initialize the terminal array .
    IJBPaymentTerminal[] memory _terminals = new IJBPaymentTerminal[](1);
    _terminals[0] = _launchProjectData.terminal;

    // Launch the project with params for phase 1 of the game.
    controller.launchProjectFor(
      // Project is owned by this contract.
      address(this),
      _launchProjectData.projectMetadata,
      JBFundingCycleData ({
        duration: _launchProjectData.mintDuration,
        // Don't mint project tokens.
        weight: 0,
        discountRate: 0,
        ballot: IJBFundingCycleBallot(address(0))
      }),
      JBFundingCycleMetadata ({
        global: JBGlobalFundingCycleMetadata({
          allowSetTerminals: false,
          allowSetController: false,
          pauseTransfers: false
        }),
        reservedRate: 0,
        // Full refunds.
        redemptionRate: JBConstants.MAX_REDEMPTION_RATE,
        ballotRedemptionRate: JBConstants.MAX_REDEMPTION_RATE,
        pausePay: false,
        pauseDistributions: false,
        pauseRedeem: false,
        pauseBurn: false,
        allowMinting: false,
        allowTerminalMigration: false,
        allowControllerMigration: false,
        holdFees: _launchProjectData.holdFees,
        preferClaimedTokenOverride: false,
        useTotalOverflowForRedemptions: false,
        useDataSourceForPay: true,
        useDataSourceForRedeem: true,
        dataSource: _dataSource,
        metadata:  JBTiered721FundingCycleMetadataResolver.packFundingCycleGlobalMetadata(
          JBTiered721FundingCycleMetadata({
            pauseTransfers: false,
            pauseMintingReserves: true
          })
        )
      }),
      _launchProjectData.start - _launchProjectData.mintDuration,
      new JBGroupedSplits[](0),
      new JBFundAccessConstraints[](0),
      _terminals,
      'Defifa game phase 1.'
    );
  }

  /**
    @notice
    Gets reconfiguration data for phase 2 of the game.

    @dev
    Phase 2 freezes the treasury and activates the pre-programmed distribution limit to the specified splits.

    @param _gameId The ID of the project that's being reconfigured.
    @param _dataSource The data source to use.

    @return configuration The configuration of the funding cycle that was successfully reconfigured.
  */
  function _queuePhase2(uint256 _gameId, address _dataSource)
    internal
    returns (uint256 configuration)
  {
    // Get a reference to the terminal being used by the project.
    DefifaStoredOpsData memory _ops = _opsFor[_gameId];

    // Set fund access constraints.
    JBFundAccessConstraints[] memory fundAccessConstraints = new JBFundAccessConstraints[](1);
    fundAccessConstraints[0] = JBFundAccessConstraints({
      terminal: _ops.terminal,
      token: token,
      distributionLimit: _ops.distributionLimit,
      distributionLimitCurrency: _ops.terminal.currencyForToken(token),
      overflowAllowance: 0,
      overflowAllowanceCurrency: 0
    });

    // Fetch splits.
    JBSplit[] memory _splits =  controller.splitsStore().splitsOf(SPLIT_PROJECT_ID, SPLIT_DOMAIN, _gameId);

    // Make a group split for ETH payouts.
    JBGroupedSplits[] memory _groupedSplits;

    if (_splits.length != 0) {
      _groupedSplits = new JBGroupedSplits[](1);
      _groupedSplits[0] = JBGroupedSplits({group: JBSplitsGroups.ETH_PAYOUT, splits: _splits});
    }
    else {
      _groupedSplits = new JBGroupedSplits[](0);
    }

    // Get a reference to the time data.
    DefifaTimeData memory _times = _timesFor[_gameId];

    return
      controller.reconfigureFundingCyclesOf(
        _gameId,
        JBFundingCycleData ({
          duration: _times.tradeDeadline - _times.start,
          // Don't mint project tokens.
          weight: 0,
          discountRate: 0,
          ballot: IJBFundingCycleBallot(address(0))
        }),
        JBFundingCycleMetadata({
         global: JBGlobalFundingCycleMetadata({
            allowSetTerminals: false,
            allowSetController: false,
            pauseTransfers: false
          }),
          reservedRate: 0,
          redemptionRate: 0,
          ballotRedemptionRate: 0,
          // No more payments.
          pausePay: true,
          pauseDistributions: false,
          // No redemptions.
          pauseRedeem: true,
          pauseBurn: false,
          allowMinting: false,
          allowTerminalMigration: false,
          allowControllerMigration: false,
          holdFees: _ops.holdFees,
          preferClaimedTokenOverride: false,
          useTotalOverflowForRedemptions: false,
          useDataSourceForPay: true,
          useDataSourceForRedeem: true,
          dataSource: _dataSource,
          metadata: JBTiered721FundingCycleMetadataResolver.packFundingCycleGlobalMetadata(
            JBTiered721FundingCycleMetadata({
              pauseTransfers: false,
              pauseMintingReserves: false
            })
          )
        }),
        0, // mustStartAtOrAfter should be ASAP
         _groupedSplits,
        fundAccessConstraints,
        'Defifa game phase 2.'
      );
  }

  /**
    @notice
    Gets reconfiguration data for phase 3 of the game.

    @dev
    Phase 3 imposes a trade deadline.

    @param _gameId The ID of the project that's being reconfigured.
    @param _dataSource The data source to use.

    @return configuration The configuration of the funding cycle that was successfully reconfigured.
  */
  function _queuePhase3(uint256 _gameId, address _dataSource) internal returns (uint256 configuration) {

    // Get a reference to the time data.
    DefifaTimeData memory _times = _timesFor[_gameId];

    return
      controller.reconfigureFundingCyclesOf(
        _gameId,
        JBFundingCycleData ({
          duration: _times.end - _times.tradeDeadline,
          // Don't mint project tokens.
          weight: 0,
          discountRate: 0,
          ballot: IJBFundingCycleBallot(address(0))
        }),
        JBFundingCycleMetadata({
         global: JBGlobalFundingCycleMetadata({
            allowSetTerminals: false,
            allowSetController: false,
            pauseTransfers: false
          }),
          reservedRate: 0,
          redemptionRate: 0,
          ballotRedemptionRate: 0,
          // No more payments.
          pausePay: true,
          pauseDistributions: false,
          // No redemptions.
          pauseRedeem: true,
          pauseBurn: false,
          allowMinting: false,
          allowTerminalMigration: false,
          allowControllerMigration: false,
          holdFees: false,
          preferClaimedTokenOverride: false,
          useTotalOverflowForRedemptions: false,
          useDataSourceForPay: true,
          useDataSourceForRedeem: true,
          dataSource: _dataSource,
          // Set a metadata of 1 to impose token non-transferability.
          metadata: JBTiered721FundingCycleMetadataResolver.packFundingCycleGlobalMetadata(
            JBTiered721FundingCycleMetadata({
              pauseTransfers: true,
              pauseMintingReserves: false
            })
          )
        }),
        0, // mustStartAtOrAfter should be ASAP
        new JBGroupedSplits[](0),
        new JBFundAccessConstraints[](0),
        'Defifa game phase 3.'
      );
  }

  /**
    @notice
    Gets reconfiguration data for phase 4 of the game.

    @dev
    Phase 4 removes the trade deadline and open up redemptions.

    @param _gameId The ID of the project that's being reconfigured.
    @param _dataSource The data source to use.

    @return configuration The configuration of the funding cycle that was successfully reconfigured.
  */
  function _queuePhase4(uint256 _gameId, address _dataSource) internal returns (uint256 configuration) {
    return
      controller.reconfigureFundingCyclesOf(
        _gameId,
        JBFundingCycleData ({
          // No duration, lasts indefinately.
          duration: 0,
          // Don't mint project tokens.
          weight: 0,
          discountRate: 0,
          ballot: IJBFundingCycleBallot(address(0))
        }),
        JBFundingCycleMetadata({
         global: JBGlobalFundingCycleMetadata({
            allowSetTerminals: false,
            allowSetController: false,
            pauseTransfers: false
          }),
          reservedRate: 0,
          // Linear redemptions.
          redemptionRate: JBConstants.MAX_REDEMPTION_RATE,
          ballotRedemptionRate: JBConstants.MAX_REDEMPTION_RATE,
          // No more payments.
          pausePay: true,
          pauseDistributions: false,
          // Redemptions allowed.
          pauseRedeem: false,
          pauseBurn: false,
          allowMinting: false,
          allowTerminalMigration: false,
          allowControllerMigration: false,
          holdFees: false,
          preferClaimedTokenOverride: false,
          useTotalOverflowForRedemptions: false,
          useDataSourceForPay: true,
          useDataSourceForRedeem: true,
          dataSource: _dataSource,
          // Transferability unlocked.
          metadata: JBTiered721FundingCycleMetadataResolver.packFundingCycleGlobalMetadata(
            JBTiered721FundingCycleMetadata({
              pauseTransfers: false,
              pauseMintingReserves: false
            })
          )
        }),
        0, // mustStartAtOrAfter should be ASAP
        new JBGroupedSplits[](0),
        new JBFundAccessConstraints[](0),
        'Defifa game phase 4.'
      );
  }

   /**
    @notice Clone and redeploy the bytecode of a given address

    @dev Runtime bytecode needs a constructor -> we append this one
         to the bytecode, which is a minimalistic one only returning the runtime bytecode

         See https://github.com/drgorillamd/clone-deployed-contract/blob/master/readme.MD for details
   */
  function _clone(address _targetAddress) internal returns (address _out) {
    assembly {
      // Get deployed/runtime code size
      let _codeSize := extcodesize(_targetAddress)

      // Get a bit of freemem to land the bytecode, not updated as we'll leave this scope right after create(..)
      let _freeMem := mload(0x40)

      // Shift the length to the length placeholder, in the constructor (by adding zero's/mul)
      let _mask := mul(_codeSize, 0x100000000000000000000000000000000000000000000000000000000)

      // Insert the length in the correct spot (after the PUSH3 / 0x62)
      let _initCode := or(_mask, 0x62000000600081600d8239f3fe00000000000000000000000000000000000000)
      // --------------------------- here ^ (see the "1" from the mul step aligning)

      // Store the deployment bytecode in free memory
      mstore(_freeMem, _initCode)

      // Copy the bytecode, after the deployer bytecode in free memory
      extcodecopy(_targetAddress, add(_freeMem, _DEPLOY_BYTECODE_LENGTH), 0, _codeSize)

      // Deploy the copied bytecode (constructor + original) and return the address in 'out'
      _out := create(0, _freeMem, add(_codeSize, _DEPLOY_BYTECODE_LENGTH))
    }
  }
}
