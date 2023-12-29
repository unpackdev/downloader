// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./IXENCrypto.sol";
import "./IXENFT.sol";
import "./MintInfo.sol";
import "./DBXENFT.sol";
import "./XENFTStorage.sol";

contract DBXeNFTFactory is ReentrancyGuard {
    using MintInfo for uint256;
    using SafeERC20 for IERC20;

    /**
     * XENFT Token contract.
     */
    IXENFT public immutable xenft;

    /**
     * DBXen Reward Token contract.
     */
    IERC20 public immutable dxn;

    /**
     * Xen Token contract.
     */
    IXENCrypto public immutable xenCrypto;

    /**
     * DBXeNFT Token contract.
     */
    DBXENFT public immutable dbxenft;

    /**
     * Address receiving 2.5% of protocol fees.
     */
    address public devAddress;

    /**
     * Index (0-based) of the current cycle.
     * 
     * Updated upon cycle setup that is triggered by contract interaction 
     * (account burn tokens, claims fees, claims rewards, stakes or unstakes).
     */
    uint256 public currentCycle;

    /**
     * Stores the index of the penultimate active cycle plus one.
     */
    uint256 public previousStartedCycle;

    /**
     * Helper variable to store the index of the last active cycle.
     */
    uint256 public currentStartedCycle;

    /**
     * Stores the index of the penultimate active cycle plus one.
     */
    uint256 public lastStartedCycle;

    /**
     * Power reward amount allocated for the current cycle.
     */
    uint256 public currentCycleReward;

    /**
     * Power reward amount allocated for the previous cycle.
     */
    uint256 public lastCycleReward;

    /**
     * Amount of seconds in a day.
     */
    uint256 public constant SECONDS_IN_DAY = 3_600 * 24;

    /**
     * Upper percentage limit that can be applied as penalty.
     */
    uint256 public constant MAX_PENALTY_PCT = 99;

    /**
     * Basis points representation of 100 percent.
     */
    uint256 public constant MAX_BPS = 10_000_000;

    /**
     * Helper constant used in calculating the fee for locking XENFT.
     */
    uint256 public constant BASE_XEN = 5_000_000_000;

    /**
     * Used to minimize division remainder when earned fees are calculated.
     */
    uint256 public constant SCALING_FACTOR = 1e40;

    /**
     * Length of a fee distribution cycle.
     * Initialized in constructor to 1 day.
     */
    uint256 public immutable i_periodDuration;

    /**
     * Contract creation timestamp.
     * Initialized in constructor.
     */
    uint256 public immutable i_initialTimestamp;

    /**
     * Pending power decrease applied at the start of the next active cycle.
     */
    uint256 public pendingStakeWithdrawal;

    /**
     * Pending fees added into the pool of the next active cycle.
     */
    uint256 public pendingFees;

    /**
     * Pending extra power from DXN staking added into the pool of the next active cycle.
     */
    uint256 public pendingPower;

    /**
     * The total amount of accrued fees per cycle.
     */
    mapping(uint256 => uint256) public cycleAccruedFees;

    /**
     * Total entry power(in est. Xen reward) in the given cycle.
     */
    mapping(uint256 => uint256) public totalEntryPowerPerCycle;

    /**
     * Updated when staking DXN - used in the calculation of
     * all the extra power that needs to be added to the total
     * power of DBXENFTs.
     */
    mapping(uint256 => uint256) public totalExtraEntryPower;

    /**
     * Entry power(in est. Xen reward) of the given DBXENFT.
     */
    mapping(uint256 => uint256) public dbxenftEntryPower;

    /**
     * Cycle in which the given DBXENFT was minted.
     */
    mapping(uint256 => uint256) public tokenEntryCycle;

    /**
     * Total entry power(in est. Xen reward) of all DBXENFTs
     * that staked during entry cycle.
     */
    mapping(uint256 => uint256) public dbxenftEntryPowerWithStake;

    /**
     * Power of DBXENFT counting towards the share of protocol fees.
     * Equal to base DBXENFT power + (base DBXENFT power * DXN staked) / 100;
     */ 
    mapping(uint256 => uint256) public dbxenftPower;

    /**
     * Base power of DBXENFT obtained from the share of
     * power reward of its entry cycle.
     */
    mapping(uint256 => uint256) public baseDBXeNFTPower;

    /**
     * Stores the sum of the total DBXENFT powers from all
     * the previous cycles + the current power reward of the given cycle.
     */
    mapping(uint256 => uint256) public summedCyclePowers;

     /**
     * Sum of previous total cycle accrued fees divided by total DBXENFT powers.
     */
    mapping(uint256 => uint256) public cycleFeesPerPowerSummed;

    /**
     * Total power rewards allocated per cycle.
     */
    mapping(uint256 => uint256) public rewardPerCycle;

    /**
     * Cycle in which a DBXENFT's staked DXN is locked and begins generating fees.
     */
    mapping(uint256 => uint256) public dbxenftFirstStake;

    /**
     * Same as dbxenftFirstStake, but stores the second stake separately 
     * in case DXN is staked for the DBXENFT in two consecutive active cycles.
     */
    mapping(uint256 => uint256) public dbxenftSecondStake;

    /**
     * DXN amount a DBXENFT has staked and is locked during given cycle.
     */
    mapping(uint256 => mapping(uint256 => uint256)) public dbxenftStakeCycle;

    /**
     * Pending staked DXN helper variable used for
     * updating DBXENFT with the corresponding power.
     */
    mapping(uint256 => uint256) public pendingDXN;

    /**
     * Amount of unclaimed fees of given DBXENFT since last stats update.
     */
    mapping(uint256 => uint256) public dbxenftAccruedFees;

    /**
     * Last cycle in which the total accrued fee amount of the DBXENFT was updated.
     */
    mapping(uint256 => uint256) public lastFeeUpdateCycle;

    /**
     * Last cycle in which the power of the DBXENFT was updated.
     */
    mapping(uint256 => uint256) public lastPowerUpdateCycle;

    /**
     * DXN amount a DBXENFT can currently withdraw.
     */
    mapping(uint256 => uint256) public dbxenftWithdrawableStake;

    /**
     * DBXENFT's locked XENFT.
     */
    mapping(uint256 => uint256) public dbxenftUnderlyingXENFT;

    /**
     * Contains the address of the storage contract holding the XENFT for given DBXENFT.
     */
    mapping(uint256 => XENFTStorage) public dbxenftUnderlyingStorage;

     /**
     * @dev Emitted when calling {mintDBXENFT} marking the new current `cycle`,
     * `calculatedCycleReward` and `summedCycleStakes`.
     */
    event NewCycleStarted(
        uint256 cycle,
        uint256 calculatedCycleReward,
        uint256 summedCyclePowers
    );

    /**
     * @dev Emitted when calling {mintDBXENFT} function by
     * `minter` in `cycle` which after paying `fee`amount native token
     * it's minted a DBXENFT with id `DBXENFTId` and
     * the XENFT with `XENFTID` gets locked.
     */
    event DBXeNFTMinted(
        uint256 indexed cycle,
        uint256 DBXENFTId,
        uint256 XENFTID,
        uint256 fee,
        address indexed minter
    );

    /**
     * @dev Emitted when `account` claims an amount of `fees` in native token
     * through {claimFees} in `cycle`.
     */
    event FeesClaimed(
        uint256 indexed cycle,
        uint256 indexed tokenId,
        uint256 fees,
        address indexed owner
    );

    /**
     * @dev Emitted when `owner` stakes `amount` DXN tokens through
     * {stake} on DBXENFT with `tokenId` in `cycle`.
     */
    event Staked(
        uint256 indexed cycle,
        uint256 indexed tokenId,
        uint256 amount,
        address indexed owner
    );

    /**
     * @dev Emitted when `owner` unstakes `amount` DXN tokens through
     * {unstake} on DBXENFT with `tokenId` in `cycle`.
     */
    event Unstaked(
        uint256 indexed cycle,
        uint256 indexed tokenId,
        uint256 amount,
        address indexed owner
    );

    /**
     * Emitted when `owner` of `dbxenftId` claims Xen
     * through {claimXen} from `xenftId`.
     */
    event XenRewardsClaimed(
        uint256 indexed cycle,
        uint256 dbxenftId,
        uint256 xenftId,
        address indexed owner
    );

    /**
     * @dev Used to check if the user owns a certain DBXENFT/XENFT.
     */
    modifier onlyNFTOwner(
        IERC721 tokenAddress,
        uint256 tokenId,
        address user
    ) {
        require(
            tokenAddress.ownerOf(tokenId) == user,
            "You do not own this NFT!"
        );
        _;
    }


    /**
     * @param xenftAddress XENFT contract address.
     * @param dbxAddress DXN contract address.
     * @param _xenCrypto Xen contract address.
     * @param _devAddress Dev address.
     */
    constructor(
        address dbxAddress,
        address xenftAddress,
        address _xenCrypto,
        address _devAddress
    ) {
        dxn = IERC20(dbxAddress);
        xenft = IXENFT(xenftAddress);
        xenCrypto = IXENCrypto(_xenCrypto);
        devAddress = _devAddress;
        i_periodDuration = 1 days;
        i_initialTimestamp = block.timestamp;
        dbxenft = new DBXENFT();
        currentCycleReward = 10000 * 1e18;
        summedCyclePowers[0] = 10000 * 1e18;
        rewardPerCycle[0] = 10000 * 1e18;
    }

    /**
     * @dev Locks an owned XENFT inside this contract and mints a DBXENFT.
     * Must pay a protocol fee based on the estimated Xen rewards
     * the XENFT yields at the time of locking. The estimated Xen
     * also determines the entry power that will provide the DBXENFT
     * a base power from the reward power pool split to all the
     * DBXENFTs created during the cycle.
     * If the XENFT is already redeemed, a DBXENFT that does not take
     * part in the auction of the cycle's reward power nor does it
     * start it is minted and is assigned the base power of 1.
     *
     * @param xenftId id of the XENFT to be locked.
     */
    function mintDBXENFT(
        uint256 xenftId
    ) external payable nonReentrant onlyNFTOwner(xenft, xenftId, msg.sender) {
        calculateCycle();
        updateCycleFeesPerStakeSummed();

        uint256 mintInfo = xenft.mintInfo(xenftId);

        bool redeemed = mintInfo.getRedeemed();

        uint256 fee;
        uint256 estimatedReward;
        if(redeemed) {
            fee = 1e15;
        } else {
            estimatedReward = _calculateUserMintReward(xenftId, mintInfo);

            fee = _calculateFee(
                estimatedReward,
                mintInfo.getMaturityTs(),
                mintInfo.getTerm()
            );
        }
        require(msg.value >= fee, "Payment less than fee");

        uint256 updatedFee = fee - calculateDevFee(fee);

        uint256 dbxenftId = dbxenft.mintDBXENFT(msg.sender);
        uint256 currentCycleMem = currentCycle;

        if(redeemed) {
            baseDBXeNFTPower[dbxenftId] = 1e18;
            dbxenftPower[dbxenftId] = 1e18;

            if(currentCycleMem != 0) {
                lastFeeUpdateCycle[dbxenftId] = lastStartedCycle + 1;
            }

            if(currentCycleMem == currentStartedCycle) {
                summedCyclePowers[currentCycleMem] += 1e18;
                cycleAccruedFees[currentCycleMem] = cycleAccruedFees[currentCycleMem] + updatedFee;

            } else {
                pendingPower += 1e18;
                pendingFees += updatedFee;
            }
        } else {
            setUpNewCycle();
            dbxenftEntryPower[dbxenftId] = estimatedReward;
            tokenEntryCycle[dbxenftId] = currentCycleMem;
            totalEntryPowerPerCycle[currentCycleMem] += estimatedReward;
            cycleAccruedFees[currentCycleMem] = cycleAccruedFees[currentCycleMem] + updatedFee;

            if(currentCycleMem != 0) {
                lastFeeUpdateCycle[dbxenftId] = lastStartedCycle + 1;
            }
        }
    
        dbxenftUnderlyingXENFT[dbxenftId] = xenftId;
       
        XENFTStorage dbxenftStorage = new XENFTStorage();
        dbxenftUnderlyingStorage[dbxenftId] = dbxenftStorage;

        xenft.transferFrom(msg.sender, address(dbxenftStorage), xenftId);
        sendViaCall(payable(msg.sender), msg.value - fee);
        sendViaCall(payable(devAddress), calculateDevFee(fee));

        emit DBXeNFTMinted(
            currentCycleMem,
            dbxenftId,
            xenftId,
            fee,
            msg.sender
        );
    }

    /**
     * @dev Calculates the protocol fee when staking 'dxnAmount' of DXN.
     *
     * @param dxnAmount amount of DXN to calculate protocol fee for.
     */
    function calcStakeFee(uint256 dxnAmount) internal pure returns(uint256 stakeFee){
        stakeFee = dxnAmount / 1000;
        require(stakeFee > 0, "DBXeNFT: stakeFee must be > 0");
    }

    /**
     * @dev Used for calculating extra entry power in order to find out
     * the extra total DBXENFT power of all the DBXENFTs that staked,
     * respectively when adding the extra power to an individual DBXENFT.
     *
     * @param power base/entry power to be multiplied upon.
     * @param dxnAmount amount of DXN to be multiplied with.
     */
    function calcExtraPower(uint256 power, uint256 dxnAmount) internal pure returns(uint256 calcPower){
        calcPower = Math.mulDiv(power, dxnAmount, 1e20);
    }

    /**
     * @dev Stake an amount of DXN for the given DBXENFT to give it extra power.
     * Must pay a protocol fee of 0.001 native coin for each DXN.
     * The corresponding DXN is locked until the end of the next cycle.
     *
     * @param amount amount of DXN to be staked.
     * @param tokenId DBXENFT id.
     */    
    function stake(uint256 amount, uint256 tokenId) external payable nonReentrant onlyNFTOwner(dbxenft, tokenId, msg.sender) {
        require(amount > 0, "DBXeNFT: amount is zero");
        calculateCycle();
        updateCycleFeesPerStakeSummed();
        updateDBXeNFT(tokenId);
        
        uint256 currentCycleMem = currentCycle;

        require(currentCycleMem == currentStartedCycle, "DBXeNFT: Only stake during active cycle");

        uint256 tokenEntryPowerMem = dbxenftEntryPower[tokenId];

        require(tokenEntryPowerMem != 0 || baseDBXeNFTPower[tokenId] != 0, "DBXeNFT does not exist");

        uint256 stakeFee = calcStakeFee(amount);
        require(msg.value >= stakeFee, "Value less than staking fee");
        uint256 devFee = calculateDevFee(stakeFee);
        uint256 updatedFee = stakeFee - devFee;

        cycleAccruedFees[currentCycleMem] += updatedFee;

        uint256 cycleToSet = currentCycleMem + 1;

        if (
            (cycleToSet != dbxenftFirstStake[tokenId] &&
                cycleToSet != dbxenftSecondStake[tokenId])
        ) {
            if (dbxenftFirstStake[tokenId] == 0) {
                dbxenftFirstStake[tokenId] = cycleToSet;
            } else if (dbxenftSecondStake[tokenId] == 0) {
                dbxenftSecondStake[tokenId] = cycleToSet;
            }
        }

        dbxenftStakeCycle[tokenId][cycleToSet] += amount;
        pendingDXN[tokenId] += amount;

        if(lastPowerUpdateCycle[tokenId] != currentCycle) {
            lastPowerUpdateCycle[tokenId] = currentCycle;
        }

        if(baseDBXeNFTPower[tokenId] == 0){
            uint256 extraPower = calcExtraPower(tokenEntryPowerMem, amount);
            dbxenftEntryPowerWithStake[currentCycleMem] += tokenEntryPowerMem;
            totalExtraEntryPower[currentCycleMem] += extraPower;
        } else {
            uint256 extraPower = calcExtraPower(baseDBXeNFTPower[tokenId], amount);
            pendingPower += extraPower;
        }

        dxn.safeTransferFrom(msg.sender, address(this), amount);
        sendViaCall(payable(msg.sender), msg.value - stakeFee);
        sendViaCall(payable(devAddress), devFee);
        emit Staked(
            currentCycleMem,
            tokenId,
            amount,
            msg.sender
        );
    }

    /**
     * @dev Unstake an amount of DXN for the given DBXENFT applying a power decrease
     * to the current cycle if it's an active one or beginning with the next active one.
     * Can only withdraw DXN that has completed the corresponding cycle lock-up.
     *
     * @param tokenId DBXENFT id.
     * @param amount amount of DXN to be unstaked.
     */ 
    function unstake(uint256 tokenId, uint256 amount) external nonReentrant onlyNFTOwner(dbxenft, tokenId, msg.sender) {
        require(amount > 0, "DBXeNFT: Amount is zero");
        calculateCycle();
        updateCycleFeesPerStakeSummed();
        updateDBXeNFT(tokenId);

        require(
            amount <= dbxenftWithdrawableStake[tokenId],
            "DBXeNFT: Amount greater than withdrawable stake"
        );

        uint256 powerDecrease = calcExtraPower(baseDBXeNFTPower[tokenId], amount);
        dbxenftWithdrawableStake[tokenId] -= amount;
        dbxenftPower[tokenId] -= powerDecrease;

        if (lastStartedCycle == currentStartedCycle) {
            pendingStakeWithdrawal += powerDecrease;
        } else {
            summedCyclePowers[currentCycle] -= powerDecrease;
        }

        dxn.safeTransfer(msg.sender, amount);
        emit Unstaked(
            currentCycle,
            tokenId,
            amount,
            msg.sender
        );
    }

    /**
     * @dev Transfers accrued fees of DBXENFT to its owner.
     *
     * @param tokenId DBXENFT id.
     */
    function claimFees(uint256 tokenId) external nonReentrant() onlyNFTOwner(dbxenft, tokenId, msg.sender){
        calculateCycle();
        updateCycleFeesPerStakeSummed();
        updateDBXeNFT(tokenId);

        uint256 fees = dbxenftAccruedFees[tokenId];
        require(fees > 0, "dbXENFT: amount is zero");
        dbxenftAccruedFees[tokenId] = 0;

        sendViaCall(payable(msg.sender), fees);
        emit FeesClaimed(
            currentCycle,
            tokenId,
            fees,
            msg.sender
        );
    }

    /**
     * @dev MaturityDays = Days since XENFT was minted - Days until XENFT can be claimed.
     *
     * @param term term attribute of XENFT
     * @param maturityTs maturity timestamp of XENFT
     */ 
    function calcMaturityDays(uint256 term, uint256 maturityTs) internal view returns(uint256 maturityDays) {
        uint256 daysTillClaim;
        uint256 daysSinceMinted;

        if(block.timestamp < maturityTs) {
            daysTillClaim = ((maturityTs - block.timestamp) / SECONDS_IN_DAY);
            daysSinceMinted = term - daysTillClaim;
        } else {
            daysTillClaim = 0;
            daysSinceMinted =
                ((term * SECONDS_IN_DAY + (block.timestamp - maturityTs))) /
                SECONDS_IN_DAY;
        }

        if (daysSinceMinted > daysTillClaim) {
            maturityDays = daysSinceMinted - daysTillClaim;
        }
    }
    
    /**
     * @dev Given a DBXENFT, claim the Xen rewards of the underlying XENFT
     * and direct them to its owner. Not permitted during entry cycle of DBXENFT.
     * In doing so, the base power of the DBXENFT will become 1(unless it's already smaller)
     * and the DBXENFT total power is updated according to the new base power
     * and the existent DXN stake.
     *
     * @param tokenId DBXENFT id.
     */ 
    function claimXen(uint256 tokenId) external nonReentrant onlyNFTOwner(dbxenft, tokenId, msg.sender) {
        calculateCycle();
        updateCycleFeesPerStakeSummed();
        updateDBXeNFT(tokenId);

        uint256 xenftId = dbxenftUnderlyingXENFT[tokenId];
        uint256 mintInfo = xenft.mintInfo(xenftId);

        require(!mintInfo.getRedeemed(), "XENFT: Already redeemed");

        require(currentCycle != tokenEntryCycle[tokenId], "Can not claim during entry cycle");

        uint256 DBXenftPow = dbxenftPower[tokenId];
        uint256 baseDBXeNFTPow = baseDBXeNFTPower[tokenId];
        if(baseDBXeNFTPow > 1e18) {
            uint256 newPow = Math.mulDiv(DBXenftPow, 1e18, baseDBXeNFTPow);
            dbxenftPower[tokenId] = newPow;
            DBXenftPow -= newPow;
            baseDBXeNFTPower[tokenId] = 1e18;

            if (lastStartedCycle == currentStartedCycle) {
            pendingStakeWithdrawal += DBXenftPow;
            } else {
                summedCyclePowers[currentCycle] -= DBXenftPow;
            }
        }

        XENFTStorage xenftStorage = dbxenftUnderlyingStorage[tokenId];
        xenftStorage.claimXenFromStorage(address(xenft), msg.sender, xenftId);
        emit XenRewardsClaimed(
            currentCycle,
            tokenId, 
            xenftId,
            msg.sender
        );
    }

    /**
     * Allows the current dev address to set a new one.
     * 
     * @param newDevAddress new dev address to be set.
     */
    function setDevAddress(address newDevAddress) public {
        require(msg.sender == devAddress, "Only dev can change address");

        devAddress = newDevAddress;
    }

    /**
     * Calculated according to the following formula:
     * ProtocolFee = MAX( (Xen*MAX( 1-0.0011389 * MAX(MaturityDays,0) , 0.5) )/ BASE_XEN), MinCost).
     * Xen = Estimated Xen to be claimed.
     * BaseXen = The floor amount of Xen for 1 Native coin = 1_000_000_000.
     * MinCost = Minimum amount of Native coin to be paid for minting = 0.001 native coin.
     *
     * @param userReward estimated Xen reward.
     * @param term term attribute of XENFT
     * @param maturityTs maturity timestamp of XENFT
     */
    function _calculateFee(
        uint256 userReward,
        uint256 maturityTs,
        uint256 term
    ) private view returns (uint256 burnFee) {
        uint256 maturityDays = calcMaturityDays(term, maturityTs);
        uint256 maxDays = maturityDays;
        uint256 daysReduction = 11389 * maxDays;
        uint256 maxSubtrahend = Math.min(daysReduction, 5_000_000);
        uint256 difference = MAX_BPS - maxSubtrahend;
        uint256 maxPctReduction = Math.max(difference, 5_000_000);
        uint256 xenMulReduction = Math.mulDiv(userReward, maxPctReduction, MAX_BPS);
        burnFee = Math.max(1e15, xenMulReduction / BASE_XEN);
    }

    /**
     * @dev calculates withdrawal penalty of Xen rewards depending on lateness.
     *
     * @param secsLate second late since maturity timestamp of XENFT.
     */
    function _penalty(uint256 secsLate) private pure returns (uint256) {
        // =MIN(2^(daysLate+3)/window-1,99)
        uint256 daysLate = secsLate / SECONDS_IN_DAY;
        if (daysLate > 7 - 1) return MAX_PENALTY_PCT;
        uint256 penalty = (uint256(1) << (daysLate + 3)) / 7 - 1;
        return penalty < MAX_PENALTY_PCT ? penalty : MAX_PENALTY_PCT;
    }

    /**
     * @dev calculates net Xen Reward (adjusted for Penalty).
     */
    function _calculateMintReward(
        uint256 cRank,
        uint256 term,
        uint256 maturityTs,
        uint256 amplifier,
        uint256 eeaRate
    ) private view returns (uint256) {
        uint256 penalty;
        if (block.timestamp > maturityTs) {
            uint256 secsLate = block.timestamp - maturityTs;
            penalty = _penalty(secsLate);
        }
        uint256 rankDiff = xenCrypto.globalRank() - cRank;
        uint256 rankDelta = rankDiff > 2 ? rankDiff : 2;
        uint256 EAA = (1000 + eeaRate);
        uint256 reward = xenCrypto.getGrossReward(
            rankDelta,
            amplifier,
            term,
            EAA
        );
        return (reward * (100 - penalty)) / 100;
    }

    /**
     * @dev calculates the estimated total Xen reward of the XENFT.
     *
     * @param tokenId XENFT id.
     * @param mintInfo contains packed info about XENFT.
     */
    function _calculateUserMintReward(
        uint256 tokenId,
        uint256 mintInfo
    ) internal view returns (uint256 userMintReward) {
        uint256 vmuCount = xenft.vmuCount(tokenId);
        (
            uint256 term,
            uint256 maturityTs,
            uint256 rank,
            uint256 amp,
            uint256 eea,
            ,
            ,
            ,

        ) = mintInfo.decodeMintInfo();
        uint256 mintReward = _calculateMintReward(
            rank,
            term,
            maturityTs,
            amp,
            eea
        );
        return mintReward * vmuCount * 1 ether;
    }

    /**
     * @dev calculates 2.5% of the paid protocol fee to be attributed to dev.
     *
     * @param inputValue protocol fee from which the dev fee is deducted.
     */
    function calculateDevFee(uint256 inputValue) public pure returns (uint256) {
        uint256 percentage = Math.mulDiv(inputValue, 25, 1000);

        return percentage;
    }

    /**
     * @dev Updates the global helper variables related to fee distribution.
     */
    function updateCycleFeesPerStakeSummed() internal {
        if (currentCycle != currentStartedCycle) {
            previousStartedCycle = lastStartedCycle + 1;
            lastStartedCycle = currentStartedCycle;
        }

        if (
            currentCycle > lastStartedCycle &&
            cycleFeesPerPowerSummed[lastStartedCycle + 1] == 0
        ) {
            uint256 feePerStake =
                    (cycleAccruedFees[lastStartedCycle] * SCALING_FACTOR) /
                    summedCyclePowers[lastStartedCycle];

            cycleFeesPerPowerSummed[lastStartedCycle + 1] =
                cycleFeesPerPowerSummed[previousStartedCycle] +
                feePerStake;
        }
    }

    /**
     * @dev Set up the new active cycle calculating the new
     * reward power pool with an 1% increase. 
     * Introduce any pending fees in the cycle's fee pool.
     * Calculate the new total power of DBXENFTs based on
     * the ones that have staked DXN.
     * Apply pending power decrease to the total DBXENFT power.
     */
    function setUpNewCycle() internal {
        uint256 currentCycleMemory = currentCycle;
        if (rewardPerCycle[currentCycleMemory] == 0) {
            lastCycleReward = currentCycleReward;
            uint256 calculatedCycleReward = lastCycleReward +
                (lastCycleReward / 100);

            currentCycleReward = calculatedCycleReward;
            rewardPerCycle[currentCycleMemory] = calculatedCycleReward;

            if(pendingFees != 0) {
                cycleAccruedFees[currentCycleMemory] += pendingFees;
                pendingFees = 0;
            }

            uint256 lastStartedCycleMemory = lastStartedCycle;
            if(dbxenftEntryPowerWithStake[lastStartedCycleMemory] != 0) {
                uint256 extraPower = Math.mulDiv(totalExtraEntryPower[lastStartedCycleMemory],lastCycleReward,
                    totalEntryPowerPerCycle[lastStartedCycleMemory]);
                summedCyclePowers[currentCycleMemory] += extraPower;
            }

            if(pendingPower != 0) {
                summedCyclePowers[currentCycleMemory] += pendingPower;
                pendingPower = 0;
            }

            currentStartedCycle = currentCycleMemory;

            summedCyclePowers[currentCycleMemory] += summedCyclePowers[lastStartedCycleMemory] + calculatedCycleReward;

            if (pendingStakeWithdrawal != 0) {
                summedCyclePowers[
                    currentCycleMemory
                ] -= pendingStakeWithdrawal;
                pendingStakeWithdrawal = 0;
            }

            emit NewCycleStarted(
                currentCycle,
                calculatedCycleReward,
                summedCyclePowers[currentCycleMemory]
            );
        }
    }

    /**
     * Update DBXENFT stats:
     * Assign their respective base power if not yet set.
     * Calculate the new DBXENFT power if any new stake was made.
     * Calculate the new fees it has accumulated since last update.
     * Mark any stake that passed the lock-up cycle as withdrawable.
     *
     * @param tokenId DBXENFT id.
     */
    function updateDBXeNFT(uint256 tokenId) internal {
        uint256 entryCycle = tokenEntryCycle[tokenId];
        if(baseDBXeNFTPower[tokenId] == 0 && currentCycle > entryCycle) {
            baseDBXeNFTPower[tokenId] = Math.mulDiv(dbxenftEntryPower[tokenId],
                rewardPerCycle[entryCycle], totalEntryPowerPerCycle[entryCycle]);
            dbxenftPower[tokenId] += baseDBXeNFTPower[tokenId];
        }

        uint256 lastStartedCycleMem = lastStartedCycle;
        uint256 stakedDXN = pendingDXN[tokenId];
        uint256 extraPower;
        uint256 dbxenftPowerBeforeExtraPower = dbxenftPower[tokenId];
        if(currentCycle > lastPowerUpdateCycle[tokenId] && stakedDXN != 0) {
            extraPower = calcExtraPower(baseDBXeNFTPower[tokenId], stakedDXN);
            pendingDXN[tokenId] = 0;
            dbxenftPower[tokenId] += extraPower;
        }

        if (
            currentCycle > lastStartedCycleMem &&
            lastFeeUpdateCycle[tokenId] != lastStartedCycleMem + 1
        ) {
            
            dbxenftAccruedFees[tokenId] += (dbxenftPowerBeforeExtraPower
                    * (cycleFeesPerPowerSummed[lastStartedCycleMem + 1] - cycleFeesPerPowerSummed[lastFeeUpdateCycle[tokenId]])) / SCALING_FACTOR;

            if(stakedDXN != 0) {
                uint256 stakeCycle;

                if(dbxenftSecondStake[tokenId] != 0) {
                    stakeCycle = dbxenftSecondStake[tokenId];
                } else {
                    stakeCycle = dbxenftFirstStake[tokenId];
                }
                 
                if(lastStartedCycleMem >= stakeCycle) {
                        dbxenftAccruedFees[tokenId] += (extraPower 
                        * (cycleFeesPerPowerSummed[lastStartedCycleMem + 1] - 
                        cycleFeesPerPowerSummed[stakeCycle])) / SCALING_FACTOR;
                }
            }
            
            lastFeeUpdateCycle[tokenId] = lastStartedCycleMem + 1;
        }

        uint256 tokenFirstStakeMem = dbxenftFirstStake[tokenId];
        if (
            tokenFirstStakeMem != 0 &&
            currentCycle > tokenFirstStakeMem
        ) {
            uint256 unlockedFirstStake = dbxenftStakeCycle[tokenId][tokenFirstStakeMem];

            dbxenftWithdrawableStake[tokenId] += unlockedFirstStake;

            dbxenftStakeCycle[tokenId][tokenFirstStakeMem] = 0;
            dbxenftFirstStake[tokenId] = 0;

            uint256 tokenSecondStakeMem = dbxenftSecondStake[tokenId];
            if (tokenSecondStakeMem != 0) {
                if (currentCycle > tokenSecondStakeMem) {
                    uint256 unlockedSecondStake = dbxenftStakeCycle[tokenId][tokenSecondStakeMem];

                    dbxenftWithdrawableStake[tokenId] += unlockedSecondStake;

                    dbxenftStakeCycle[tokenId][tokenSecondStakeMem] = 0;
                    dbxenftSecondStake[tokenId] = 0;
                } else {
                    dbxenftFirstStake[tokenId] = tokenSecondStakeMem;
                    dbxenftSecondStake[tokenId] = 0;
                }
            }
        }
    }

    /**
     * @dev Returns the index of the cycle at the current block time.
     */
    function getCurrentCycle() public view returns (uint256) {
        return (block.timestamp - i_initialTimestamp) / i_periodDuration;
    }

    /**
     * @dev Updates the index of the cycle.
     */
    function calculateCycle() internal {
        uint256 calculatedCycle = getCurrentCycle();

        if (calculatedCycle > currentCycle) {
            currentCycle = calculatedCycle;
        }
    }

    /**
     * Recommended method to use to send native coins.
     *
     * @param to receiving address.
     * @param amount in wei.
     */
    function sendViaCall(address payable to, uint256 amount) internal {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "DBXen: failed to send amount");
    }
}