// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpCommon.sol";

import "./IAccountCenter.sol";

contract OpClaimAaveV2StakedRewards is OpCommon {
    address public immutable aaveIncentivesAddress;
    address public immutable aaveStakeRewardClaimer;

    event ClaimStkAaveReward(address[], uint256, address);
    constructor(address _aaveIncentivesAddress, address _aaveStakeRewardClaimer)
    {
        aaveIncentivesAddress = _aaveIncentivesAddress;
        aaveStakeRewardClaimer = _aaveStakeRewardClaimer;
    }

    function claimDsaAaveStakeReward(address[] calldata atokens) public {
        address EOA = AccountCenterInterface(accountCenter).getEOA(
            address(this)
        );

        _fakeClaimRewards(
                atokens,
                type(uint256).max,
                EOA
        );
        // AaveStakedTokenIncentivesController(aaveIncentivesAddress).claimRewards(
        //         atokens,
        //         type(uint256).max,
        //         EOA
        //     );
    }

    function _fakeClaimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) public {

        emit ClaimStkAaveReward(assets, amount, to);
    }
}

interface AaveStakedTokenIncentivesController {
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}
