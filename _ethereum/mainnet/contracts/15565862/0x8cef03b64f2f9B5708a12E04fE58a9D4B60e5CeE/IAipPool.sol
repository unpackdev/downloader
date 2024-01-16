// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipPool {
    event Trigger(
        uint256 tickIndex,
        uint256 amount0,
        uint256 amount1,
        uint256 triggerFee0,
        uint256 protocolFee0
    );

    event Subscribe(
        uint256 planIndex,
        address owner,
        uint256 tickAmount,
        uint256 startTick,
        uint256 endTick
    );

    event Extend(uint256 planIndex, uint256 oldEndTick, uint256 newEndTick);

    event Unsubscribe(uint256 planIndex, uint256 received0, uint256 received1);

    event Withdraw(uint256 planIndex, uint256 received1);

    event ClaimReward(
        uint256 planIndex,
        uint256 unclaimedAmount,
        uint256 claimedAmount
    );
    event DepositReward(uint256 amount);
    event InitReward(address token, address operator);
    event RewardOperatorChanged(
        address oldRewardOperator,
        address newRewardOperator
    );

    event SwapFeeChanged(
        uint16 oldSwapFee,
        uint16 oldSwapWETH9Fee,
        uint16 newSwapFee,
        uint16 newSwapWETH9Fee
    );
    event CollectProtocol(address requester, address receiver, uint256 amount);

    struct PlanInfo {
        uint256 index;
        address owner;
        uint256 tickAmount0;
        uint256 withdrawnIndex;
        uint256 withdrawnAmount1;
        uint256 startTick;
        uint256 endTick;
        uint256 claimedRewardIndex;
        uint256 claimedRewardAmount;
    }

    function factory() external view returns (address);

    function swapManager() external view returns (address);

    function WETH9() external view returns (address);

    function rewardToken() external view returns (address);

    function rewardOperator() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function frequency() external view returns (uint8);

    function swapFee() external view returns (uint16);

    function swapWETH9Fee() external view returns (uint16);

    function protocolFee() external view returns (uint256);

    function totalPaymentAmount0() external view returns (uint256);

    function plans(uint256)
        external
        view
        returns (
            uint256 index,
            address owner,
            uint256 tickAmount0,
            uint256 withdrawnIndex,
            uint256 withdrawnAmount1,
            uint256 startTick,
            uint256 endTick,
            uint256 claimedRewardIndex,
            uint256 claimedRewardAmount
        );

    function price() external view returns (uint256);

    function lastTrigger() external view returns (uint256 tick, uint256 time);

    function nextTickVolume()
        external
        view
        returns (uint256 index, uint256 amount0);

    function tickInfo(uint256 tick)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 time,
            uint256 reward
        );

    function getPlanStatistics(uint256 planIndex)
        external
        view
        returns (
            uint256 swapAmount1,
            uint256 withdrawnAmount1,
            uint256 ticks,
            uint256 remainingTicks,
            uint256 startedTime,
            uint256 endedTime,
            uint256 lastTriggerTime
        );

    function subscribe(
        address owner,
        uint256 tickAmount0,
        uint256 totalAmount0,
        bytes calldata data
    ) external returns (uint256 index);

    function withdraw(uint256 planIndex, address receiver)
        external
        returns (uint256 received1);

    function withdrawIn(
        uint256 planIndex,
        address receiver,
        uint256 periods
    ) external returns (uint256 received1);

    function extend(
        uint256 planIndex,
        uint256 extendedAmount0,
        bytes calldata data
    ) external;

    function unsubscribe(uint256 planIndex, address receiver)
        external
        returns (uint256 received0, uint256 received1);

    function trigger() external returns (uint256 amount0, uint256 amount1);

    function setSwapFee(uint16 _swapFee, uint16 _swapWETH9Fee)
        external
        returns (address swapPool, address swapWETH9Pool);

    function claimReward(uint256 planIndex, address receiver)
        external
        returns (
            address token,
            uint256 unclaimedAmount,
            uint256 claimedAmount
        );

    function depositReward(uint256 amount) external;

    function initReward(address _rewardToken, address _rewardOperator) external;

    function changeRewardOperator(address _operator) external;

    function collectProtocol(address recipient, uint256 amountRequested)
        external
        returns (uint256 amount);
}
