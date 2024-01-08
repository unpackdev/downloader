// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./SafeCast.sol";
import "./CrvPoolMgrBase.sol";
import "./IStableSwap3Pool.sol";
import "./IAggregatorV3.sol";

contract Crv3PoolMgr is CrvPoolMgrBase {
    IStableSwap3Pool public constant THREEPOOL = IStableSwap3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    address public constant THREECRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant GAUGE = 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;

    /* solhint-disable var-name-mixedcase */
    string[3] public COINS = ["DAI", "USDC", "USDT"];

    address[3] public COIN_ADDRS = [
        0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
        0xdAC17F958D2ee523a2206206994597C13D831ec7 // USDT
    ];
    uint256[3] public DECIMALS = [18, 6, 6];

    /* solhint-enable */

    // solhint-disable-next-line no-empty-blocks
    constructor() CrvPoolMgrBase(address(THREEPOOL), THREECRV, GAUGE) {}

    function _minimumLpPrice(uint256 _safeRate) internal view returns (uint256) {
        return ((THREEPOOL.get_virtual_price() * _safeRate) / 1e18);
    }

    function get3PoolBalances(uint256 _lpAmount) public view returns (uint256[3] memory balances) {
        // the balance of a given coin is equal to our share of the lp supply,
        // times the underlying balance, less the pool withdrawal fee
        for (uint256 i = 0; i < COINS.length; i++) {
            balances[i] =
                (((THREEPOOL.balances(i) * _lpAmount) / (IERC20(crvLp).totalSupply())) *
                    (uint256(1e10) - THREEPOOL.fee())) /
                uint256(1e10);
        }
    }

    function _withdrawAsFromCrvPool(
        uint256 _lpAmount,
        uint256 _minAmt,
        uint256 i
    ) internal {
        THREEPOOL.remove_liquidity_one_coin(_lpAmount, SafeCast.toInt128(int256(i)), _minAmt);
    }

    function _withdrawAllAs(uint256 i) internal {
        uint256 lpAmt = IERC20(crvLp).balanceOf(address(this));
        if (lpAmt != 0) {
            THREEPOOL.remove_liquidity_one_coin(lpAmt, SafeCast.toInt128(int256(i)), 0);
        }
    }

    function calcWithdrawLpAs(uint256 _amtNeeded, uint256 i)
        public
        view
        returns (uint256 lpToWithdraw, uint256 unstakeAmt)
    {
        uint256 lp = IERC20(crvLp).balanceOf(address(this));
        uint256 tlp = lp + IERC20(crvGauge).balanceOf(address(this));
        lpToWithdraw = (_amtNeeded * tlp) / getLpValueAs(tlp, i);
        lpToWithdraw = (lpToWithdraw > tlp) ? tlp : lpToWithdraw;
        if (lpToWithdraw > lp) {
            unstakeAmt = lpToWithdraw - lp;
        }
    }

    function getLpValueAs(uint256 _lpAmount, uint256 i) public view returns (uint256) {
        return (_lpAmount != 0) ? THREEPOOL.calc_withdraw_one_coin(_lpAmount, SafeCast.toInt128(int256(i))) : 0;
    }

    // While this is inaccurate in terms of slippage, this gives us the
    // best estimate (least manipulatable value) to calculate share price
    function getLpValue(uint256 _lpAmount) public view returns (uint256) {
        return (_lpAmount != 0) ? (THREEPOOL.get_virtual_price() * _lpAmount) / 1e18 : 0;
    }

    function estimateFeeImpact(uint256 _amount) public view returns (uint256) {
        return (_amount * (uint256(1e10) - estimatedFees())) / (uint256(1e10));
    }

    function estimatedFees() public view returns (uint256) {
        return (THREEPOOL.fee() * 4);
    }

    function setCheckpoint() external {
        _setCheckpoint();
    }
}
