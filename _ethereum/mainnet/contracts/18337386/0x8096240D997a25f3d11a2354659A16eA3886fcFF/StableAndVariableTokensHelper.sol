// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import "./StableDebtToken.sol";
import "./VariableDebtToken.sol";
import "./LendingRateOracle.sol";
import "./Ownable.sol";

contract StableAndVariableTokensHelper is Ownable {
	address payable private pool;
	address private addressesProvider;
	event deployedContracts(address stableToken, address variableToken);

	constructor(address payable _pool, address _addressesProvider) {
		pool = _pool;
		addressesProvider = _addressesProvider;
	}

	function initDeployment(address[] calldata tokens, string[] calldata symbols) external onlyOwner {
		require(tokens.length == symbols.length, "Arrays not same length");
		require(pool != address(0), "Pool can not be zero address");
		uint256 length = tokens.length;
		for (uint256 i = 0; i < length; ) {
			emit deployedContracts(address(new StableDebtToken()), address(new VariableDebtToken()));
			unchecked {
				i++;
			}
		}
	}

	function setOracleBorrowRates(
		address[] calldata assets,
		uint256[] calldata rates,
		address oracle
	) external onlyOwner {
		require(assets.length == rates.length, "Arrays not same length");

		uint256 length = assets.length;
		for (uint256 i = 0; i < length; ) {
			// LendingRateOracle owner must be this contract
			LendingRateOracle(oracle).setMarketBorrowRate(assets[i], rates[i]);
			unchecked {
				i++;
			}
		}
	}

	function setOracleOwnership(address oracle, address admin) external onlyOwner {
		require(admin != address(0), "owner can not be zero");
		require(LendingRateOracle(oracle).owner() == address(this), "helper is not owner");
		LendingRateOracle(oracle).transferOwnership(admin);
	}
}
