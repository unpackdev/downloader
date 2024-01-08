pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import "./IFarmingPool.sol";

contract AdvanceAggregator {

	constructor () public {}
	
	function advance(address[] calldata farmingPools) external {
		for (uint i = 0; i < farmingPools.length; i++) {
			IFarmingPool(farmingPools[i]).advance();
		}
	}

}