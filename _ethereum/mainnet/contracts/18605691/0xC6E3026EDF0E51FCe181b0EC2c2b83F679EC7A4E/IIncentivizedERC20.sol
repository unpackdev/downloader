// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./IScaledBalanceToken.sol";
import "./IInitializableAToken.sol";
import "./IAaveIncentivesController.sol";

interface IIncentivizedERC20 {
	function getAssetPrice() external view returns (uint256);

	function decimals() external view returns (uint8);
}
