// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./SafeMath.sol";

interface IStake {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IFarm {
    function getLPSupply(uint256) external view returns (uint256);
    function userInfo(uint256 poolid, address account) external view returns (uint256, uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


contract ICHIFarmPowah {
    using SafeMath for uint256;

    string public DESCRIPTION = "ICHIPowah Interperter for ichi LP tokens in ICHI Farm";

    address public ICHIaddress = 0x903bEF1736CDdf2A537176cf3C64579C3867A881; //mainnet
    address public ICHIFarmAddress = 0x275dFE03bc036257Cd0a713EE819Dbd4529739c8;
     
    uint256 public SUSHIFarmPoolID = 79;

    function getSupply(address instance) public view returns (uint256 ichi) {
        IStake stake = IStake(instance);
        IERC20 ichiToken = IERC20(ICHIaddress);

        ichi = ichiToken.balanceOf(address(stake));
    }

    function getPowah(address instance, address user, bytes32 params) public view returns (uint256 ichi) {
        uint256 poolid = uint256(params);
        // get user wallet LP balance
        IStake LPToken = IStake(instance);
        IERC20 ichiToken = IERC20(ICHIaddress);
        uint256 LP_ICHI_balance = ichiToken.balanceOf(address(LPToken));
        uint256 user_wallet_total_lp = LPToken.balanceOf(user);
        ichi = ichi.add(LP_ICHI_balance.mul(user_wallet_total_lp).div(LPToken.totalSupply()));

        // get user balance in farm
        IFarm ichiFarm = IFarm(ICHIFarmAddress);
        uint256 user_farm_tokens;
        (user_farm_tokens, ) = ichiFarm.userInfo(poolid, user);
        if (user_farm_tokens > 0) {
           ichi = ichi.add(LP_ICHI_balance.mul(user_farm_tokens).div(LPToken.totalSupply()));
        }
    }
}

