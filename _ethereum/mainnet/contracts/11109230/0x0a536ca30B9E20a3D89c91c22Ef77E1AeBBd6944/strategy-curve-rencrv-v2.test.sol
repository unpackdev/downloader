// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;



import "./hevm.sol";
import "./user.sol";
import "./test-approx.sol";
import "./test-defi-base.sol";
import "./test-strategy-curve-farm-base.sol";

import "./strategy.sol";
import "./curve.sol";
import "./uniswapv2.sol";

import "./pickle-jar.sol";
import "./controller-v4.sol";

import "./strategy-curve-rencrv-v2.sol";

contract StrategyCurveRenCRVv2Test is StrategyCurveFarmTestBase {
    function setUp() public {
        governance = address(this);
        strategist = address(this);
        devfund = address(new User());
        treasury = address(new User());
        timelock = address(this);

        want = ren_crv;

        controller = new ControllerV4(
            governance,
            strategist,
            timelock,
            devfund,
            treasury
        );

        strategy = IStrategy(
            address(
                new StrategyCurveRenCRVv2(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );

        pickleJar = new PickleJar(
            strategy.want(),
            governance,
            timelock,
            address(controller)
        );

        controller.setJar(strategy.want(), address(pickleJar));
        controller.approveStrategy(strategy.want(), address(strategy));
        controller.setStrategy(strategy.want(), address(strategy));

        hevm.warp(startTime);

        _getWant(10e8); // 10 wbtc
    }

    function _getWant(uint256 btcAmount) internal {
        _getERC20(wbtc, btcAmount);
        uint256[2] memory liquidity;
        liquidity[1] = IERC20(wbtc).balanceOf(address(this));
        IERC20(wbtc).approve(ren_pool, liquidity[1]);
        ICurveFi_2(ren_pool).add_liquidity(liquidity, 0);
    }

    // **** Tests **** //

    function test_rencrv_v1_withdraw() public {
        _test_withdraw();
    }

    function test_rencrv_v1_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
