pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title LegacyRegistry contract interface
 * @dev Just for to have the interface to read old contracts
 */

interface ILegacyRegistry {
	struct Creator {
		address token;
		string name;
		string symbol;
		uint8 decimals;
		uint256 totalSupply;
		address proposer;
		address vestingBeneficiary;
		uint8 initialPercentage;
		uint256 vestingPeriodInWeeks;
		bool approved;
	}

	function rolodex(bytes32) external view returns (Creator memory);

	function getIndexSymbol(string memory _symbol)
		external
		view
		returns (bytes32);
}
