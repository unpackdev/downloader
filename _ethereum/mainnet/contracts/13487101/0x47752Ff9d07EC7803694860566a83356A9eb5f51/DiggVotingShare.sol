// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "ISett.sol";
import "IGeyser.sol";
import "IUniswapV2Pair.sol";
import "ICToken.sol";

import "SafeMath.sol";

contract DiggVotingShare {
    using SafeMath for uint256;

    IERC20 constant digg = IERC20(0x798D1bE841a82a273720CE31c822C61a67a601C3);
    ISett constant sett_digg =
        ISett(0x7e7E112A68d8D2E221E11047a72fFC1065c38e1a);

    //Digg is token1
    IUniswapV2Pair constant digg_wBTC_UniV2 =
        IUniswapV2Pair(0xE86204c4eDDd2f70eE00EAd6805f917671F56c52);
    ISett constant sett_digg_wBTC_UniV2 =
        ISett(0xC17078FDd324CC473F8175Dc5290fae5f2E84714);
    IGeyser constant geyser_digg_wBTC_UniV2 =
        IGeyser(0x0194B5fe9aB7e0C43a08aCbb771516fc057402e7);

    //Digg is token1
    IUniswapV2Pair constant digg_wBTC_SLP =
        IUniswapV2Pair(0x9a13867048e01c663ce8Ce2fE0cDAE69Ff9F35E3);
    ISett constant sett_digg_wBTC_SLP =
        ISett(0x88128580ACdD9c04Ce47AFcE196875747bF2A9f6);
    IGeyser constant geyser_digg_wBTC_SLP =
        IGeyser(0x7F6FE274e172AC7d096A7b214c78584D99ca988B);

    // Rari pool - fDIGG-22
    ICToken constant fDIGG =
        ICToken(0x792a676dD661E2c182435aaEfC806F1d4abdC486);

    function decimals() external pure returns (uint8) {
        return uint8(9);
    }

    function name() external pure returns (string memory) {
        return "Digg Voting Share";
    }

    function symbol() external pure returns (string memory) {
        return "Digg VS";
    }

    function totalSupply() external view returns (uint256) {
        return digg.totalSupply();
    }

    function uniswapBalanceOf(address _voter) external view returns(uint256) {
        return _uniswapBalanceOf(_voter);
    }
    function sushiswapBalanceOf(address _voter) external view returns(uint256) {
        return _sushiswapBalanceOf(_voter);
    }
    function diggBalanceOf(address _voter) external view returns(uint256) {
        return _diggBalanceOf(_voter);
    }
    function rariBalanceOf(address _voter) external view returns(uint256) {
        return _rariBalanceOf(_voter);
    }

    /*
        The voter can have Digg in Uniswap in 3 configurations:
         * Staked bUni-V2 in Geyser
         * Unstaked bUni-V2 (same as staked Uni-V2 in Sett)
         * Unstaked Uni-V2
        The top two correspond to more than 1 Uni-V2, so they are multiplied by pricePerFullShare.
        After adding all 3 balances we calculate how much DIGG it corresponds to using the pool's reserves.
    */
    function _uniswapBalanceOf(address _voter) internal view returns (uint256) {
        uint256 bUniV2PricePerShare = sett_digg_wBTC_UniV2
            .getPricePerFullShare();
        (, uint112 reserve1, ) = digg_wBTC_UniV2.getReserves();
        uint256 totalUniBalance = digg_wBTC_UniV2.balanceOf(_voter) +
            (sett_digg_wBTC_UniV2.balanceOf(_voter) * bUniV2PricePerShare) /
            1e18 +
            (geyser_digg_wBTC_UniV2.totalStakedFor(_voter) *
                bUniV2PricePerShare) /
            1e18;
        return (totalUniBalance * reserve1) / digg_wBTC_UniV2.totalSupply();
    }

    /*
        The voter can have Digg in Sushiswap in 3 configurations:
         * Staked bSushi-V2 in Geyser
         * Unstaked bSushi-V2 (same as staked Sushi-V2 in Sett)
         * Unstaked Sushi-V2
        The top two correspond to more than 1 Sushi-V2, so they are multiplied by pricePerFullShare.
        After adding all 3 balances we calculate how much DIGG it corresponds to using the pool's reserves.
    */
    function _sushiswapBalanceOf(address _voter)
        internal
        view
        returns (uint256)
    {
        uint256 bSLPPricePerShare = sett_digg_wBTC_SLP.getPricePerFullShare();
        (, uint112 reserve1, ) = digg_wBTC_SLP.getReserves();
        uint256 totalSLPBalance = digg_wBTC_SLP.balanceOf(_voter) +
            (sett_digg_wBTC_SLP.balanceOf(_voter) * bSLPPricePerShare) /
            1e18 +
            (geyser_digg_wBTC_SLP.totalStakedFor(_voter) *
                bSLPPricePerShare) /
            1e18;
        return (totalSLPBalance * reserve1) / digg_wBTC_SLP.totalSupply();
    }

    /*
        The voter can have regular Digg in 2 configurations (There is no Digg or bDigg geyser):
         * Unstaked bDigg (same as staked Digg in Sett)
         * Unstaked Digg
    */
    function _diggBalanceOf(address _voter) internal view returns (uint256) {
        uint256 bDiggPricePerShare = sett_digg.balance().mul(1e18).div(sett_digg.totalSupply());
        return
            digg.balanceOf(_voter) +
            (sett_digg.balanceOf(_voter) * bDiggPricePerShare) /
            1e18;
    }

    /*
        The voter may have deposited DIGG into the rari pool:
         * check current rate
         * balanceOf fDigg
    */
    function _rariBalanceOf(address _voter) internal view returns (uint256) {
        uint256 rate = fDIGG.exchangeRateStored();
        return (fDIGG.balanceOf(_voter) * rate) / 1e18;
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return
            _diggBalanceOf(_voter) +
            _uniswapBalanceOf(_voter) +
            _sushiswapBalanceOf(_voter) +
            _rariBalanceOf(_voter);
    }

    constructor() {}
}
