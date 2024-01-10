// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpCommon.sol";

import "./IAccountCenter.sol";

contract OpClaimAaveV2StakedRewards is OpCommon {

    address public immutable aaveIncentivesAddress;
    address public immutable aaveStakeRewardClaimer;


    constructor(address _aaveIncentivesAddress, address _aaveStakeRewardClaimer) {
        aaveIncentivesAddress = _aaveIncentivesAddress;
        aaveStakeRewardClaimer = _aaveStakeRewardClaimer;
    }

    function claimDsaAaveStakeReward(address[] memory atokens)
        public
    {
        address EOA = AccountCenterInterface(accountCenter).getEOA(
            address(this)
        );

        AaveStakedTokenIncentivesController(aaveIncentivesAddress).claimRewards(
            atokens,
            type(uint256).max,
            EOA        
        );
    }
}

interface AaveStakedTokenIncentivesController {
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}
