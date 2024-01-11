// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC165Spec.sol";
import "./PriceOracleSpec.sol";
import "./UpgradeableAccessControl.sol";
import "./AggregatorV3Interface.sol";

/**
 * @title Chainlink Price Feed Aggregator based Land Sale Price Oracle
 *
 * @notice LandSalePriceOracle implementation based on ILV/ETH Chainlink price feeds,
 *      see https://docs.chain.link/docs/ethereum-addresses/
 *      see https://docs.chain.link/docs/using-chainlink-reference-contracts/
 *
 * @author Basil Gorin
 */
contract LandSalePriceOracleV1 is ERC165, LandSalePriceOracle, UpgradeableAccessControl {
	/**
	 * @notice Chainlink ILV/ETH price feed aggregator maintains ILV/ETH price feed
	 */
	AggregatorV3Interface public aggregator;

	/**
	 * @notice When communicating with Chainlink ILV/ETH price feed, we verify how old
	 *      the IV/ETH price is, and if it is older than `oldAnswerThreshold`, the answer
	 *      is treated as old and is not used: `ethToIlv` conversion function throws in this case
	 */
	uint256 public oldAnswerThreshold;

	/**
	 * @notice Price Oracle manager is responsible for updating `oldAnswerThreshold` value,
	 *      and other price oracle configuration values in the future
	 *
	 * @dev Role ROLE_PRICE_ORACLE_MANAGER allows updating the `oldAnswerThreshold` value
	 *      (executing `setOldAnswerThreshold` function)
	 */
	uint32 public constant ROLE_PRICE_ORACLE_MANAGER = 0x0001_0000;

	/**
	 * @dev Fired in setOldAnswerThreshold()
	 *
	 * @param _by an address which executed update
	 * @param _oldVal old oldAnswerThreshold value
	 * @param _newVal new oldAnswerThreshold value
	 */
	event OldAnswerThresholdUpdated(address indexed _by, uint256 _oldVal, uint256 _newVal);

	/**
	 * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @param _aggregator Chainlink ILV/ETH price feed aggregator address
	 */
	function postConstruct(address _aggregator) public virtual initializer {
		// verify the inputs are set
		require(_aggregator != address(0), "aggregator address is not set");

		// assign the addresses
		aggregator = AggregatorV3Interface(_aggregator);

		// set the default value for the threshold
		oldAnswerThreshold = 30 hours;

		// verify the inputs are valid smart contracts of the expected interfaces
		// since Chainlink AggregatorV3Interface doesn't support ERC165, verify
		// by executing the functions we're going to use anyway
		// get the data
		uint8 decimals = aggregator.decimals();
		(
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		) = aggregator.latestRoundData();
		// verify the response
		require(
			decimals > 0 && roundId > 0 && answer > 0 && startedAt > 0 && updatedAt > 0 && answeredInRound > 0,
			"unexpected aggregator response"
		);

		// execute all parent initializers in cascade
		UpgradeableAccessControl._postConstruct(msg.sender);
	}

	/**
	 * @notice Restricted access function to update `oldAnswerThreshold` value, used
	 *       in `ethToIlv` conversion function to determine if Chainlink ILV/ETH price feed
	 *       returns the value fresh enough to be used
	 *
	 * @notice Note: `ethToIlv` conversion function throws if Chainlink ILV/ETH price feed
	 *      answer is older then `oldAnswerThreshold` value
	 *
	 * @notice Chainlink is expected to update ILV/ETH price at least one per day (24 hours)
	 *      therefore `oldAnswerThreshold` should be kept bigger than 24 hours
	 *
	 * @param _oldAnswerThreshold `oldAnswerThreshold` value to set
	 */
	function setOldAnswerThreshold(uint256 _oldAnswerThreshold) public {
		// verify the access permission
		require(isSenderInRole(ROLE_PRICE_ORACLE_MANAGER), "access denied");

		// check that the value supplied resides in a reasonable bounds
		require(_oldAnswerThreshold > 1 hours, "threshold too low");
		require(_oldAnswerThreshold < 7 days, "threshold too high");

		// emit an event first - to log both old and new values
		emit OldAnswerThresholdUpdated(msg.sender, oldAnswerThreshold, _oldAnswerThreshold);

		// update the `oldAnswerThreshold` value
		oldAnswerThreshold = _oldAnswerThreshold;
	}

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
		// determine and return the interface support
		return interfaceID == type(LandSalePriceOracle).interfaceId;
	}

	/**
	 * @inheritdoc LandSalePriceOracle
	 */
	function ethToIlv(uint256 ethOut) public view virtual override returns (uint256 ilvIn) {
		// get the latest round data from Chainlink price feed aggregator
		// see https://docs.chain.link/docs/price-feeds-api-reference/#latestrounddata
		(
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		) = aggregator.latestRoundData();

		// verify if the data obtained from Chainlink looks fresh, updated recently
		// TODO: review and check with Chainlink this is a correct way of ensuring data freshness
		require(roundId == answeredInRound && startedAt <= updatedAt && updatedAt <= now256(), "invalid answer");
		require(updatedAt > now256() - oldAnswerThreshold, "answer is too old");

		// calculate according to `ethOut * ilvIn / ethOut` formula and return
		return ethOut * 10 ** aggregator.decimals() / uint256(answer);
	}

	/**
	 * @dev Testing time-dependent functionality may be difficult;
	 *      we override time in the helper test smart contract (mock)
	 *
	 * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
	 */
	function now256() public view virtual returns (uint256) {
		// return current block timestamp
		return block.timestamp;
	}
}
