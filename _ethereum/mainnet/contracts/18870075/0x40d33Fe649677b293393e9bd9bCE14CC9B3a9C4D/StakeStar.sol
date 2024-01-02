// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./ETHReceiver.sol";
import "./Utils.sol";

import "./IStakingPool.sol";
import "./IDepositContract.sol";
import "./IOracleNetwork.sol";

import "./SSVNetwork.sol";

import "./SStarETH.sol";
import "./StarETH.sol";

import "./StakeStarRegistry.sol";
import "./StakeStarTreasury.sol";

contract StakeStar is
    IStakingPool,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    // Data just to aggregate validator parameters, not used in any data structure
    struct ValidatorParams {
        bytes publicKey;
        bytes withdrawalCredentials;
        bytes signature;
        bytes32 depositDataRoot;
        uint64[] operatorIds;
        bytes sharesData;
    }

    // Balances (earned and staked) for specified timestamp
    // used to calculate rate for any time in future using linear extrapolation
    struct Snapshot {
        uint96 total_ETH; // in ether (decimals = 1e18)
        uint96 total_stakedStar; // in SStarETH (decimals = 1e18)
        uint64 timestamp; // in seconds (taken from block.timestamp)
    }

    event SetAddresses(
        address depositContract,
        address ssvNetwork,
        address ssvToken,
        address oracleNetwork,
        address sstarETH,
        address starETH,
        address stakeStarRegistry,
        address stakeStarTreasury,
        address withdrawalAddress,
        address feeRecipient,
        address mevRecipient
    );
    event SetUnstakeParameters(uint32 ustakePeriodLimit);
    event SetWithdrawalParameters(uint96 withdrawalMinLimit);
    event SetRateParameters(uint24 maxRateDeviation, bool rateDeviationCheck);
    event SetLocalPoolParameters(
        uint256 localPoolMaxSize,
        uint256 limit,
        uint256 frequencyLimit
    );
    event SetQueueParameters(uint32 loopLimit);
    event SetCommissionParameters(uint256 rateDiffThreshold);
    event SetValidatorWithdrawalThreshold(uint256 threshold);
    event CreateValidator(ValidatorParams params, uint256 ssvDepositAmount);
    event UpdateValidator(ValidatorParams params, uint256 ssvDepositAmount);
    event DestroyValidator(bytes publicKey);
    event RegisterValidator(ValidatorParams params);
    event UnregisterValidator(bytes publicKey);
    event Deposit(address indexed who, uint256 eth);
    event Stake(address indexed who, uint256 starETH, uint256 sstarETH);
    event Unstake(address indexed who, uint256 sstarETH, uint256 starETH);
    event Withdraw(address indexed who, uint256 starETH);
    event Claim(address indexed who, uint256 eth);
    event LocalPoolWithdraw(address indexed who, uint256 starETH);
    event CommitSnapshot(
        uint256 total_ETH,
        uint256 total_stakedStar,
        uint256 timestamp,
        uint256 rate
    );
    event RateDiff(uint256 realRate, uint256 calculatedRate);
    event RateEC(uint256 rateEC);
    event ExtractCommission(uint256 ssETH);
    event OptimizeCapitalEfficiency(uint256 ssETH, uint256 eth);

    // External contract addresses. Can be changed only using setAddresses method
    SStarETH public sstarETH; // StakedStarETH token
    StarETH public starETH; // StarETH token
    StakeStarRegistry public stakeStarRegistry; // Stake Star Registry with the list of operators/validators
    StakeStarTreasury public stakeStarTreasury; // Treasury used to collect commission

    // Special contracts used to receive profit
    ETHReceiver public withdrawalAddress; // Money got by Ethereum PoS protocol + when validator is destroyed
    ETHReceiver public feeRecipient; // Money got by user transaction fee when validator propose block
    ETHReceiver public mevRecipient; // Money got by MEV optimization on validator nodes

    // Other external contracts
    IDepositContract public depositContract; // Contract for validator creation by 32ETH
    SSVNetwork public ssvNetwork; // SSV Network
    IERC20 public ssvToken; // SSV Token used to pay for SSV Network usage
    IOracleNetwork public oracleNetwork; // Oracle aggregation contract to get current staked + earned PoS balance

    mapping(address => uint32) public stakeHistory;

    // Data structures for withdrawal operation
    // Linked list structure
    struct PendingWithdrawalData {
        address next;
        uint96 pendingAmount;
    }

    mapping(address => PendingWithdrawalData) public queue; // withdrawal queue organized as one-way list

    // -= slot =-
    uint96 public pendingWithdrawalSum; // total current pending withdrawal sum
    address public head; // pointer to the first item

    // -= slot =-
    address public tail; // pointer to the last item
    uint32 public loopLimit; // max queue items to process (other items are saved but can't be withdrawn)

    // Local Pool data for LocalWithdrawal operations
    mapping(address => uint32) public localPoolWithdrawalHistory; // block number for last LocalWithdrawal operation for user
    uint96 public localPoolSize; // current local pool size in ETH
    uint96 public localPoolMaxSize; // max pool size
    uint32 public localPoolWithdrawalPeriodLimit; // in blocks 12 seconds * 2^32 =~ 1600 years
    uint96 public localPoolWithdrawalLimit; // max amount allowed for LocalWithdrawal operation

    // Last two balance data used for rate approximation
    Snapshot[2] public snapshots;

    uint96 public validatorWithdrawalThreshold;

    uint32 public unstakePeriodLimit;

    uint96 public withdrawalMinLimit;

    // Rate control variables. Stored as numerator with 1e18 denominator
    // rate = TotalEth / StakedStar * 1e18
    uint24 public maxRateDeviation; // rate deviation control. In 1/100_000
    bool public rateDeviationCheck; // rate deviation check temporary disable. Can be used only once

    uint96 public rateForExtractCommision; // last rate used for extractCommission
    uint64 public rateDiffThreshold; // if (rate2 - rate1) < rateDiffThreshold do not extract any commission
    uint96 public rateCorrectionFactor; // rate correction to consider commission

    receive() external payable {}

    function initialize() public initializer {
        loopLimit = 25;

        maxRateDeviation = 500; // 0.5%
        rateDeviationCheck = true;

        rateForExtractCommision = 1 ether;
        rateCorrectionFactor = 1 ether;

        validatorWithdrawalThreshold = 16 ether;

        _setupRole(Utils.DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setAddresses(
        address depositContractAddress,
        address ssvNetworkAddress,
        address ssvTokenAddress,
        address oracleNetworkAddress,
        address sstarETHAddress,
        address starETHAddress,
        address stakeStarRegistryAddress,
        address stakeStarTreasuryAddress,
        address withdrawalCredentialsAddress,
        address feeRecipientAddress,
        address mevRecipientAddress
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        require(
            depositContractAddress != address(0),
            Utils.ZERO_ADDR_ERROR_MSG
        );
        require(ssvNetworkAddress != address(0), Utils.ZERO_ADDR_ERROR_MSG);
        require(ssvTokenAddress != address(0), Utils.ZERO_ADDR_ERROR_MSG);
        require(oracleNetworkAddress != address(0), Utils.ZERO_ADDR_ERROR_MSG);
        require(sstarETHAddress != address(0), Utils.ZERO_ADDR_ERROR_MSG);
        require(starETHAddress != address(0), Utils.ZERO_ADDR_ERROR_MSG);
        require(
            stakeStarRegistryAddress != address(0),
            Utils.ZERO_ADDR_ERROR_MSG
        );
        require(
            stakeStarTreasuryAddress != address(0),
            Utils.ZERO_ADDR_ERROR_MSG
        );
        require(
            withdrawalCredentialsAddress != address(0),
            Utils.ZERO_ADDR_ERROR_MSG
        );
        require(feeRecipientAddress != address(0), Utils.ZERO_ADDR_ERROR_MSG);
        require(mevRecipientAddress != address(0), Utils.ZERO_ADDR_ERROR_MSG);

        depositContract = IDepositContract(depositContractAddress);
        ssvNetwork = SSVNetwork(ssvNetworkAddress);
        ssvToken = IERC20(ssvTokenAddress);
        oracleNetwork = IOracleNetwork(oracleNetworkAddress);

        sstarETH = SStarETH(sstarETHAddress);
        starETH = StarETH(starETHAddress);
        stakeStarRegistry = StakeStarRegistry(stakeStarRegistryAddress);
        stakeStarTreasury = StakeStarTreasury(
            payable(stakeStarTreasuryAddress)
        );

        withdrawalAddress = ETHReceiver(payable(withdrawalCredentialsAddress));
        feeRecipient = ETHReceiver(payable(feeRecipientAddress));
        mevRecipient = ETHReceiver(payable(mevRecipientAddress));

        ssvNetwork.setFeeRecipientAddress(feeRecipientAddress);

        emit SetAddresses(
            depositContractAddress,
            ssvNetworkAddress,
            ssvTokenAddress,
            oracleNetworkAddress,
            sstarETHAddress,
            starETHAddress,
            stakeStarRegistryAddress,
            stakeStarTreasuryAddress,
            withdrawalCredentialsAddress,
            feeRecipientAddress,
            mevRecipientAddress
        );
    }

    function setUnstakeParameters(
        uint32 _unstakePeriodLimit
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        unstakePeriodLimit = _unstakePeriodLimit;

        emit SetUnstakeParameters(_unstakePeriodLimit);
    }

    function setWithdrawalParameters(
        uint96 _withdrawalMinLimit
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        withdrawalMinLimit = _withdrawalMinLimit;

        emit SetWithdrawalParameters(_withdrawalMinLimit);
    }

    function setRateParameters(
        uint24 _maxRateDeviation,
        bool _rateDeviationCheck
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        require(
            _maxRateDeviation <= Utils.BASE,
            "maxRateDeviation must be in [0, 100_000]"
        );

        maxRateDeviation = _maxRateDeviation;
        rateDeviationCheck = _rateDeviationCheck;

        emit SetRateParameters(_maxRateDeviation, rateDeviationCheck);
    }

    function setLocalPoolParameters(
        uint96 _localPoolMaxSize,
        uint96 _localPoolWithdrawalLimit,
        uint32 _localPoolWithdrawalPeriodLimit
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        localPoolMaxSize = _localPoolMaxSize;
        localPoolWithdrawalLimit = _localPoolWithdrawalLimit;
        localPoolWithdrawalPeriodLimit = _localPoolWithdrawalPeriodLimit;

        localPoolSize = localPoolSize < localPoolMaxSize
            ? localPoolSize
            : localPoolMaxSize;

        emit SetLocalPoolParameters(
            _localPoolMaxSize,
            _localPoolWithdrawalLimit,
            _localPoolWithdrawalPeriodLimit
        );
    }

    function setQueueParameters(
        uint32 _loopLimit
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        loopLimit = _loopLimit;

        emit SetQueueParameters(_loopLimit);
    }

    function setCommissionParameters(
        uint256 _rateDiffThreshold
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        rateDiffThreshold = uint64(_rateDiffThreshold);

        emit SetCommissionParameters(_rateDiffThreshold);
    }

    function setValidatorWithdrawalThreshold(
        uint256 threshold
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        validatorWithdrawalThreshold = uint96(threshold);

        emit SetValidatorWithdrawalThreshold(threshold);
    }

    // deposit Ether and receive Star tokens (1:1). Works exactly as ETH wrapping in WETH.deposit()
    function deposit() public payable {
        require(msg.value > 0, "msg.value = 0");

        starETH.mint(msg.sender, msg.value);

        // change some eth if we can
        uint256 eth = optimizeCapitalEfficiency(msg.value);
        // update localPoolSize
        topUpLocalPool(msg.value - eth);

        emit Deposit(msg.sender, msg.value);
    }

    // convert Star tokens to the StakedStar tokens by current SStar rate
    // (notice: this method doesn't change rate)
    function stake(
        uint256 starAmount
    ) public returns (uint256 stakedStarAmount) {
        require(starAmount > 0, "amount = 0");
        extractCommission();

        stakedStarAmount = ETHToStakedStar(starAmount);
        starETH.burn(msg.sender, starAmount);
        sstarETH.mint(msg.sender, stakedStarAmount);

        stakeHistory[msg.sender] = uint32(block.number);

        emit Stake(msg.sender, starAmount, stakedStarAmount);
    }

    // call deposit then stake in one call
    function depositAndStake() public payable {
        deposit();
        stake(msg.value);
    }

    // convert StakedStar tokens to Star tokens by current SStar rate
    function unstake(
        uint256 stakedStarAmount
    ) public returns (uint256 starAmount) {
        require(
            uint32(block.number) - stakeHistory[msg.sender] >
                unstakePeriodLimit,
            "unstakePeriodLimit"
        );
        require(
            uint32(block.number) - sstarETH.history(msg.sender) >
            unstakePeriodLimit,
            "unstakePeriodLimit after transfer"
        );

        extractCommission();

        starAmount = stakedStarToETH(stakedStarAmount);
        sstarETH.burn(msg.sender, stakedStarAmount);
        starETH.mint(msg.sender, starAmount);

        emit Unstake(msg.sender, stakedStarAmount, starAmount);
    }

    // unwrap Star tokens to ETH (1:1). Ether do not send immediately, but put in withdrawal queue
    // when balance of the contract will have enough free ETH you can `claim` it
    function withdraw(uint256 starAmount) public {
        require(starAmount >= withdrawalMinLimit, "withdrawalMinLimit");
        require(
            queue[msg.sender].pendingAmount == 0,
            "one withdrawal at a time only"
        );
        starETH.burn(msg.sender, starAmount);

        queue[msg.sender].pendingAmount = uint96(starAmount); // next = 0
        pendingWithdrawalSum += uint96(starAmount);
        if (head == address(0)) {
            head = msg.sender;
        } else {
            assert(tail != address(0)); // tail can be 0 only if head = 0
            queue[tail].next = msg.sender;
        }
        tail = msg.sender;

        emit Withdraw(msg.sender, starAmount);
    }

    // unstake then withdraw in one call
    function unstakeAndWithdraw(uint256 stakedStarAmount) public {
        uint256 starAmount = unstake(stakedStarAmount);
        withdraw(starAmount);
    }

    // Try to receive ETH already requested to withdraw
    function claim() public nonReentrant {
        _claim(msg.sender);
    }

    // Forcefully empty the withdrawal queue
    function forceClaim(uint8 n) public nonReentrant {
        require(n > 0, "n = 0");
        require(head != address(0), "queue is empty");

        while (n > 0 && head != address(0)) {
            _claim(head);
            n = n - 1;
        }
    }

    function _claim(address msgSender) internal {
        PendingWithdrawalData memory pendingData = queue[msgSender];
        uint96 eth = pendingData.pendingAmount;
        require(eth > 0, "no pending withdrawal");

        (uint32 index, address index_prev) = queueIndexAndPrevious(msgSender);
        require(index > 0, "lack of eth / queue length");

        pendingWithdrawalSum -= eth;
        if (head == msgSender) {
            head = pendingData.next;
        } else {
            queue[index_prev].next = pendingData.next;
        }
        if (tail == msgSender) {
            tail = index_prev;
        }

        delete queue[msgSender];

        // possible reentrancy, but as a last call before return it's safe
        Utils.safeTransferETH(msgSender, eth);

        emit Claim(msgSender, eth);
    }

    // for small SStar amount make withdraw without enqueue/claim operations
    // more gas efficient and fast, but can't be used frequently and with big amounts
    function localPoolWithdraw(uint256 starAmount) public {
        require(
            starAmount <= localPoolWithdrawalLimit,
            "localPoolWithdrawalLimit"
        );
        require(starAmount <= localPoolSize, "localPoolSize");
        require(
            uint32(block.number) - localPoolWithdrawalHistory[msg.sender] >
                localPoolWithdrawalPeriodLimit,
            "localPoolWithdrawalPeriodLimit"
        );
        require(
            uint32(block.number) - starETH.history(msg.sender) >
                localPoolWithdrawalPeriodLimit,
            "localPoolWithdrawalPeriodLimit after transfer"
        );

        starETH.burn(msg.sender, starAmount);
        localPoolSize -= uint96(starAmount);
        localPoolWithdrawalHistory[msg.sender] = uint32(block.number);

        Utils.safeTransferETH(msg.sender, starAmount);

        emit LocalPoolWithdraw(msg.sender, starAmount);
    }

    // unstake then localPoolWithdraw in one call
    function unstakeAndLocalPoolWithdraw(uint256 stakedStarAmount) public {
        uint256 starAmount = unstake(stakedStarAmount);
        localPoolWithdraw(starAmount);
    }

    // find position of msgSender address in the withdrawal queue starting from 1 (zero has special meaning)
    // also return previous to this position element to make available one-way list remove operation
    // if position in queue more then loopLimit or msgSender not found return (0, 0)
    function queueIndexAndPrevious(
        address msgSender
    ) internal view returns (uint32, address) {
        address current = head;
        address previous = address(0);

        uint32 loopCounter = 0;
        uint256 availableETH = address(this).balance - localPoolSize;
        uint256 withdrawalSum = 0;

        while (current != address(0) && loopCounter < loopLimit) {
            PendingWithdrawalData memory data = queue[current];
            withdrawalSum += data.pendingAmount;
            if (withdrawalSum > availableETH) break;
            if (msgSender == current) return (loopCounter + 1, previous);

            previous = current;
            current = data.next;
            loopCounter++;
        }

        return (0, address(0));
    }

    function queueIndex(address msgSender) public view returns (uint32) {
        (uint32 index, ) = queueIndexAndPrevious(msgSender);
        return index;
    }

    // Mint StakedStar tokens accorded to commissionRate
    function extractCommission() public {
        uint256 totalSupply_stakedStar = sstarETH.totalSupply();
        if (totalSupply_stakedStar == 0) return;
        uint256 totalSupply_ETH = stakedStarToETH(totalSupply_stakedStar);

        uint96 currentRate = uint96(rate());
        if (currentRate > rateForExtractCommision) {
            if (currentRate <= rateForExtractCommision + rateDiffThreshold)
                return;

            uint256 unrecordedRewards = MathUpgradeable.mulDiv(
                totalSupply_stakedStar,
                currentRate - rateForExtractCommision,
                1 ether
            );
            uint256 commission_ETH = stakeStarTreasury.getCommission(
                unrecordedRewards
            );
            // Mint as much StakedStar that new rate * minted = commission_ETH
            // newRate = totalSupplyETH/(totalSupplyStakedStar + commissionStakedStar)
            // newRate * commissionStakedStar =
            //   totalSupplyETH / (totalSupplyStakedStar + commissionStakedStar) *
            //   (commissionETH * totalSupplyStakedStar) / (totalSupplyETH - commissionETH)
            // = (after simplification) = commissionETH
            uint256 commission_stakedStar = MathUpgradeable.mulDiv(
                commission_ETH,
                totalSupply_stakedStar,
                totalSupply_ETH - commission_ETH
            );

            // Snapshots are not updated after minting commission_stakedStar,
            // so save the change and update rate to consider this commission
            rateCorrectionFactor = uint96(
                MathUpgradeable.mulDiv(
                    rateCorrectionFactor,
                    totalSupply_stakedStar,
                    totalSupply_stakedStar + commission_stakedStar
                )
            );
            sstarETH.mint(address(stakeStarTreasury), commission_stakedStar);

            emit ExtractCommission(commission_stakedStar);
        }

        rateForExtractCommision = uint96(rate());
        emit RateEC(rateForExtractCommision);
    }

    // this method convert some StakedStar tokens from stakeStarTreasury to ETH
    // Ether are taken from this StakeStar contract and transferred to the Treasury
    function optimizeCapitalEfficiency(uint256 eth) internal returns (uint256) {
        uint256 stakedStarBalance = sstarETH.balanceOf(
            address(stakeStarTreasury)
        );
        uint256 ethBalance = stakedStarToETH(stakedStarBalance);

        uint256 toTransfer = MathUpgradeable.min(eth, ethBalance);
        uint256 toBurn = ETHToStakedStar(toTransfer);

        if (toTransfer > 0 && toBurn > 0) {
            sstarETH.burn(address(stakeStarTreasury), toBurn);
            Utils.safeTransferETH(address(stakeStarTreasury), toTransfer);
            emit OptimizeCapitalEfficiency(toBurn, toTransfer);
        }

        return toTransfer;
    }

    // update localPoolSize according to added `value` ether
    function topUpLocalPool(uint256 value) internal {
        localPoolSize += uint96(value);
        if (localPoolSize > localPoolMaxSize) localPoolSize = localPoolMaxSize;
    }

    function reactivate(
        uint64[] memory operatorIds,
        uint256 amount,
        SSVNetwork.Cluster memory cluster
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        ssvNetwork.reactivate(operatorIds, amount, cluster);
    }

    // create new validator if ETH balance is enough
    // operator status will be changed from MISSING -> PENDING
    function createValidator(
        ValidatorParams calldata validatorParams,
        uint256 amount,
        SSVNetwork.Cluster calldata cluster
    ) public onlyRole(Utils.MANAGER_ROLE) {
        require(validatorCreationAvailability(), "cannot create validator");
        require(
            stakeStarRegistry.verifyOperators(validatorParams.operatorIds),
            "operators not allowListed"
        );
        require(
            Utils.compareBytes(
                validatorParams.withdrawalCredentials,
                Utils.addressToWithdrawalCredentials(address(withdrawalAddress))
            ),
            "invalid WC"
        );

        stakeStarRegistry.initiateActivatingValidator(
            validatorParams.publicKey
        );

        depositContract.deposit{value: 32 ether}(
            validatorParams.publicKey,
            validatorParams.withdrawalCredentials,
            validatorParams.signature,
            validatorParams.depositDataRoot
        );

        ssvToken.approve(address(ssvNetwork), amount);
        ssvNetwork.registerValidator(
            validatorParams.publicKey,
            validatorParams.operatorIds,
            validatorParams.sharesData,
            amount,
            cluster
        );

        emit CreateValidator(validatorParams, amount);
    }

    // destroy already destroyed operator, which must be in EXITING status
    function destroyValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        SSVNetwork.Cluster memory cluster
    ) public onlyRole(Utils.MANAGER_ROLE) {
        stakeStarRegistry.confirmExitingValidator(publicKey);
        ssvNetwork.removeValidator(publicKey, operatorIds, cluster);

        emit DestroyValidator(publicKey);
    }

    // register new validator
    function registerValidator(
        ValidatorParams calldata validatorParams,
        uint256 amount,
        SSVNetwork.Cluster calldata cluster
    ) public onlyRole(Utils.MANAGER_ROLE) {
        ssvToken.approve(address(ssvNetwork), amount);
        ssvNetwork.registerValidator(
            validatorParams.publicKey,
            validatorParams.operatorIds,
            validatorParams.sharesData,
            amount,
            cluster
        );

        emit RegisterValidator(validatorParams);
    }

    function unregisterValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        SSVNetwork.Cluster memory cluster
    ) public onlyRole(Utils.MANAGER_ROLE) {
        ssvNetwork.removeValidator(publicKey, operatorIds, cluster);

        emit UnregisterValidator(publicKey);
    }

    // transfer earned Ether to this contract
    function harvest() public {
        if (address(feeRecipient).balance > 0) feeRecipient.pull();
        if (address(mevRecipient).balance > 0) mevRecipient.pull();
    }

    // update rate according to the new total balance
    function commitSnapshot() public {
        // Warning: totalBalance includes withdrawalAddress balance!
        (uint256 totalBalance, uint256 timestamp) = oracleNetwork
            .latestTotalBalance();

        require(
            timestamp >= snapshots[1].timestamp + Utils.EPOCH_DURATION,
            "timestamps too close"
        );

        harvest();

        uint256 total_ETH = totalBalance +
            address(this).balance -
            uint256(pendingWithdrawalSum) -
            starETH.totalSupply();
        uint256 total_stakedStar = sstarETH.totalSupply();

        require(total_ETH > 0 && total_stakedStar > 0, "totals must be > 0");

        uint256 currentRate = rate();
        uint256 newRate = MathUpgradeable.mulDiv(
            total_ETH,
            1 ether,
            total_stakedStar
        );

        if (rateDeviationCheck) {
            uint256 lastRate = snapshots[1].timestamp > 0
                ? MathUpgradeable.mulDiv(
                    snapshots[1].total_ETH,
                    1 ether,
                    snapshots[1].total_stakedStar
                )
                : 1 ether;

            uint256 maxRate = MathUpgradeable.max(newRate, lastRate);
            uint256 minRate = MathUpgradeable.min(newRate, lastRate);

            require(
                MathUpgradeable.mulDiv(
                    maxRate - minRate,
                    Utils.BASE,
                    lastRate
                ) <= uint256(maxRateDeviation),
                "rate deviation too big"
            );
        } else {
            rateDeviationCheck = true;
        }

        snapshots[0] = snapshots[1];
        snapshots[1] = Snapshot(
            uint96(total_ETH),
            uint96(total_stakedStar),
            uint64(timestamp)
        );

        rateCorrectionFactor = 1 ether;

        if (address(withdrawalAddress).balance > 0) withdrawalAddress.pull();

        emit CommitSnapshot(total_ETH, total_stakedStar, timestamp, newRate);
        emit RateDiff(newRate, currentRate);
    }

    function validatorCreationAvailability() public view returns (bool) {
        return
            address(this).balance >=
            (uint256(32 ether) + pendingWithdrawalSum + localPoolSize);
    }

    function validatorDestructionAvailability() public view returns (bool) {
        uint256 activeValidators = stakeStarRegistry.countValidatorPublicKeys(
            StakeStarRegistry.ValidatorStatus.ACTIVE
        );
        if (activeValidators == 0) return false;

        uint256 freeETH = address(this).balance - localPoolSize;
        uint256 exitedETH = address(withdrawalAddress).balance;
        uint256 fees = address(feeRecipient).balance +
            address(mevRecipient).balance;
        uint256 exitingValidators = stakeStarRegistry.countValidatorPublicKeys(
            StakeStarRegistry.ValidatorStatus.EXITING
        );
        uint256 exitingETH = exitingValidators * uint256(32 ether);

        return
            pendingWithdrawalSum >=
            validatorWithdrawalThreshold +
                freeETH +
                exitedETH +
                fees +
                exitingETH;
    }

    function validatorToDestroy() public view returns (bytes memory) {
        require(validatorDestructionAvailability(), "destroy not available");

        return
            stakeStarRegistry.getValidatorPublicKeys(
                StakeStarRegistry.ValidatorStatus.ACTIVE
            )[0];
    }

    function rate(uint256 timestamp) public view returns (uint256 _rate) {
        require(timestamp >= snapshots[1].timestamp, "timestamp from the past");

        if (snapshots[0].timestamp == 0 && snapshots[1].timestamp == 0) {
            return 1 ether;
        }

        uint256 rate1 = MathUpgradeable.mulDiv(
            snapshots[1].total_ETH,
            1 ether,
            snapshots[1].total_stakedStar
        );

        if (snapshots[0].timestamp == 0) {
            _rate = rate1;
        } else {
            uint256 rate0 = MathUpgradeable.mulDiv(
                snapshots[0].total_ETH,
                1 ether,
                snapshots[0].total_stakedStar
            );

            // distance & snapshot distance
            uint256 d = timestamp - snapshots[1].timestamp;
            uint256 sd = snapshots[1].timestamp - snapshots[0].timestamp;

            _rate = rate1 > rate0
                ? rate1 + MathUpgradeable.mulDiv(rate1 - rate0, d, sd)
                : rate1 - MathUpgradeable.mulDiv(rate0 - rate1, d, sd);
        }

        _rate = MathUpgradeable.mulDiv(_rate, rateCorrectionFactor, 1 ether);
    }

    function rate() public view returns (uint256) {
        return rate(block.timestamp);
    }

    function stakedStarToETH(uint256 ssETH) public view returns (uint256) {
        return MathUpgradeable.mulDiv(ssETH, rate(), 1 ether);
    }

    function ETHToStakedStar(uint256 eth) public view returns (uint256) {
        return MathUpgradeable.mulDiv(eth, 1 ether, rate());
    }
}
