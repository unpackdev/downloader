// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOwnable.sol";
import "./IERC20Metadata.sol";
import "./IExofiswapFactory.sol";
import "./IExofiswapPair.sol";
import "./IMigrator.sol";

interface IExofiswapFactory is IOwnable
{
	event PairCreated(IERC20Metadata indexed token0, IERC20Metadata indexed token1, IExofiswapPair pair, uint256 pairCount);

	function createPair(IERC20Metadata tokenA, IERC20Metadata tokenB) external returns (IExofiswapPair pair);
	function setFeeTo(address) external;
	function setMigrator(IMigrator) external;
	
	function allPairs(uint256 index) external view returns (IExofiswapPair);
	function allPairsLength() external view returns (uint);
	function feeTo() external view returns (address);
	function getPair(IERC20Metadata tokenA, IERC20Metadata tokenB) external view returns (IExofiswapPair);
	function migrator() external view returns (IMigrator);

	function pairCodeHash() external pure returns (bytes32);
}
