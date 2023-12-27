// SPDX-License-Identifier: MIT
// MarketConnector 
pragma solidity 0.8.21;

import "IMarketRegistry.sol";

abstract contract MarketConnector {

    address immutable public marketRegistry;
	constructor(address _markets)
    {
        marketRegistry = _markets;

    }

    event TreasuryTopup(address Asset, uint256 TopupAmount);
    event Sandbox2Topup(address Asset, uint256 TopupAmount);
    event Sandbox1Redeem(address Asset, uint256 TopupAmount);


    function _getCollateralSystemLevelM10() internal view returns(uint256) {
        return  IMarketRegistry(marketRegistry).getCollateralLevelM10();
    }
    
    function _getBalanceInStableUnits(address _holder, address[] memory _assets) 
        internal 
        view 
        returns(uint256)
    {
        return IMarketRegistry(marketRegistry).getBalanceInStableUnits(_holder, _assets);
    }
}