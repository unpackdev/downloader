// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


import "./IERC20.sol";

interface IERC20UtilityToken is IERC20 {
    function mint(address, uint256) external;
}


interface IRstStakingPool {

    struct GeneralRewardVars {
        uint32 lastUpdateTime;
        uint32 periodFinish;
        uint128 tokenRewardPerTokenStored;
        uint128 tokenRewardRate;
    }

    struct AccountRewardVars {
        uint64 lastBonus;
        uint32 lastUpdated;
        uint96 tokenRewards;
        uint128 tokenRewardPerTokenPaid;
    }

    struct AccountVars {
        uint128 xphotonBalance;
        uint128 rainbowBalance;
    }

    function rewardRate() external view returns (uint256);
    function xphotonRewardRate() external view returns (uint256);
    function minRewardStake() external view returns (uint256);

    function maxBonus() external view returns (uint256);
    function bonusDuration() external view returns (uint256);
    function bonusRate() external view returns (uint256);

    function rstToken() external view returns (IERC20);
    function rewardToken() external view returns (IERC20);

    function totalSupply() external view returns (uint256);
    function generalRewardVars() external view returns (GeneralRewardVars memory);

    function accountRewardVars(address) external view returns (AccountRewardVars memory);
    function accountVars(address) external view returns (AccountVars memory);
    function staked(address) external view returns (uint256);

    function setRewardRate(uint256) external;
    function setMinRewardStake(uint256) external;

    function setMaxBonus(uint256) external;
    function setBonusDuration(uint256) external;
    function setBonusRate(uint256) external;

    function setRewardToken(address) external;

    function setGeneralRewardVars(GeneralRewardVars memory) external;

    function setAccountRewardVars(address, AccountRewardVars memory) external;
    function setAccountVars(address, AccountVars memory) external;


    function withdrawRewardToken(address, uint256 _amount) external;

    function stakeTokens(address, uint256 _amount) external;
    function withdrawTokens(address, uint256 _amount) external;

}
