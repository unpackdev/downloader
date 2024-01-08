// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./Math.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./YapePair.sol";

contract YapeRebalancer {
    using SafeERC20 for IERC20;
    uint256 private constant DENOMINATOR = 10000;

    function rebalance(address pair) public {
        _rebalance(pair);
    }

    function rebalanceAll(address[] memory pairs) public {
        for (uint256 i = 0; i < pairs.length; i++) {
            _rebalance(pairs[i]);
        }
    }

    function expectedRevenue(address pair_) public view returns (uint256 yield0, uint256 yield1) {
        YapePair pair = YapePair(pair_);
        yield0 = _expectedRevenue(pair, pair.token0());
        yield1 = _expectedRevenue(pair, pair.token1());
    }

    function _rebalance(address pair_) internal {
        YapePair pair = YapePair(pair_);
        address token0 = pair.token0();
        address token1 = pair.token1();
        pair.rebalance(token0);
        pair.rebalance(token1);
    }

    function _expectedRevenue(YapePair pair, address token)
        internal
        view
        returns (uint256)
    {
        (uint256 min, uint256 max) = pair.farmingRatio();
        uint256 newBal = _balanceOf(pair, token);
        uint256 minFarming = (newBal * min) / DENOMINATOR;
        uint256 maxFarming = (newBal * max) / DENOMINATOR;
        uint256 currentFarming = pair.farming(token);
        uint256 avg = Math.average(minFarming, maxFarming);
        if (currentFarming > avg) {
            // should withdraw from Yearn
            uint256 yearnBal = pair.totalVaultBalance(token, address(this));
            uint256 farmingAmount = pair.farming(token);
            uint256 yield;
            if (yearnBal > farmingAmount) {
                yield = yearnBal - farmingAmount;
            } else {
                // rare case
                yield = 0;
            }
            return yield;
        } else {
            return 0;
        }
    }

    function _balanceOf(YapePair pair, address token)
        internal
        view
        returns (uint256)
    {
        return
            IERC20(token).balanceOf(address(pair)) +
            YapePair(pair).farming(token);
    }
}
