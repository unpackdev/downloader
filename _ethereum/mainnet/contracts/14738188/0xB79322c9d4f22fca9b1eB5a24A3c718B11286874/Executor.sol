// SPDX-License-Identifier: LGPL-3.0
pragma solidity =0.8.10;

import "./Config.sol";
import "./Registry.sol";
import "./DSProxyFactory.sol";
import "./CentralLogger.sol";
import "./CommunityAcknowledgement.sol";
import "./IBorrowerOperations.sol";
import "./ITroveManager.sol";
import "./ICollSurplusPool.sol";
import "./ILUSDToken.sol";
import "./IPriceFeed.sol";
import "./LiquityMath.sol";

/// @title APUS execution logic
/// @dev Should be called as delegatecall from APUS smart account proxy
contract Executor is LiquityMath{

	// ================================================================================
	// WARNING!!!!
	// Executor must not have or store any stored variables (constant and immutable variables are not stored).
	// It could conflict with proxy storage as it is called via delegatecall from proxy.
	// ================================================================================
	/* solhint-disable var-name-mixedcase */

	/// @notice Registry's contracts IDs
	bytes32 private constant CONFIG_ID = keccak256("Config");
	bytes32 private constant CENTRAL_LOGGER_ID = keccak256("CentralLogger");
	bytes32 private constant COMMUNITY_ACKNOWLEDGEMENT_ID = keccak256("CommunityAcknowledgement");

	/// @notice APUS registry address
	address public immutable registry;
	
	// MakerDAO's deployed contracts - Proxy Factory
	// see https://changelog.makerdao.com/
	DSProxyFactory public immutable ProxyFactory;

	// L1 Liquity deployed contracts
	// see https://docs.liquity.org/documentation/resources#contract-addresses
	IBorrowerOperations public immutable BorrowerOperations;
	ITroveManager public immutable TroveManager;
	ICollSurplusPool public immutable CollSurplusPool;
    ILUSDToken public immutable LUSDToken;
	IPriceFeed public immutable PriceFeed;
	
	/* solhint-enable var-name-mixedcase */

	/// @dev enum for the logger events
	enum AdjustCreditLineLiquityChoices {
		DebtIncrease, DebtDecrease, CollateralIncrease, CollateralDecrease
	}

    /* --- Variable container structs  ---
    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */
	/* solhint-disable-next-line contract-name-camelcase */
	struct LocalVariables_adjustCreditLineLiquity {
		Config config;
		uint256 neededLUSDChange;
		uint256 expectedLiquityProtocolRate;
		uint256 previousLUSDBalance;
		uint256 previousETHBalance;	
		uint16 acr;
		uint256 price;
		bool isDebtIncrease;
		uint256 mintedLUSD;
		uint256 adoptionContributionLUSD;				
	}


	/// @notice Modifier will fail if function is not called within proxy contract
	/// @dev Mofifier checks if current address is valid (MakerDAO) proxy
	modifier onlyProxy() {
		require(ProxyFactory.isProxy(address(this)), "Only proxy can call Executor");
		_;
	}

	/* solhint-disable-next-line func-visibility */
	constructor(
		address _registry,
		address _borrowerOperations,
		address _troveManager,
		address _collSurplusPool,
		address _lusdToken,
		address _priceFeed,
		address _proxyFactory
	) {
		registry = _registry;
		BorrowerOperations = IBorrowerOperations(_borrowerOperations);
		TroveManager = ITroveManager(_troveManager);
		CollSurplusPool = ICollSurplusPool(_collSurplusPool);
		LUSDToken = ILUSDToken(_lusdToken);
		PriceFeed = IPriceFeed(_priceFeed);
		ProxyFactory = DSProxyFactory(_proxyFactory);
	}

	// ------------------------------------------ Liquity functions ------------------------------------------

	/// @notice Sends LUSD amount from Smart Account to _LUSDTo account. Sends total balance if uint256.max is given as the amount.
	/* solhint-disable-next-line var-name-mixedcase */
	function sendLUSD(address _LUSDTo, uint256 _amount) internal {
		if (_amount == type(uint256).max) {
            _amount = getLUSDBalance(address(this));
        }
		// Do not transfer from Smart Account to itself, silently pass such case.
        if (_LUSDTo != address(this) && _amount != 0) {
			// LUSDToken.transfer reverts on recipient == adress(0) or == liquity contracts.
			// Overall either reverts or procedes returning true. Never returns false.
            LUSDToken.transfer(_LUSDTo, _amount);
		}
	}

	/// @notice Pulls LUSD amount from `_from` address to Smart Account. Pulls total balance if uint256.max is given as the amount.
	function pullLUSDFrom(address _from, uint256 _amount) internal {
		if (_amount == type(uint256).max) {
            _amount = getLUSDBalance(_from);
        }
		// Do not transfer from Smart Account to itself, silently pass such case.
		if (_from != address(this) && _amount != 0) {
			// function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
			// LUSDToken.transfer reverts on allowance issue, recipient == adress(0) or == liquity contracts.
			// Overall either reverts or procedes returning true. Never returns false.
			LUSDToken.transferFrom(_from, address(this), _amount);
		}
	}

	/// @notice Gets the LUSD balance of the account
	function getLUSDBalance(address _acc) internal view returns (uint256) {
		return LUSDToken.balanceOf(_acc);
	}

	/// @notice Get and apply Recognised Community Contributor Acknowledgement Rate to ACR for the Contributor
	/// @param _acr Adoption Contribution Rate in uint16
	/// @param _requestor Requestor for whom to apply Contributor Acknowledgement if is set
	function adjustAcrForRequestor(uint16 _acr, address _requestor) internal view returns (uint16) {
		// Get and apply Recognised Community Contributor Acknowledgement Rate
		CommunityAcknowledgement ca = CommunityAcknowledgement(Registry(registry).getAddress(COMMUNITY_ACKNOWLEDGEMENT_ID));

		uint16 rccar = ca.getAcknowledgementRate(keccak256(abi.encodePacked(_requestor)));

		return applyRccarOnAcr(rccar, _acr);
	}


	/// @notice Open a new credit line using Liquity protocol by depositing ETH collateral and borrowing LUSD.
	/// @dev Value is amount of ETH to deposit into Liquity Trove
	/// @param _LUSDRequestedDebt Amount of LUSD caller wants to borrow and withdraw.
	/// @param _LUSDTo Address that will receive the generated LUSD.
	/// @param _upperHint For gas optimalisation. Referring to the prevId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @param _lowerHint For gas optimalisation. Referring to the nextId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Hints should reflect calculated neededLUSDAmount instead of _LUSDRequestedDebt
	/* solhint-disable-next-line var-name-mixedcase */
	function openCreditLineLiquity(uint256 _LUSDRequestedDebt, address _LUSDTo, address _upperHint, address _lowerHint, address _caller) external payable onlyProxy {

		// Assertions and relevant reverts are done within Liquity protocol
		// Re-entrancy is avoided by calling the openTrove (cannot open the additional trove for the same smart account)
		
		Config config = Config(Registry(registry).getAddress(CONFIG_ID));

		uint256 mintedLUSD;
		uint256 neededLUSDAmount;
		uint256 expectedLiquityProtocolRate;

		{ // scope to avoid stack too deep errors
			uint16 acr = adjustAcrForRequestor(config.adoptionContributionRate(), _caller);

			// Find effectively that Liquity is in Recovery mode => 0 rate
			// TroveManager.checkRecoveryMode() requires priceFeed.fetchPrice(), 
			// which is expensive to run and will be run again when openTrove is called.
			// We use much cheaper view PriceFeed.lastGoodPrice instead, which might be outdated by 1 call
			// Consequence in such situation is that the Adoption Contribution is decreased by otherwise non applicable protocol fee.
			// There is no negative impact on the user.
			uint256 price = PriceFeed.lastGoodPrice();
			expectedLiquityProtocolRate = (TroveManager.checkRecoveryMode(price)) ? 0 : TroveManager.getBorrowingRateWithDecay();

			neededLUSDAmount = calcNeededLiquityLUSDAmount(_LUSDRequestedDebt, expectedLiquityProtocolRate, acr);

			uint256 previousLUSDBalance = getLUSDBalance(address(this));

			BorrowerOperations.openTrove{value: msg.value}(
				LIQUITY_PROTOCOL_MAX_BORROWING_FEE,
				neededLUSDAmount,
				_upperHint,
				_lowerHint
			);

			mintedLUSD = getLUSDBalance(address(this)) - previousLUSDBalance;
		}

		// Can send only what was minted
		// assert (_LUSDRequestedDebt <= mintedLUSD); // asserts in adoptionContributionLUSD calculation by avoiding underflow
		uint256 adoptionContributionLUSD = mintedLUSD - _LUSDRequestedDebt;

		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "openCreditLineLiquity",
			abi.encode(_LUSDRequestedDebt, _LUSDTo, _upperHint, _lowerHint, neededLUSDAmount, mintedLUSD, expectedLiquityProtocolRate)
		);

		// Send LUSD to the Adoption DAO
		sendLUSD(config.adoptionDAOAddress(), adoptionContributionLUSD);

		// Send LUSD to the requested address
		// Must be located at the end to avoid withdrawal by re-entrancy into potential LUSD withdrawal function
		sendLUSD(_LUSDTo, _LUSDRequestedDebt);
	}


	/// @notice Closes the Liquity trove
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param _caller msg.sender in the Stargate
	/// @dev Closing Liquity Credit Line pulls required LUSD and therefore requires approval on LUSD spending
	/* solhint-disable-next-line var-name-mixedcase */
	function closeCreditLineLiquity(address _LUSDFrom, address payable _collateralTo, address _caller) public onlyProxy {

		uint256 collateral = TroveManager.getTroveColl(address(this));

		// getTroveDebt returns composite debt including 200 LUSD gas compensation
		// Liquity Trove cannot have less than 2000 LUSD total composite debt
		// @dev Substraction is safe since solidity 0.8 reverts on underflow
		uint256 debtToRepay = TroveManager.getTroveDebt(address(this)) - LIQUITY_LUSD_GAS_COMPENSATION;

		// Liquity requires to have LUSD on the msg.sender, i.e. on Smart Account proxy
		// Pull LUSD from _from (typically EOA) to Smart Account proxy
		pullLUSDFrom(_LUSDFrom, debtToRepay);

		// Closing trove results in ETH to be stored on Smart Account proxy
		BorrowerOperations.closeTrove(); 

		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "closeCreditLineLiquity",
			abi.encode(_LUSDFrom, _collateralTo, debtToRepay, collateral)
		);

		// Must be last to avoid re-entrancy attack
		// In fact BorrowerOperations.closeTrove() fails on re-entrancy since Trove would be closed in re-entrancy
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = _collateralTo.call{ value: collateral }("");
		require(success, "Sending collateral ETH failed");

	}

	/// @notice Closes the Liquity trove using EIP2612 Permit.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param v EIP2612 secp256k1 permit signature part
	/// @param r EIP2612 secp256k1 permit signature part
	/// @param s EIP2612 secp256k1 permit signature part
	/// @param _caller msg.sender in the Stargate
	/// @dev Closing Liquity Credit Line pulls required LUSD and therefore requires approval on LUSD spending
	/* solhint-disable-next-line var-name-mixedcase */
	function closeCreditLineLiquityWithPermit(address _LUSDFrom, address payable _collateralTo, uint8 v, bytes32 r, bytes32 s, address _caller) external onlyProxy {
		// getTroveDebt returns composite debt including 200 LUSD gas compensation
		// Liquity Trove cannot have less than 2000 LUSD total composite debt
		// @dev Substraction is safe since solidity 0.8 reverts on underflow
		uint256 debtToRepay = TroveManager.getTroveDebt(address(this)) - LIQUITY_LUSD_GAS_COMPENSATION;

		LUSDToken.permit(_LUSDFrom, address(this), debtToRepay, type(uint256).max, v, r, s);

		closeCreditLineLiquity(_LUSDFrom, _collateralTo, _caller);
	}

	/// @notice Enables a borrower to simultaneously change both their collateral and debt.
	/// @param _isDebtIncrease Indication whether _LUSDRequestedChange increases debt (true), decreases debt(false) or does not impact debt (false).
	/// @param _LUSDRequestedChange Amount of LUSD to be returned or further borrowed.
	///			The increase or decrease is indicated by _isDebtIncrease.
	///			Adoption Contribution and protocol's fees are applied in the form of additional debt in case of requested debt increase.
	/// @param _LUSDAddress Address where the LUSD is being pulled from in case of to repaying debt.
	/// Or address that will receive the generated LUSD in case of increasing debt.
	/// Approval of LUSD transfers for given Smart Account is required in case of repaying debt.
	/// @param _collWithdrawal Amount of ETH collateral to withdraw. MUST be 0 if ETH is provided to increase collateral.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param _upperHint For gas optimalisation. Referring to the prevId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @param _lowerHint For gas optimalisation. Referring to the nextId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Hints should reflect calculated neededLUSDChange instead of _LUSDRequestedChange
	/// @dev Value is amount of ETH to deposit into Liquity protocol
	/* solhint-disable var-name-mixedcase */
	function adjustCreditLineLiquity(
		bool _isDebtIncrease,
		uint256 _LUSDRequestedChange,
		address _LUSDAddress,
		uint256 _collWithdrawal,
		address _collateralTo,
		address _upperHint, address _lowerHint, address _caller
		/* solhint-enable var-name-mixedcase */
	) public payable onlyProxy {

		// Assertions and relevant reverts are done within Liquity protocol

		LocalVariables_adjustCreditLineLiquity memory vars;
		
		vars.config = Config(Registry(registry).getAddress(CONFIG_ID));

		// Make sure there is a requested increase in debt
		vars.isDebtIncrease = _isDebtIncrease && (_LUSDRequestedChange > 0);

		// Handle pre trove action regarding debt.
		if (vars.isDebtIncrease) {
			{
			vars.acr = adjustAcrForRequestor(vars.config.adoptionContributionRate(), _caller);

			// Find effectively that Liquity is in Recovery mode => 0 rate
			// TroveManager.checkRecoveryMode() requires priceFeed.fetchPrice(), 
			// which is expensive to run and will be run again when adjustTrove is called.
			// We use much cheaper view PriceFeed.lastGoodPrice instead, which might be outdated by 1 call
			// Consequence in such situation is that the Adoption Contribution is decreased by otherwise non applicable protocol fee.
			// There is no negative impact on the user.
			vars.price = PriceFeed.lastGoodPrice();
			vars.expectedLiquityProtocolRate = (TroveManager.checkRecoveryMode(vars.price)) ? 0 : TroveManager.getBorrowingRateWithDecay();

			vars.neededLUSDChange = calcNeededLiquityLUSDAmount(_LUSDRequestedChange, vars.expectedLiquityProtocolRate, vars.acr);
			}
		} else {
			// Debt decrease (= repayment) or no change in debt
			vars.neededLUSDChange = _LUSDRequestedChange;

			if (vars.neededLUSDChange > 0) {
				// Debt decrease
				// Liquity requires to have LUSD on the msg.sender, i.e. on Smart Account proxy
				// Pull LUSD from _LUSDAddress (typically EOA) to Smart Account proxy
				// Pull is re-entrancy safe as we call non upgradable LUSDToken
				pullLUSDFrom(_LUSDAddress, vars.neededLUSDChange);
			}
		}

		vars.previousLUSDBalance = getLUSDBalance(address(this));
		vars.previousETHBalance = address(this).balance;

		// Check on singular-collateral-change is done within Liquity
		// Receiving ETH in case of collateral increase is implemented by passing the value. 
		BorrowerOperations.adjustTrove{value: msg.value}(
				LIQUITY_PROTOCOL_MAX_BORROWING_FEE,
				_collWithdrawal,
				vars.neededLUSDChange,
				vars.isDebtIncrease,
				_upperHint,
				_lowerHint
			);

		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));

		// Handle post trove-change regarding debt.
		// Only debt increase requires actions, as debt decrease was handled by pre trove operation.
		if (vars.isDebtIncrease) {
			vars.mintedLUSD = getLUSDBalance(address(this)) - vars.previousLUSDBalance;
			// Can send only what was minted
			// assert (_LUSDRequestedChange <= mintedLUSD); // asserts in adoptionContributionLUSD calculation by avoiding underflow
			vars.adoptionContributionLUSD = vars.mintedLUSD - _LUSDRequestedChange;

			// Send LUSD to the Adoption DAO
			sendLUSD(vars.config.adoptionDAOAddress(), vars.adoptionContributionLUSD);

			// Send LUSD to the requested address
			sendLUSD(_LUSDAddress, _LUSDRequestedChange);


			logger.log(
				address(this), _caller, "adjustCreditLineLiquity",
				abi.encode(
					AdjustCreditLineLiquityChoices.DebtIncrease, 
					vars.mintedLUSD, 
					_LUSDRequestedChange,
					_LUSDAddress
					)
			);

		} else if (vars.neededLUSDChange > 0) {
			// Log debt decrease
			logger.log(
				address(this), _caller, "adjustCreditLineLiquity",
				abi.encode(AdjustCreditLineLiquityChoices.DebtDecrease, _LUSDRequestedChange, _LUSDAddress)
			);
		}

		// Handle post trove-change regarding collateral.
		// Only collateral decrease (withdrawal) requires actions, 
		// as collateral increase was handled by passing value to the trove operation (= getting ETH from sender into the trove).
		if (msg.value > 0) {
			// Log collateral increase
			logger.log(
				address(this), _caller, "adjustCreditLineLiquity",
				abi.encode(AdjustCreditLineLiquityChoices.CollateralIncrease, msg.value, _caller)
			);

		} else if (_collWithdrawal > 0) {
			// Collateral decrease

			// Make sure we send what was provided by the Trove
			uint256 collateralChange = address(this).balance - vars.previousETHBalance;

			logger.log(
				address(this), _caller, "adjustCreditLineLiquity",
				abi.encode(AdjustCreditLineLiquityChoices.CollateralDecrease, collateralChange, _collWithdrawal, _collateralTo)
			);

			// Must be last to avoid re-entrancy attack
			// solhint-disable-next-line avoid-low-level-calls
			(bool success, ) = _collateralTo.call{ value: collateralChange }("");
			require(success, "Sending collateral ETH failed");
		}
	}

	/// @notice Enables a borrower to simultaneously change both their collateral and decrease debt providing LUSD from ANY ADDRESS using EIP2612 Permit. 
	/// Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// It is useful only when the debt decrease is requested while working with collateral.
	/// In all other cases [adjustCreditLineLiquity()] MUST be used. It is cheaper on gas.
	/// @param _LUSDRequestedChange Amount of LUSD to be returned.
	/// @param _LUSDFrom Address where the LUSD is being pulled from. Can be ANY ADDRESS with enough LUSD.
	/// Approval of LUSD transfers for given Smart Account is ensured by the offchain signature from that address.
	/// @param _collWithdrawal Amount of ETH collateral to withdraw. MUST be 0 if ETH is provided to increase collateral.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param v EIP2612 secp256k1 permit signature part
	/// @param r EIP2612 secp256k1 permit signature part
	/// @param s EIP2612 secp256k1 permit signature part
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Value is amount of ETH to deposit into Liquity protocol
	/* solhint-disable var-name-mixedcase */
	function adjustCreditLineLiquityWithPermit(
		uint256 _LUSDRequestedChange,
		address _LUSDFrom,
		uint256 _collWithdrawal,
		address _collateralTo,
		address _upperHint, address _lowerHint,
		uint8 v, bytes32 r, bytes32 s,
		address _caller
		/* solhint-enable var-name-mixedcase */
	) external payable onlyProxy {
		LUSDToken.permit(_LUSDFrom, address(this), _LUSDRequestedChange, type(uint256).max, v, r, s);

		adjustCreditLineLiquity(false, _LUSDRequestedChange, _LUSDFrom, _collWithdrawal, _collateralTo, _upperHint, _lowerHint, _caller);
	}

	/// @notice Claims remaining collateral from the user's closed Liquity Trove due to a redemption or a liquidation with ICR > MCR in Recovery Mode
	/// @param _collateralTo Address that will receive the claimed collateral ETH.
	/// @param _caller msg.sender in the Stargate
	function claimRemainingCollateralLiquity(address payable _collateralTo, address _caller) external onlyProxy {
		
		uint256 remainingCollateral = CollSurplusPool.getCollateral(address(this));

		// Reverts if there is no collateral to claim 
		BorrowerOperations.claimCollateral();

		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "claimRemainingCollateralLiquity",
			abi.encode(_collateralTo, remainingCollateral)
		);

		// Send claimed ETH
		// Must be last to avoid re-entrancy attack
		// In fact BorrowerOperations.claimCollateral() reverts on re-entrancy since there will be no residual collateral to claim
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = _collateralTo.call{ value: remainingCollateral }("");
		/* solhint-disable-next-line reason-string */
		require(success, "Sending of claimed collateral failed.");
	}

	/// @notice Allows ANY ADDRESS (calling and paying) to add ETH collateral to borrower's Credit Line (Liquity protocol) and thus increase CR (decrease LTV ratio).
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// 	DANGEROUS operation, which can be initiated by non-owner of Smart Account (via Smart Account, though)
	///		Having the impact on the Smart Account storage. Therefore no 3rd party contract besides Liquity is called.
	function addCollateralLiquity(address _upperHint, address _lowerHint, address _caller) external payable onlyProxy {

		BorrowerOperations.addColl{value: msg.value}(_upperHint, _lowerHint);

		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "addCollateralLiquity",
			abi.encode(msg.value, _caller)
		);
	}


	/// @notice Withdraws amount of ETH collateral from the Credit Line and transfer to _collateralTo address.
	/// @param _collWithdrawal Amount of ETH collateral to withdraw
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	function withdrawCollateralLiquity(uint256 _collWithdrawal, address payable _collateralTo, address _upperHint, address _lowerHint, address _caller) external onlyProxy {

		// Withdrawing results in ETH to be stored on Smart Account proxy
		BorrowerOperations.withdrawColl(_collWithdrawal, _upperHint, _lowerHint);

		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "withdrawCollateralLiquity",
			abi.encode(_collWithdrawal, _collateralTo)
		);

		// Must be last to mitigate re-entrancy attack
		// Re-entrancy only enables caller to withdraw and transfer more ETH if allowed by the trove.
		// Having just negative impact on the caller (by spending more gas).
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = _collateralTo.call{ value: _collWithdrawal }("");
		require(success, "Sending collateral ETH failed");

	}

	/// @notice Enables credit line owner to partially repay the debt from ANY ADDRESS by the given amount of LUSD.
	/// Approval of LUSD transfers for given Smart Account is required.
	/// Cannot repay below 2000 LUSD composite debt. Use closeCreditLineLiquity to repay whole debt instead.
	/// @param _LUSDRequestedChange Amount of LUSD to be repaid. Repaying is subject to leaving 2000 LUSD min. debt in the Liquity protocol.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/* solhint-disable-next-line var-name-mixedcase */	
	function repayLUSDLiquity(uint256 _LUSDRequestedChange, address _LUSDFrom, address _upperHint, address _lowerHint, address _caller) public onlyProxy {
		// Debt decrease
		// Liquity requires to have LUSD on the msg.sender, i.e. on Smart Account proxy
		// Pull LUSD from _LUSDFrom (typically EOA) to Smart Account proxy
		// Pull is re-entrancy safe as we call non upgradable LUSDToken contract
		pullLUSDFrom(_LUSDFrom, _LUSDRequestedChange);

		BorrowerOperations.repayLUSD(_LUSDRequestedChange, _upperHint, _lowerHint);

		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "repayLUSDLiquity",
			abi.encode(_LUSDRequestedChange, _LUSDFrom)
		);

	}

	/// @notice Enables credit line owner to partially repay the debt from ANY ADDRESS by the given amount of LUSD using EIP 2612 Permit.
	/// Approval of LUSD transfers for given Smart Account is ensured by the offchain signature from that address.
	/// Cannot repay below 2000 LUSD composite debt. Use closeCreditLineLiquity to repay whole debt instead.
	/// @param _LUSDRequestedChange Amount of LUSD to be repaid. Repaying is subject to leaving 2000 LUSD min. debt in the Liquity protocol.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param v EIP2612 secp256k1 permit signature part
	/// @param r EIP2612 secp256k1 permit signature part
	/// @param s EIP2612 secp256k1 permit signature part
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/* solhint-disable-next-line var-name-mixedcase */	
	function repayLUSDLiquityWithPermit(uint256 _LUSDRequestedChange, address _LUSDFrom, address _upperHint, address _lowerHint, uint8 v, bytes32 r, bytes32 s, address _caller) external onlyProxy {
		LUSDToken.permit(_LUSDFrom, address(this), _LUSDRequestedChange, type(uint256).max, v, r, s);

		repayLUSDLiquity(_LUSDRequestedChange, _LUSDFrom, _upperHint, _lowerHint, _caller);
	}

}
