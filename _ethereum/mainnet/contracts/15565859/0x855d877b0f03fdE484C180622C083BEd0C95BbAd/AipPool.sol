// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./IAipPoolDeployer.sol";
import "./IERC20.sol";
import "./IAipPool.sol";
import "./IAipFactory.sol";
import "./IAipSwapManager.sol";

import "./IAipSubscribeCallback.sol";
import "./IAipExtendCallback.sol";
import "./TransferHelper.sol";

import "./console.sol";

contract AipPool is IAipPool, ReentrancyGuard {
    address public immutable override factory;
    address public immutable override swapManager;
    address public immutable override WETH9;
    address public override rewardToken;
    address public override rewardOperator;
    address public immutable override token0;
    address public immutable override token1;
    uint8 public immutable override frequency;
    uint16 public override swapFee = 3000;
    uint16 public override swapWETH9Fee = 3000;
    uint16 private constant PROTOCOL_FEE = 1000;
    uint16 private constant MAX_TICKS = 365;
    uint24 private constant TIME_UNIT = 24 * 3600;
    uint24 private constant PROCESSING_GAS = 400000;
    uint64 private constant MIN_TICK_AMOUNT = 10 * 1e18;

    uint256 private _nextPlanIndex = 1;
    uint256 private _nextTickIndex = 1;
    uint256 public override protocolFee;
    uint256 public override totalPaymentAmount0;
    mapping(uint256 => uint256) private _tickVolumes0;
    mapping(uint256 => uint256) private _tickVolumes1;
    mapping(uint256 => uint256) private _tickFees0;
    mapping(uint256 => uint256) private _tickTimes;
    mapping(uint256 => uint256) private _tickRewards;
    mapping(uint256 => PlanInfo) public override plans;

    constructor() {
        (
            factory,
            swapManager,
            WETH9,
            token0,
            token1,
            frequency
        ) = IAipPoolDeployer(msg.sender).parameters();
    }

    modifier onlyFactoryOwner() {
        require(msg.sender == IAipFactory(factory).owner());
        _;
    }

    modifier onlyRewardOperator() {
        require(msg.sender == rewardOperator);
        _;
    }

    function _getCurrentEndTick(uint256 endTick)
        private
        view
        returns (uint256)
    {
        return _nextTickIndex - 1 > endTick ? endTick : _nextTickIndex - 1;
    }

    function _getPlanAmount(
        uint256 tickAmount0,
        uint256 startTick,
        uint256 endTick
    ) private view returns (uint256 amount0, uint256 amount1) {
        uint256 currentEndTick = _getCurrentEndTick(endTick);
        for (uint256 i = startTick; i <= currentEndTick; i++) {
            amount0 += tickAmount0;
            amount1 += (_tickVolumes1[i] * tickAmount0) / _tickVolumes0[i];
        }
    }

    function balance0() private view returns (uint256) {
        (bool success, bytes memory data) = token0.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function balance1() private view returns (uint256) {
        (bool success, bytes memory data) = token1.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function balanceReward() private view returns (uint256) {
        (bool success, bytes memory data) = rewardToken.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function price() public view override returns (uint256) {
        return IAipSwapManager(swapManager).poolPrice(token0, token1, swapFee);
    }

    function lastTrigger()
        public
        view
        override
        returns (uint256 tick, uint256 time)
    {
        tick = _nextTickIndex - 1;
        time = _tickTimes[_nextTickIndex - 1];
    }

    function nextTickVolume()
        external
        view
        override
        returns (uint256 index, uint256 amount0)
    {
        index = _nextTickIndex;
        amount0 = _tickVolumes0[index];
    }

    function tickInfo(uint256 tick)
        external
        view
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 time,
            uint256 reward
        )
    {
        amount0 = _tickVolumes0[tick];
        amount1 = _tickVolumes1[tick];
        fee0 = _tickFees0[tick];
        time = _tickTimes[tick];
        reward = _tickRewards[tick];
    }

    function getPlanStatistics(uint256 planIndex)
        external
        view
        override
        returns (
            uint256 swapAmount1,
            uint256 withdrawnAmount1,
            uint256 ticks,
            uint256 remainingTicks,
            uint256 startedTime,
            uint256 endedTime,
            uint256 lastTriggerTime
        )
    {
        PlanInfo memory plan = plans[planIndex];
        uint256 lastTriggerTick;
        (lastTriggerTick, lastTriggerTime) = lastTrigger();
        if (plan.endTick >= plan.startTick) {
            startedTime = _tickTimes[plan.startTick];
            (, swapAmount1) = _getPlanAmount(
                plan.tickAmount0,
                plan.startTick,
                plan.endTick
            );
            withdrawnAmount1 = plan.withdrawnAmount1;
            uint24 period = TIME_UNIT * frequency;
            if (plan.endTick > lastTriggerTick) {
                if (lastTriggerTime > 0) {
                    endedTime =
                        lastTriggerTime +
                        period *
                        (plan.endTick - lastTriggerTick);
                }
                remainingTicks = plan.endTick - lastTriggerTick;
            } else {
                endedTime = _tickTimes[plan.endTick];
            }
        }
        ticks = plan.endTick + 1 - plan.startTick;
    }

    function subscribe(
        address owner,
        uint256 tickAmount0,
        uint256 ticks,
        bytes calldata data
    ) external override nonReentrant returns (uint256 planIndex) {
        require(tickAmount0 >= MIN_TICK_AMOUNT, "Invalid tick amount");
        require(ticks > 0 && ticks <= MAX_TICKS, "Invalid periods");
        planIndex = _nextPlanIndex++;
        PlanInfo memory plan = PlanInfo({
            index: planIndex,
            owner: owner,
            tickAmount0: tickAmount0,
            withdrawnIndex: 0,
            withdrawnAmount1: 0,
            startTick: _nextTickIndex,
            endTick: _nextTickIndex + ticks - 1,
            claimedRewardIndex: 0,
            claimedRewardAmount: 0
        });
        plans[planIndex] = plan;
        for (uint256 i = plan.startTick; i <= plan.endTick; i++) {
            _tickVolumes0[i] += tickAmount0;
        }
        uint256 balance0Before = balance0();
        IAipSubscribeCallback(msg.sender).aipSubscribeCallback(
            ticks * tickAmount0,
            data
        );
        require(balance0Before + ticks * tickAmount0 <= balance0(), "S");
        emit Subscribe(
            plan.index,
            plan.owner,
            plan.tickAmount0,
            plan.startTick,
            plan.endTick
        );
    }

    function extend(
        uint256 planIndex,
        uint256 ticks,
        bytes calldata data
    ) external override nonReentrant {
        PlanInfo storage plan = plans[planIndex];
        require(msg.sender == plan.owner);
        require(plan.endTick >= _nextTickIndex, "Finished");
        require(
            ticks > 0 && plan.endTick + ticks <= MAX_TICKS,
            "Invalid periods"
        );
        uint256 oldEndTick = plan.endTick;
        plan.endTick = plan.endTick + ticks;

        for (uint256 i = oldEndTick + 1; i <= plan.endTick; i++) {
            _tickVolumes0[i] += plan.tickAmount0;
        }
        uint256 balance0Before = balance0();
        IAipExtendCallback(msg.sender).aipExtendCallback(
            ticks * plan.tickAmount0,
            data
        );
        require(balance0Before + ticks * plan.tickAmount0 <= balance0(), "E");
        emit Extend(planIndex, oldEndTick, plan.endTick);
    }

    function withdraw(uint256 planIndex, address receiver)
        external
        override
        nonReentrant
        returns (uint256 received1)
    {
        PlanInfo storage plan = plans[planIndex];
        require(msg.sender == plan.owner);
        uint256 withdrawIndex = plan.withdrawnIndex == 0
            ? plan.startTick
            : plan.withdrawnIndex + 1;
        if (plan.endTick >= withdrawIndex) {
            (, received1) = _getPlanAmount(
                plan.tickAmount0,
                withdrawIndex,
                plan.endTick
            );
            plan.withdrawnAmount1 += received1;
            plan.withdrawnIndex = _nextTickIndex - 1;
        }
        require(received1 > 0, "Nothing to withdraw");
        uint256 balance1Before = balance1();
        TransferHelper.safeTransfer(token1, receiver, received1);
        require(balance1Before - received1 <= balance1(), "C1");
        emit Withdraw(planIndex, received1);
    }

    function withdrawIn(
        uint256 planIndex,
        address receiver,
        uint256 periods
    ) external override nonReentrant returns (uint256 received1) {
        PlanInfo storage plan = plans[planIndex];
        require(msg.sender == plan.owner);
        uint256 withdrawIndex = plan.withdrawnIndex == 0
            ? plan.startTick
            : plan.withdrawnIndex + 1;
        uint256 endIndex = withdrawIndex + periods - 1;
        require(
            periods > 0 &&
                endIndex <= plan.endTick &&
                endIndex <= _nextTickIndex - 1,
            "Invalid period"
        );
        (, received1) = _getPlanAmount(
            plan.tickAmount0,
            withdrawIndex,
            endIndex
        );
        plan.withdrawnAmount1 += received1;
        plan.withdrawnIndex = endIndex;
        uint256 balance1Before = balance1();
        TransferHelper.safeTransfer(token1, receiver, received1);
        require(balance1Before - received1 <= balance1(), "C1");
        emit Withdraw(planIndex, received1);
    }

    function unsubscribe(uint256 planIndex, address receiver)
        external
        override
        nonReentrant
        returns (uint256 received0, uint256 received1)
    {
        require(receiver != address(0));
        PlanInfo storage plan = plans[planIndex];
        require(msg.sender == plan.owner);
        if (plan.endTick >= _nextTickIndex) {
            uint256 oldEndTick = plan.endTick;
            plan.endTick = _nextTickIndex - 1;
            received0 = plan.tickAmount0 * (oldEndTick - plan.endTick);
            if (plan.endTick + 1 <= oldEndTick) {
                for (uint256 i = plan.endTick + 1; i <= oldEndTick; i++) {
                    _tickVolumes0[i] -= plan.tickAmount0;
                }
            }
        }
        uint256 withdrawIndex = plan.withdrawnIndex == 0
            ? plan.startTick
            : plan.withdrawnIndex + 1;
        if (plan.endTick >= withdrawIndex) {
            (, received1) = _getPlanAmount(
                plan.tickAmount0,
                withdrawIndex,
                plan.endTick
            );
            plan.withdrawnAmount1 += received1;
            plan.withdrawnIndex = _nextTickIndex - 1;
        }
        uint256 balance0Before = balance0();
        uint256 balance1Before = balance1();

        if (received0 > 0) {
            TransferHelper.safeTransfer(token0, receiver, received0);
            require(balance0Before - received0 <= balance0(), "U0");
        }
        if (received1 > 0) {
            TransferHelper.safeTransfer(token1, receiver, received1);
            require(balance1Before - received1 <= balance1(), "U1");
        }

        emit Unsubscribe(planIndex, received0, received1);
    }

    function trigger()
        external
        override
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        uint256 tickIndex = _nextTickIndex++;
        amount0 = _tickVolumes0[tickIndex];
        console.log("tickIndex", tickIndex);
        require(amount0 > 0, "Tick volume equal 0");
        if (tickIndex > 1) {
            require(
                _tickTimes[tickIndex - 1] + TIME_UNIT * frequency <=
                    block.timestamp + 5,
                "Not yet"
            );
        }
        _tickTimes[tickIndex] = block.timestamp;
        uint256 gasFee = tx.gasprice * PROCESSING_GAS;
        uint256 _price = IAipSwapManager(swapManager).poolPrice(
            token0,
            WETH9,
            swapWETH9Fee
        );
        uint256 triggerFee0 = (gasFee * 1e18) / _price;
        uint256 protocolFee0 = amount0 / PROTOCOL_FEE;

        uint256 totalSwap = amount0 - protocolFee0 - triggerFee0;

        totalPaymentAmount0 += amount0;

        TransferHelper.safeApprove(token0, swapManager, totalSwap);

        uint256 balance0Before = balance0();
        uint256 balance1Before = balance1();
        (, int256 swapAmount1) = IAipSwapManager(swapManager).swap(
            token0,
            token1,
            swapFee,
            address(this),
            true,
            totalSwap
        );

        amount1 = swapAmount1 >= 0
            ? uint256(swapAmount1)
            : uint256(-swapAmount1);
        require(amount1 > 0);
        _tickVolumes1[tickIndex] += amount1;
        _tickFees0[tickIndex] += protocolFee0 + triggerFee0;
        protocolFee += protocolFee0;
        TransferHelper.safeTransfer(token0, msg.sender, triggerFee0);
        require(balance0Before - (totalSwap + triggerFee0) <= balance0(), "T0");
        require(balance1Before + amount1 <= balance1(), "T1");
        emit Trigger(tickIndex, amount0, amount1, triggerFee0, protocolFee0);
    }

    function setSwapFee(uint16 _swapFee, uint16 _swapWETH9Fee)
        external
        override
        nonReentrant
        onlyFactoryOwner
        returns (address swapPool, address swapWETH9Pool)
    {
        require(
            _swapFee == 500 || _swapFee == 3000 || _swapFee == 10000,
            "Invalid swap fee"
        );
        swapPool = IAipSwapManager(swapManager).getPool(
            token0,
            token1,
            _swapFee
        );
        swapWETH9Pool = IAipSwapManager(swapManager).getPool(
            token0,
            WETH9,
            _swapWETH9Fee
        );
        emit SwapFeeChanged(swapFee, swapWETH9Fee, _swapFee, _swapWETH9Fee);
        swapFee = _swapFee;
        swapWETH9Fee = _swapWETH9Fee;
    }

    function claimReward(uint256 planIndex, address receiver)
        external
        override
        nonReentrant
        returns (
            address token,
            uint256 unclaimedAmount,
            uint256 claimedAmount
        )
    {
        PlanInfo storage plan = plans[planIndex];
        require(msg.sender == plan.owner);
        token = rewardToken;
        if (token != address(0)) {
            uint256 currentEndTick = _getCurrentEndTick(plan.endTick);
            uint256 currentStartTick = plan.claimedRewardIndex == 0
                ? plan.startTick
                : plan.claimedRewardIndex + 1;
            if (currentEndTick >= currentStartTick) {
                for (uint256 i = currentStartTick; i <= currentEndTick; i++) {
                    unclaimedAmount +=
                        (_tickRewards[i] * plan.tickAmount0) /
                        _tickVolumes0[i];
                }
            }

            claimedAmount = plan.claimedRewardAmount;

            if (unclaimedAmount > 0) {
                plan.claimedRewardAmount += unclaimedAmount;
                plan.claimedRewardIndex = _nextTickIndex - 1;
                uint256 balanceRewardBefore = balanceReward();
                TransferHelper.safeTransfer(
                    rewardToken,
                    receiver,
                    unclaimedAmount
                );
                require(
                    balanceRewardBefore - unclaimedAmount <= balanceReward(),
                    "CR"
                );
                emit ClaimReward(plan.index, unclaimedAmount, claimedAmount);
            }
        }
    }

    function depositReward(uint256 amount)
        external
        override
        nonReentrant
        onlyRewardOperator
    {
        _tickRewards[_nextTickIndex - 1] += amount;
        uint256 balanceRewardBefore = balanceReward();
        TransferHelper.safeTransferFrom(
            rewardToken,
            msg.sender,
            address(this),
            amount
        );
        require(balanceRewardBefore + amount <= balanceReward(), "DR");
        emit DepositReward(amount);
    }

    function initReward(address _rewardToken, address _rewardOperator)
        external
        override
        nonReentrant
        onlyFactoryOwner
    {
        require(rewardToken == address(0));
        require(_rewardToken != address(0), "Invalid token address");
        require(_rewardOperator != address(0), "Invalid operator address");
        rewardToken = _rewardToken;
        rewardOperator = _rewardOperator;
        emit InitReward(rewardToken, rewardOperator);
    }

    function changeRewardOperator(address _operator)
        external
        override
        nonReentrant
        onlyFactoryOwner
    {
        require(rewardOperator != address(0), "Operator is not exist");
        require(_operator != address(0), "Invalid address");
        emit RewardOperatorChanged(rewardOperator, _operator);
        rewardOperator = _operator;
    }

    function collectProtocol(address recipient, uint256 amountRequested)
        external
        override
        nonReentrant
        onlyFactoryOwner
        returns (uint256 amount)
    {
        amount = amountRequested > protocolFee ? protocolFee : amountRequested;

        if (amount > 0) {
            if (amount == protocolFee) amount--;
            protocolFee -= amount;
            TransferHelper.safeTransfer(token0, recipient, amount);
        }

        emit CollectProtocol(msg.sender, recipient, amount);
    }
}
