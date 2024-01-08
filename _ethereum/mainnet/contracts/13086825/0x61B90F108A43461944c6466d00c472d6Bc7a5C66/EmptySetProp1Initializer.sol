// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.6;

import "./IUniswapV3Staker.sol";
import "./SafeERC20.sol";

contract EmptySetProp1Initializer {
    using SafeERC20 for IERC20;

    event IncentivesInitialized(bytes32 dsuIncentiveId, bytes32 essIncentiveId);

    IERC20 public constant STAKE = IERC20(0x24aE124c4CC33D6791F8E8B63520ed7107ac8b3e);
    address public constant TIMELOCK = address(0x1bba92F379375387bf8F927058da14D47464cB7A);
    address public constant RESERVE = address(0xD05aCe63789cCb35B9cE71d01e4d632a0486Da4B);

    IUniswapV3Staker public constant STAKER = IUniswapV3Staker(0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d);
    address public constant DSU_USDC_POOL = address(0x3432ef874A39BB3013e4d574017e0cCC6F937efD);
    address public constant ESS_WETH_POOL = address(0xd2Ef54450ec52347bde3dab7B086bf2a005601d8);

    function start() external {
        require(STAKE.balanceOf(address(this)) == 12_000_000 ether, "Prop1Initializer: incorrect stake");

        STAKE.approve(address(STAKER), 12_000_000 ether);

        IUniswapV3Staker.IncentiveKey memory dsuIncentiveKey = IUniswapV3Staker.IncentiveKey({
            rewardToken: STAKE,
            pool: DSU_USDC_POOL,
            startTime: block.timestamp,
            endTime: block.timestamp + 90 days,
            refundee: RESERVE
        });

        IUniswapV3Staker.IncentiveKey memory essIncentiveKey = IUniswapV3Staker.IncentiveKey({
            rewardToken: STAKE,
            pool: ESS_WETH_POOL,
            startTime: block.timestamp,
            endTime: block.timestamp + 90 days,
            refundee: RESERVE
        });

        STAKER.createIncentive(dsuIncentiveKey, 8_000_000 ether);
        STAKER.createIncentive(essIncentiveKey, 4_000_000 ether);

        require(STAKE.balanceOf(address(this)) == 0, "Prop1Initializer: stake left over");

        emit IncentivesInitialized(computeIncentiveId(dsuIncentiveKey), computeIncentiveId(essIncentiveKey));
    }

    function cancel() external {
        require(msg.sender == TIMELOCK, "Prop1Initializer: not timelock");
        STAKE.transfer(RESERVE, STAKE.balanceOf(address(this)));
    }

    function computeIncentiveId(IUniswapV3Staker.IncentiveKey memory key) private pure returns (bytes32) {
        return keccak256(abi.encode(key));
    }
}
