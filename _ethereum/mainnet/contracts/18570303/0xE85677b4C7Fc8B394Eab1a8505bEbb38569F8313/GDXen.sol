// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Context.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./ABDKMath64x64.sol";
import "./IBurnRedeemable.sol";
import "./GDXenERC20.sol";
import "./XecERC20.sol";
import "./XENCrypto.sol";
import "./Xec.sol";

contract GDXen is Context, ReentrancyGuard, IBurnRedeemable {
    using SafeERC20 for GDXenERC20;
    using SafeERC20 for XecERC20;
    using Math for uint256;
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    GDXenERC20 public gdxen;

    XecERC20 public xecToken;

    Xec public xec;

    XENCrypto public xen;

    address public teamAddress;

    uint256 public constant MAX_BPS = 100_000;

    uint256 public constant XEN_BATCH_AMOUNT = 2_000_000 ether;
    // 2 multiple
    uint256 public constant PROTOCOL_FEE_AMPLIFIER = 2;
    // protocol fee base
    uint256 public constant PROTOCOL_FEE_BASE = 1e15;

    uint256 public constant SCALING_FACTOR = 1e40;

    uint256 public constant SCALING_FACTOR_5 = 1e5;

    uint256 public constant HEALTH_E = 102;

    uint256 public constant HEALTH_K = 2;

    uint256 public constant HEALTH_A = 1;

    uint256 public constant HEALTH_INIT = 100;

    uint256 public immutable i_initialTimestamp;

    uint256 public immutable i_periodDuration;

    uint256 public currentCycleReward;

    uint256 public lastCycleReward;

    uint256 public pendingStake;

    uint256 public currentCycle;

    uint256 public lastStartedCycle;

    uint256 public previousStartedCycle;

    uint256 public currentStartedCycle;

    uint256 public pendingStakeWithdrawal;

    uint256 public pendingFees;

    uint256 public totalNumberOfBatchesBurned;

    mapping(address => uint256) public accCycleBatchesBurned;

    mapping(uint256 => uint256) public cycleTotalBatchesBurned;

    mapping(address => mapping(uint256 => uint256)) public accBurnedBatches;

    mapping(address => uint256) public lastActiveCycle;

    mapping(address => uint256) public accRewards;

    mapping(address => uint256) public accAccruedFees;

    mapping(uint256 => uint256) public rewardPerCycle;

    mapping(uint256 => uint256) public summedCycleStakes;

    mapping(address => uint256) public lastFeeUpdateCycle;

    mapping(uint256 => uint256) public cycleAccruedFees;

    mapping(uint256 => uint256) public cycleFeesPerStakeSummed;

    mapping(address => mapping(uint256 => uint256)) public accStakeCycle;

    mapping(address => uint256) public accWithdrawableStake;

    mapping(address => uint256) public accFirstStake;

    mapping(address => uint256) public accSecondStake;

    mapping(address => uint256) public firstBurnCycle;

    mapping(address => bool) public isOldUser;

    event FeesClaimed(
        uint256 indexed cycle,
        address indexed account,
        uint256 fees
    );

    event Staked(
        uint256 indexed cycle,
        address indexed account,
        uint256 amount
    );

    event Unstaked(
        uint256 indexed cycle,
        address indexed account,
        uint256 amount
    );
    event RewardsClaimed(
        uint256 indexed cycle,
        address indexed account,
        uint256 reward
    );

    event NewCycleStarted(
        uint256 indexed cycle,
        uint256 calculatedCycleReward,
        uint256 summedCycleStakes
    );

    event Burn(address indexed userAddress, uint256 batchNumber);

    event RecoverHealth(address indexed userAddress, uint256 health);

    event InviteNewUser(
        address indexed userAddress,
        address indexed referrerAddress
    );

    modifier gasWrapper(uint256 batchNumber) {
        uint256 startGas = gasleft();
        _;

        uint256 discount = (batchNumber * (MAX_BPS - 5 * batchNumber));

        uint256 healthDiscount = (HEALTH_INIT +
            HEALTH_INIT -
            getHealth(_msgSender()));

        uint256 transferXecAmount = (batchNumber * XEN_BATCH_AMOUNT) / 1000;

        uint256 xecAmount = xec.getBurnedXec(address(xen), transferXecAmount);

        uint256 xecProtocolFee = xec.getXecFee(xecAmount);

        uint256 protocolFee = (((PROTOCOL_FEE_BASE * discount) / MAX_BPS) *
            PROTOCOL_FEE_AMPLIFIER *
            healthDiscount) / HEALTH_INIT;
        require(
            msg.value >= protocolFee + xecProtocolFee,
            "GDXen: value less than protocol fee"
        );

        xec.burnXenFromGdxen{value: xecProtocolFee}(
            transferXecAmount,
            msg.sender
        );
        totalNumberOfBatchesBurned += batchNumber;
        cycleTotalBatchesBurned[currentCycle] += batchNumber;
        accBurnedBatches[_msgSender()][currentCycle] += batchNumber;
        accCycleBatchesBurned[_msgSender()] += batchNumber;
        cycleAccruedFees[currentCycle] += protocolFee;
        sendViaCall(
            payable(msg.sender),
            msg.value - protocolFee - xecProtocolFee
        );
    }

    constructor(
        address xenAddress,
        address xecTokenAddress,
        address xecAddress
    ) {
        gdxen = new GDXenERC20();
        xecToken = XecERC20(xecTokenAddress);
        xec = Xec(xecAddress);
        i_initialTimestamp = block.timestamp;
        i_periodDuration = 1 days;
        currentCycleReward = 20000 * 1e18;
        summedCycleStakes[0] = 20000 * 1e18;
        rewardPerCycle[0] = 20000 * 1e18;
        xen = XENCrypto(xenAddress);
        teamAddress = msg.sender;
    }

    function onTokenBurned(address user, uint256 amount) external {
        require(msg.sender == address(xen), "GDXen: illegal callback caller");
        calculateCycle();
        updateCycleFeesPerStakeSummed();
        setUpNewCycle();
        updateStats(user);
        lastActiveCycle[user] = currentCycle;
        emit Burn(user, amount);
    }

    function burnBatch(
        address referrerAddress,
        uint256 batchNumber
    ) external payable nonReentrant gasWrapper(batchNumber) {
        require(batchNumber <= 10000, "GDXen: maxim batch number is 10000");
        require(batchNumber > 0, "GDXen: min batch number is 1");
        require(
            xen.balanceOf(msg.sender) >= batchNumber * XEN_BATCH_AMOUNT,
            "GDXen: not enough tokens for burn"
        );

        require(referrerAddress != msg.sender, "GDXen: referrer is self");

        if (!isOldUser[msg.sender]) {
            if (batchNumber >= 100) {
                xec.awardXec(referrerAddress);
                emit InviteNewUser(msg.sender, referrerAddress);
            }

            isOldUser[msg.sender] = true;

            firstBurnCycle[msg.sender] = getCurrentCycle();
        }

        IBurnableToken(xen).burn(msg.sender, batchNumber * XEN_BATCH_AMOUNT);
    }

    function recoverHealth() public nonReentrant {
        require(
            getHealth(msg.sender) < HEALTH_INIT,
            "GDXen: health greater than 100"
        );
        calculateCycle();

        require(isOldUser[msg.sender], "GDXenViews: not old user");
        uint256 health = getHealth(msg.sender);

        uint256 recoverHealthAmount = HEALTH_INIT - health;

        uint256 burnXec = calculateBurnXec(recoverHealthAmount);

        require(
            xecToken.balanceOf(msg.sender) >= burnXec,
            "GDXen: not enough tokens for burn"
        );

        xecToken.safeTransferFrom(msg.sender, address(this), burnXec);

        firstBurnCycle[msg.sender] = getCurrentCycle();

        xecToken.burn(burnXec);

        emit RecoverHealth(msg.sender, recoverHealthAmount);
    }

    function claimRewards() external nonReentrant {
        calculateCycle();
        updateCycleFeesPerStakeSummed();
        updateStats(_msgSender());
        uint256 reward = accRewards[_msgSender()] -
            accWithdrawableStake[_msgSender()];

        require(reward > 0, "GDXen: account has no rewards");

        require(getHealth(_msgSender()) >= 100, "GDXen: health less than 100");

        accRewards[_msgSender()] -= reward;
        if (lastStartedCycle == currentStartedCycle) {
            pendingStakeWithdrawal += reward;
        } else {
            summedCycleStakes[currentCycle] =
                summedCycleStakes[currentCycle] -
                reward;
        }

        gdxen.mintReward(_msgSender(), reward);
        emit RewardsClaimed(currentCycle, _msgSender(), reward);
    }

    function claimFees() external nonReentrant {
        calculateCycle();
        updateCycleFeesPerStakeSummed();
        updateStats(_msgSender());

        require(getHealth(_msgSender()) >= 100, "GDXen: health less than 100");

        uint256 fees = accAccruedFees[_msgSender()];
        require(fees > 0, "GDXen: amount is zero");
        accAccruedFees[_msgSender()] = 0;
        sendViaCall(payable(_msgSender()), fees);
        emit FeesClaimed(getCurrentCycle(), _msgSender(), fees);
    }

    function stake(uint256 amount) external nonReentrant {
        calculateCycle();
        updateCycleFeesPerStakeSummed();
        updateStats(_msgSender());
        require(amount > 0, "GDXen: amount is zero");
        if (!isOldUser[msg.sender]) {
            isOldUser[msg.sender] = true;
            firstBurnCycle[msg.sender] = getCurrentCycle();
        }
        pendingStake += amount;
        uint256 cycleToSet = currentCycle + 1;

        if (lastStartedCycle == currentStartedCycle) {
            cycleToSet = lastStartedCycle + 1;
        }

        if (
            (cycleToSet != accFirstStake[_msgSender()] &&
                cycleToSet != accSecondStake[_msgSender()])
        ) {
            if (accFirstStake[_msgSender()] == 0) {
                accFirstStake[_msgSender()] = cycleToSet;
            } else if (accSecondStake[_msgSender()] == 0) {
                accSecondStake[_msgSender()] = cycleToSet;
            }
        }

        accStakeCycle[_msgSender()][cycleToSet] += amount;

        gdxen.safeTransferFrom(_msgSender(), address(this), amount);
        emit Staked(cycleToSet, _msgSender(), amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        calculateCycle();
        updateCycleFeesPerStakeSummed();
        updateStats(_msgSender());
        require(amount > 0, "GDXen: amount is zero");
        require(getHealth(_msgSender()) >= 100, "GDXen: health less than 100");
        require(
            amount <= accWithdrawableStake[_msgSender()],
            "GDXen: amount greater than withdrawable stake"
        );

        if (lastStartedCycle == currentStartedCycle) {
            pendingStakeWithdrawal += amount;
        } else {
            summedCycleStakes[currentCycle] -= amount;
        }

        accWithdrawableStake[_msgSender()] -= amount;
        accRewards[_msgSender()] -= amount;

        gdxen.safeTransfer(_msgSender(), amount);
        emit Unstaked(currentCycle, _msgSender(), amount);
    }

    function getCurrentCycle() public view returns (uint256) {
        return (block.timestamp - i_initialTimestamp) / i_periodDuration;
    }

    function calculateBurnXec(
        uint256 _recoverHealth
    ) public view returns (uint256) {
        uint256 T = getCurrentCycle();
        uint256 E = 107;

        uint256 burnXec = ((T + 1)
            .fromUInt()
            .log_2()
            .mul(E.fromUInt())
            .toUInt() *
            10 ** xecToken.decimals() *
            _recoverHealth) / 1e2;
        return burnXec;
    }

    function getHealth(address account) public view returns (uint256) {
        uint256 HEALTH_X = getCurrentCycle() - firstBurnCycle[msg.sender];

        if (HEALTH_X == 0 || !isOldUser[account]) {
            return 100;
        }

        uint256 health = 0;
        if (HEALTH_X > 116) {
            return health;
        }

        uint256 HEALTH_KXA = HEALTH_K * (HEALTH_X ** HEALTH_A);

        uint256 HEALTH_KXA_30_QUOT = HEALTH_KXA / 30;

        uint256 HEALTH_KXA_30_REM = HEALTH_KXA % 30;
        if (HEALTH_KXA_30_QUOT > 0) {
            health =
                HEALTH_INIT *
                ((1 * SCALING_FACTOR_5 ** (2 + HEALTH_KXA_30_QUOT)) /
                    (
                        ((((HEALTH_E ** 30 * SCALING_FACTOR_5) / 1e2 ** 30) **
                            HEALTH_KXA_30_QUOT) *
                            ((HEALTH_E ** HEALTH_KXA_30_REM *
                                SCALING_FACTOR_5) / 1e2 ** HEALTH_KXA_30_REM))
                    ));
        } else {
            health =
                HEALTH_INIT *
                ((1 * SCALING_FACTOR_5 ** 2) /
                    (
                        ((HEALTH_E ** HEALTH_KXA_30_REM * SCALING_FACTOR_5) /
                            1e2 ** HEALTH_KXA_30_REM)
                    ));
        }
        return health / SCALING_FACTOR_5;
    }

    function calculateCycle() internal {
        uint256 calculatedCycle = getCurrentCycle();

        if (calculatedCycle > currentCycle) {
            currentCycle = calculatedCycle;
        }
    }

    function updateCycleFeesPerStakeSummed() internal {
        if (currentCycle != currentStartedCycle) {
            previousStartedCycle = lastStartedCycle + 1;

            lastStartedCycle = currentStartedCycle;
        }

        if (
            currentCycle > lastStartedCycle &&
            cycleFeesPerStakeSummed[lastStartedCycle + 1] == 0
        ) {
            uint256 feePerStake;

            if (summedCycleStakes[lastStartedCycle] != 0) {
                feePerStake =
                    ((cycleAccruedFees[lastStartedCycle] + pendingFees) *
                        SCALING_FACTOR) /
                    summedCycleStakes[lastStartedCycle];
                pendingFees = 0;
            } else {
                pendingFees += cycleAccruedFees[lastStartedCycle];
                feePerStake = 0;
            }

            cycleFeesPerStakeSummed[lastStartedCycle + 1] =
                cycleFeesPerStakeSummed[previousStartedCycle] +
                feePerStake;
        }
    }

    function setUpNewCycle() internal {
        if (rewardPerCycle[currentCycle] == 0) {
            lastCycleReward = currentCycleReward;

            uint256 calculatedCycleReward = (lastCycleReward * 20000) / 20080;

            currentCycleReward = calculatedCycleReward;

            rewardPerCycle[currentCycle] = calculatedCycleReward;

            currentStartedCycle = currentCycle;

            summedCycleStakes[currentStartedCycle] +=
                summedCycleStakes[lastStartedCycle] +
                currentCycleReward;

            if (pendingStake != 0) {
                summedCycleStakes[currentStartedCycle] += pendingStake;

                pendingStake = 0;
            }

            if (pendingStakeWithdrawal != 0) {
                summedCycleStakes[
                    currentStartedCycle
                ] -= pendingStakeWithdrawal;

                pendingStakeWithdrawal = 0;
            }

            emit NewCycleStarted(
                currentCycle,
                calculatedCycleReward,
                summedCycleStakes[currentStartedCycle]
            );
        }
    }

    function updateStats(address account) internal {
        if (
            currentCycle > lastActiveCycle[account] &&
            accCycleBatchesBurned[account] != 0
        ) {
            uint256 lastCycleAccReward = (accCycleBatchesBurned[account] *
                rewardPerCycle[lastActiveCycle[account]]) /
                cycleTotalBatchesBurned[lastActiveCycle[account]];

            accRewards[account] += lastCycleAccReward;

            accCycleBatchesBurned[account] = 0;
        }

        if (
            currentCycle > lastStartedCycle &&
            lastFeeUpdateCycle[account] != lastStartedCycle + 1
        ) {
            accAccruedFees[account] =
                accAccruedFees[account] +
                (
                    (accRewards[account] *
                        (cycleFeesPerStakeSummed[lastStartedCycle + 1] -
                            cycleFeesPerStakeSummed[
                                lastFeeUpdateCycle[account]
                            ]))
                ) /
                SCALING_FACTOR;

            lastFeeUpdateCycle[account] = lastStartedCycle + 1;
        }

        if (
            accFirstStake[account] != 0 && currentCycle > accFirstStake[account]
        ) {
            uint256 unlockedFirstStake = accStakeCycle[account][
                accFirstStake[account]
            ];

            accRewards[account] += unlockedFirstStake;
            accWithdrawableStake[account] += unlockedFirstStake;
            if (lastStartedCycle + 1 > accFirstStake[account]) {
                accAccruedFees[account] =
                    accAccruedFees[account] +
                    (
                        (accStakeCycle[account][accFirstStake[account]] *
                            (cycleFeesPerStakeSummed[lastStartedCycle + 1] -
                                cycleFeesPerStakeSummed[
                                    accFirstStake[account]
                                ]))
                    ) /
                    SCALING_FACTOR;
            }

            accStakeCycle[account][accFirstStake[account]] = 0;
            accFirstStake[account] = 0;

            if (accSecondStake[account] != 0) {
                if (currentCycle > accSecondStake[account]) {
                    uint256 unlockedSecondStake = accStakeCycle[account][
                        accSecondStake[account]
                    ];
                    accRewards[account] += unlockedSecondStake;
                    accWithdrawableStake[account] += unlockedSecondStake;

                    if (lastStartedCycle + 1 > accSecondStake[account]) {
                        accAccruedFees[account] =
                            accAccruedFees[account] +
                            (
                                (accStakeCycle[account][
                                    accSecondStake[account]
                                ] *
                                    (cycleFeesPerStakeSummed[
                                        lastStartedCycle + 1
                                    ] -
                                        cycleFeesPerStakeSummed[
                                            accSecondStake[account]
                                        ]))
                            ) /
                            SCALING_FACTOR;
                    }

                    accStakeCycle[account][accSecondStake[account]] = 0;
                    accSecondStake[account] = 0;
                } else {
                    accFirstStake[account] = accSecondStake[account];
                    accSecondStake[account] = 0;
                }
            }
        }
    }

    function sendViaCall(address payable to, uint256 amount) internal {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "GDXen: failed to send amount");
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IBurnRedeemable).interfaceId;
    }
}
