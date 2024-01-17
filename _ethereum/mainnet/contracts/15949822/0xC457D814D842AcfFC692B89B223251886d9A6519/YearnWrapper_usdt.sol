// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.12;

import "./VaultAPI.sol";
import "./YearnWrapper.sol";

/**
 * @author RobAnon
 * @author 0xTraub
 * @author 0xTinder
 * @notice a contract for providing Yearn V2 contracts with an ERC-4626-compliant interface
 *         Developed for Resonate.
 * @dev The initial deposit to this contract should be made immediately following deployment
 */
contract YearnWrapper_usdt is YearnWrapper {

    constructor(VaultAPI _vault) YearnWrapper(_vault) {
     
    }

    /*
     *   The only difference between this contract and YearnWrapper is that YearnWrapper uses
     *   yVault.lockedProfitDegradation() and this one uses lockedProfitDegration().
     */
    function getFreeFunds() public view virtual override returns (uint256) {
        uint256 lockedFundsRatio = (block.timestamp - yVault.lastReport()) * yVault.lockedProfitDegration();
        uint256 _lockedProfit = yVault.lockedProfit();

        uint256 DEGRADATION_COEFFICIENT = 10 ** 18;
        uint256 lockedProfit = lockedFundsRatio < DEGRADATION_COEFFICIENT ? 
            _lockedProfit - (lockedFundsRatio * _lockedProfit / DEGRADATION_COEFFICIENT)
            : 0; // hardcoded DEGRADATION_COEFFICIENT        
        return yVault.totalAssets() - lockedProfit;
    }
}
