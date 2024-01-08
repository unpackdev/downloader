// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./SafeMath.sol";

interface IStake {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

// ichi-1inch LP token 0x1dcE26F543E591c27717e25294AEbbF59AD9f3a5
// 1inch farm token 0x7dEd1B278D244f707214759C45c1540834890E95

contract oneINCHICHIPowah {
    using SafeMath for uint256;

    string public DESCRIPTION = "ICHIPowah Interperter for 1inch ichi LP tokens";

    address public ICHIaddress = 0x903bEF1736CDdf2A537176cf3C64579C3867A881; //mainnet
    address public oneINCHFarmICHIaddress = 0x7dEd1B278D244f707214759C45c1540834890E95;

    function getSupply(address instance) public view returns (uint256 ichi) {
        IStake stake = IStake(instance);
        IERC20 ichiToken = IERC20(ICHIaddress);

        ichi = ichiToken.balanceOf(address(stake));
    }

    function getPowah(address instance, address user, bytes32 /*params*/) public view returns (uint256 ichi) {
        // get user wallet LP balance
        IStake LPToken = IStake(instance);
        IERC20 ichiToken = IERC20(ICHIaddress);
        uint256 LP_ICHI_balance = ichiToken.balanceOf(address(LPToken));
        uint256 user_wallet_total_lp = LPToken.balanceOf(user);
        ichi = ichi.add(LP_ICHI_balance.mul(user_wallet_total_lp).div(LPToken.totalSupply()));

        // get user balance in farm
        IStake LPFarm = IStake(oneINCHFarmICHIaddress);
        uint256 user_farm_tokens = LPFarm.balanceOf(user);
        if (user_farm_tokens > 0) {
            uint256 user_LP_Staked = LPToken.balanceOf(address(LPFarm)).mul(user_farm_tokens).div(LPFarm.totalSupply());
            ichi = ichi.add(LP_ICHI_balance.mul(user_LP_Staked).div(LPToken.totalSupply()));
        }
    }
}

