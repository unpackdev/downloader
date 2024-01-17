// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./BaseVault.sol";
import "./IBooster.sol";
import "./IRewards.sol";
import "./ICVXRewards.sol";
import "./ICurveCrvCvxCrvPool.sol";

contract ConvexVault is BaseVault {

    struct ConstructorParams {
        address rewardToken;    // reward token
        IERC20 stakeToken;  // stake token (LP)
        address inflation;  // Inflation address
        string name;    // LP Vault token name
        string symbol;  // LP Vault token symbol
        address referralProgramAddress; // Referral program contract address
        address boosterAddress;
        uint256 poolIndex;
        address crvRewardAddress;   // CRV Rewards contract address
        address curvePool;
        uint256 percentageToBeLocked;
        address veTokenAddress;
    }

    using SafeERC20 for IERC20;

    address public immutable boosterAddress;    // Booster address
    uint256 public immutable poolIndex;   // Pool index
    address public immutable crvRewardAddress;   

    address public immutable curvePool; 

    address[2] public coins;

    /**
    * @param _params ConstructorParams struct 
    */
    constructor(
        ConstructorParams memory _params
    ) BaseVault(
        _params.rewardToken,
        _params.stakeToken,
        _params.inflation,
        _params.name,
        _params.symbol,
        _params.referralProgramAddress,
        _params.percentageToBeLocked,
        _params.veTokenAddress
    ) {
        boosterAddress = _params.boosterAddress;
        stakeToken.safeApprove(_params.boosterAddress, type(uint256).max);
        poolIndex = _params.poolIndex;
        crvRewardAddress = _params.crvRewardAddress;
        curvePool = _params.curvePool;
        for (uint256 i = 0; i < 2; i++) {
            address coinAddress = ICurveCrvCvxCrvPool(_params.curvePool).coins(i);
            IERC20(coinAddress).approve(_params.curvePool, type(uint256).max);
            coins[i] = coinAddress;
        }
    }

    function _getEarnedAmountFromExternalProtocol(address _user, uint256 _index) internal override returns(uint256 vaultEarned) {
        address crvReward = crvRewardAddress;
        Reward[] memory _rewards = rewards;
        if (_index == 1 || _index == 2 && crvReward != address(0)) { // index == CRV OR index == CVX
            IRewards(crvReward).getReward(address(this), false); // claim CRV and CVX
        }
    }

    function _harvestFromExternalProtocol() internal override {
        require(
            IRewards(crvRewardAddress).getReward(address(this), false),
            "!getRewardsCRV"
        );
    }

    function _depositToExternalProtocol(uint256 _amount, address _from) internal override {
        IERC20 stake = stakeToken;
        address booster = boosterAddress;
        if (_from != address(this)) stake.safeTransferFrom(_from, address(this), _amount);
        if (booster != address(0)) {
            IBooster(booster).depositAll(
                poolIndex,
                true
            );
        }
    }

    function depositUnderlyingTokensFor(
        uint256[2] memory _amounts, 
        uint256 _min_mint_amount, 
        address _to
    ) external whenNotPaused nonReentrant {
        for (uint256 i; i < 2; i++) {
            IERC20(coins[i]).transferFrom(_msgSender(), address(this), _amounts[i]);
        }
        uint256 received = ICurveCrvCvxCrvPool(curvePool).add_liquidity(_amounts, _min_mint_amount);
        _depositForFrom(received, _to, address(this));
    }

    function _withdrawFromExternalProtocol(uint256 _amount, address _to) internal override {
        IRewards(crvRewardAddress).withdraw(_amount, true);
        require(
            IBooster(boosterAddress).withdraw(
                poolIndex,
                _amount
            ),
            "!withdraw"
        );
        stakeToken.safeTransfer(_to, _amount);

    }

}
