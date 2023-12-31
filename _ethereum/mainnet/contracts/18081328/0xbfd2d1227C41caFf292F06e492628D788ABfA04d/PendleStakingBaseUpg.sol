// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;
pragma abicoder v2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./IPendleMarketDepositHelper.sol";
import "./IPVotingEscrowMainchain.sol";
import "./IPFeeDistributorV2.sol";
import "./IPVoteController.sol";
import "./IPendleRouter.sol";
import "./IMasterPenpie.sol";
import "./IETHZapper.sol";

import "./ISmartPendleConvert.sol";
import "./IBaseRewardPool.sol";
import "./IMintableERC20.sol";
import "./IWETH.sol";
import "./IPendleStaking.sol";
import "./IPendleMarket.sol";
import "./IPenpieBribeManager.sol";

import "./IConvertor.sol";
import "./ERC20FactoryLib.sol";
import "./WeekMath.sol";

/// @title PendleStakingBaseUpg
/// @notice PendleStaking is the main contract that holds vePendle position on behalf on user to get boosted yield and vote.
///         PendleStaking is the main contract interacting with Pendle Finance side
/// @author Magpie Team

abstract contract PendleStakingBaseUpg is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IPendleStaking
{
    using SafeERC20 for IERC20;

    /* ============ Structs ============ */

    struct Pool {
        address market;
        address rewarder;
        address helper;
        address receiptToken;
        uint256 lastHarvestTime;
        bool isActive;
    }

    struct Fees {
        uint256 value; // allocation denominated by DENOMINATOR
        address to;
        bool isMPENDLE;
        bool isAddress;
        bool isActive;
    }

    /* ============ State Variables ============ */
    // Addresses
    address public PENDLE;
    address public WETH;
    address public mPendleConvertor;
    address public mPendleOFT;
    address public marketDepositHelper;
    address public masterPenpie;
    address public voteManager;
    uint256 public harvestTimeGap;

    address internal constant NATIVE = address(0);

    //Pendle Finance addresses
    IPVotingEscrowMainchain public vePendle;
    IPFeeDistributorV2 public distributorETH;
    IPVoteController public pendleVote;
    IPendleRouter public pendleRouter;

    mapping(address => Pool) public pools;
    address[] public poolTokenList;

    // Lp Fees
    uint256 constant DENOMINATOR = 10000;
    uint256 public totalPendleFee; // total fee percentage for PENDLE reward
    Fees[] public pendleFeeInfos; // infor of fee and destination
    uint256 public autoBribeFee; // fee for any reward other than PENDLE

    // vePendle Fees
    uint256 public vePendleHarvestCallerFee;
    uint256 public protocolFee; // fee charged by penpie team for operation
    address public feeCollector; // penpie team fee destination
    address public bribeManagerEOA; // An EOA address to later user vePendle harvested reward as bribe

    /* ===== 1st upgrade ===== */
    address public bribeManager;
    address public smartPendleConvert;
    address public ETHZapper;
    uint256 public harvestCallerPendleFee;

    uint256[46] private __gap;

    /* ============ Events ============ */

    // Admin
    event PoolAdded(address _market, address _rewarder, address _receiptToken);
    event PoolRemoved(uint256 _pid, address _lpToken);

    event SetMPendleConvertor(
        address _oldmPendleConvertor,
        address _newmPendleConvertor
    );

    // Fee
    event AddPendleFee(
        address _to,
        uint256 _value,
        bool _isMPENDLE,
        bool _isAddress
    );
    event SetPendleFee(address _to, uint256 _value);
    event RemovePendleFee(
        uint256 value,
        address to,
        bool _isMPENDLE,
        bool _isAddress
    );
    event RewardPaidTo(
        address _market,
        address _to,
        address _rewardToken,
        uint256 _feeAmount
    );
    event VePendleHarvested(
        uint256 _total,
        address[] _pool,
        uint256[] _totalAmounts,
        uint256 _protocolFee,
        uint256 _callerFee,
        uint256 _rest
    );

    event NewMarketDeposit(
        address indexed _user,
        address indexed _market,
        uint256 _lpAmount,
        address indexed _receptToken,
        uint256 _receptAmount
    );
    event NewMarketWithdraw(
        address indexed _user,
        address indexed _market,
        uint256 _lpAmount,
        address indexed _receptToken,
        uint256 _receptAmount
    );
    event PendleLocked(
        uint256 _amount,
        uint256 _lockDays,
        uint256 _vePendleAccumulated
    );

    // Vote Manager
    event VoteSet(
        address _voter,
        uint256 _vePendleHarvestCallerFee,
        uint256 _harvestCallerPendleFee,
        uint256 _voteProtocolFee,
        address _voteFeeCollector
    );
    event VoteManagerUpdated(address _oldVoteManager, address _voteManager);
    event BribeManagerUpdated(address _oldBribeManager, address _bribeManager);
    event BribeManagerEOAUpdated(address _oldBribeManagerEOA, address _bribeManagerEOA);

    event SmartPendleConvertUpdated(
        address _OldSmartPendleConvert,
        address _smartPendleConvert
    );

    /* ============ Errors ============ */

    error OnlyPoolHelper();
    error OnlyActivePool();
    error PoolOccupied();
    error InvalidFee();
    error LengthMismatch();
    error OnlyVoteManager();
    error TimeGapTooMuch();
    error NoVePendleReward();
    error InvalidFeeDestination();
    error ZeroNotAllowed();
    error InvalidAddress();

    /* ============ Constructor ============ */

    function __PendleStakingBaseUpg_init(
        address _pendle,
        address _WETH,
        address _vePendle,
        address _distributorETH,
        address _pendleRouter,
        address _masterPenpie
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        PENDLE = _pendle;
        WETH = _WETH;
        masterPenpie = _masterPenpie;
        vePendle = IPVotingEscrowMainchain(_vePendle);
        distributorETH = IPFeeDistributorV2(_distributorETH);
        pendleRouter = IPendleRouter(_pendleRouter);
    }

    /* ============ Modifiers ============ */

    modifier _onlyPoolHelper(address _market) {
        Pool storage poolInfo = pools[_market];

        if (msg.sender != poolInfo.helper) revert OnlyPoolHelper();
        _;
    }

    modifier _onlyActivePool(address _market) {
        Pool storage poolInfo = pools[_market];

        if (!poolInfo.isActive) revert OnlyActivePool();
        _;
    }

    modifier _onlyActivePoolHelper(address _market) {
        Pool storage poolInfo = pools[_market];

        if (msg.sender != poolInfo.helper) revert OnlyPoolHelper();
        if (!poolInfo.isActive) revert OnlyActivePool();
        _;
    }

    /* ============ External Getters ============ */

    receive() external payable {
        // Deposit ETH to WETH
        IWETH(WETH).deposit{ value: msg.value }();
    }

    /// @notice get the number of vePendle of this contract
    function accumulatedVePendle() public view returns (uint256) {
        return IPVotingEscrowMainchain(vePendle).balanceOf(address(this));
    }

    function getPoolLength() external view returns (uint256) {
        return poolTokenList.length;
    }

    /* ============ External Functions ============ */

    function depositMarket(
        address _market,
        address _for,
        address _from,
        uint256 _amount
    ) external override nonReentrant whenNotPaused _onlyPoolHelper(_market) {
        Pool storage poolInfo = pools[_market];
        _harvestMarketRewards(poolInfo.market, false);

        IERC20(poolInfo.market).safeTransferFrom(_from, address(this), _amount);

        // mint the receipt to the user driectly
        IMintableERC20(poolInfo.receiptToken).mint(_for, _amount);

        emit NewMarketDeposit(
            _for,
            _market,
            _amount,
            poolInfo.receiptToken,
            _amount
        );
    }

    function withdrawMarket(
        address _market,
        address _for,
        uint256 _amount
    ) external override nonReentrant whenNotPaused _onlyPoolHelper(_market) {
        Pool storage poolInfo = pools[_market];
        _harvestMarketRewards(poolInfo.market, false);

        IMintableERC20(poolInfo.receiptToken).burn(_for, _amount);

        IERC20(poolInfo.market).safeTransfer(_for, _amount);
        // emit New withdraw
        emit NewMarketWithdraw(
            _for,
            _market,
            _amount,
            poolInfo.receiptToken,
            _amount
        );
    }

    /// @notice harvest a Rewards from Pendle Liquidity Pool
    /// @param _market Pendle Pool lp as helper identifier
    function harvestMarketReward(
        address _market,
        address _caller,
        uint256 _minEthRecive
    ) external whenNotPaused _onlyActivePool(_market) {
        address[] memory _markets = new address[](1);
        _markets[0] = _market; 
       _harvestBatchMarketRewards(_markets, _caller, _minEthRecive); // triggers harvest from Pendle finance
    }

    function batchHarvestMarketRewards(
        address[] calldata _markets,
        uint256 minEthToRecieve
    ) external whenNotPaused {
        _harvestBatchMarketRewards(_markets, msg.sender, minEthToRecieve );
    }

    /* ============ Admin Functions ============ */

    function registerPool(
        address _market,
        uint256 _allocPoints,
        string memory name,
        string memory symbol
    ) external onlyOwner {
        if (pools[_market].isActive != false) {
            revert PoolOccupied();
        }

        IERC20 newToken = IERC20(
            ERC20FactoryLib.createReceipt(_market, masterPenpie, name, symbol)
        );

        address rewarder = IMasterPenpie(masterPenpie).createRewarder(
            address(newToken),
            address(PENDLE)
        );

        IPendleMarketDepositHelper(marketDepositHelper).setPoolInfo(
            _market,
            rewarder,
            true
        );

        IMasterPenpie(masterPenpie).add(
            _allocPoints,
            address(_market),
            address(newToken),
            address(rewarder)
        );

        pools[_market] = Pool({
            isActive: true,
            market: _market,
            receiptToken: address(newToken),
            rewarder: address(rewarder),
            helper: marketDepositHelper,
            lastHarvestTime: block.timestamp
        });
        poolTokenList.push(_market);

        emit PoolAdded(_market, address(rewarder), address(newToken));
    }

    /// @notice set the mPendleConvertor address
    /// @param _mPendleConvertor the mPendleConvertor address
    function setMPendleConvertor(address _mPendleConvertor) external onlyOwner {
        address oldMPendleConvertor = mPendleConvertor;
        mPendleConvertor = _mPendleConvertor;

        emit SetMPendleConvertor(oldMPendleConvertor, mPendleConvertor);
    }

    function setVoteManager(address _voteManager) external onlyOwner {
        address oldVoteManager = voteManager;
        voteManager = _voteManager;

        emit VoteManagerUpdated(oldVoteManager, voteManager);
    }

    function setBribeManager(address _bribeManager, address _bribeManagerEOA) external onlyOwner {
        address oldBribeManager = bribeManager;
        bribeManager = _bribeManager;

        address oldBribeManagerEOA = bribeManagerEOA;
        bribeManagerEOA = _bribeManagerEOA;

        emit BribeManagerUpdated(oldBribeManager, bribeManager);
        emit BribeManagerEOAUpdated(oldBribeManagerEOA, bribeManagerEOA);
    }

    function setmasterPenpie(address _masterPenpie) external onlyOwner {
        masterPenpie = _masterPenpie;
    }

    function setMPendleOFT(address _setMPendleOFT) external onlyOwner {
        mPendleOFT = _setMPendleOFT;
    }

    function setETHZapper(address _ETHZapper) external onlyOwner {
        ETHZapper = _ETHZapper;
    }

    /**
     * @notice pause Pendle staking, restricting certain operations
     */
    function pause() external nonReentrant onlyOwner {
        _pause();
    }

    /**
     * @notice unpause Pendle staking, enabling certain operations
     */
    function unpause() external nonReentrant onlyOwner {
        _unpause();
    }

    /// @notice This function adds a fee to the magpie protocol
    /// @param _value the initial value for that fee
    /// @param _to the address or contract that receives the fee
    /// @param _isMPENDLE true if the fee is sent as MPENDLE, otherwise it will be PENDLE
    /// @param _isAddress true if the receiver is an address, otherwise it's a BaseRewarder
    function addPendleFee(
        uint256 _value,
        address _to,
        bool _isMPENDLE,
        bool _isAddress
    ) external onlyOwner {
        if (_value >= DENOMINATOR) revert InvalidFee();

        pendleFeeInfos.push(
            Fees({
                value: _value,
                to: _to,
                isMPENDLE: _isMPENDLE,
                isAddress: _isAddress,
                isActive: true
            })
        );
        totalPendleFee += _value;

        emit AddPendleFee(_to, _value, _isMPENDLE, _isAddress);
    }

    /**
     * @dev Set the Pendle fee.
     * @param _index The index of the fee.
     * @param _value The value of the fee.
     * @param _to The address to which the fee is sent.
     * @param _isMPENDLE Boolean indicating if the fee is in MPENDLE.
     * @param _isAddress Boolean indicating if the fee is in an external token.
     * @param _isActive Boolean indicating if the fee is active.
     */
    function setPendleFee(
        uint256 _index,
        uint256 _value,
        address _to,
        bool _isMPENDLE,
        bool _isAddress,
        bool _isActive
    ) external onlyOwner {
        if (_value >= DENOMINATOR) revert InvalidFee();

        Fees storage fee = pendleFeeInfos[_index];
        fee.to = _to;
        fee.isMPENDLE = _isMPENDLE;
        fee.isAddress = _isAddress;
        fee.isActive = _isActive;

        totalPendleFee = totalPendleFee - fee.value + _value;
        fee.value = _value;

        emit SetPendleFee(fee.to, _value);
    }

    /// @notice remove some fee
    /// @param _index the index of the fee in the fee list
    function removePendleFee(uint256 _index) external onlyOwner {
        Fees memory feeToRemove = pendleFeeInfos[_index];

        for (uint i = _index; i < pendleFeeInfos.length - 1; i++) {
            pendleFeeInfos[i] = pendleFeeInfos[i + 1];
        }
        pendleFeeInfos.pop();
        totalPendleFee -= feeToRemove.value;

        emit RemovePendleFee(
            feeToRemove.value,
            feeToRemove.to,
            feeToRemove.isMPENDLE,
            feeToRemove.isAddress
        );
    }

    function setVote(
        address _pendleVote,
        uint256 _vePendleHarvestCallerFee,
        uint256 _harvestCallerPendleFee,
        uint256 _protocolFee,
        address _feeCollector
    ) external onlyOwner {
        if ((_vePendleHarvestCallerFee + _protocolFee) > DENOMINATOR)
            revert InvalidFee();

        if ((_harvestCallerPendleFee + _protocolFee) > DENOMINATOR)
            revert InvalidFee();

        pendleVote = IPVoteController(_pendleVote);
        vePendleHarvestCallerFee = _vePendleHarvestCallerFee;
        harvestCallerPendleFee = _harvestCallerPendleFee;
        protocolFee = _protocolFee;
        feeCollector = _feeCollector;

        emit VoteSet(
            _pendleVote,
            vePendleHarvestCallerFee,
            harvestCallerPendleFee,
            protocolFee,
            feeCollector
        );
    }

    function setMarketDepositHelper(address _helper) external onlyOwner {
        marketDepositHelper = _helper;
    }

    function setHarvestTimeGap(uint256 _period) external onlyOwner {
        if (_period > 4 hours) revert TimeGapTooMuch();

        harvestTimeGap = _period;
    }

    function setSmartConvert(address _smartPendleConvert) external onlyOwner {
        if (_smartPendleConvert == address(0)) revert InvalidAddress();
        address oldSmartPendleConvert = smartPendleConvert;
        smartPendleConvert = _smartPendleConvert;

        emit SmartPendleConvertUpdated(
            oldSmartPendleConvert,
            smartPendleConvert
        );
    }

    function setAutoBribeFee(
        uint256 _autoBribeFee
    ) external onlyOwner {
        if (_autoBribeFee > DENOMINATOR) revert InvalidFee();
        autoBribeFee = _autoBribeFee;
    }

    function updateMarketRewards(
        address _market,
        uint256[] memory amounts
    ) external onlyOwner {
        Pool storage poolInfo = pools[_market];
        address[] memory bonusTokens = IPendleMarket(_market).getRewardTokens();
        require(bonusTokens.length == amounts.length, "...");
        for (uint256 i; i < bonusTokens.length; i++) {
            if (bonusTokens[i] == NATIVE) bonusTokens[i] = address(WETH);
            uint256 leftAmounts = amounts[i];
            _sendRewards(
                _market,
                bonusTokens[i],
                poolInfo.rewarder,
                amounts[i],
                leftAmounts
            );
        }
    }

    /* ============ Internal Functions ============ */

    function _harvestMarketRewards(address _market, bool _force) internal {
        Pool storage poolInfo = pools[_market];
        if (
            !_force &&
            (block.timestamp - poolInfo.lastHarvestTime) < harvestTimeGap
        ) return;

        poolInfo.lastHarvestTime = block.timestamp;

        address[] memory bonusTokens = IPendleMarket(_market).getRewardTokens();
        uint256[] memory amountsBefore = new uint256[](bonusTokens.length);

        for (uint256 i; i < bonusTokens.length; i++) {
            if (bonusTokens[i] == NATIVE) bonusTokens[i] = address(WETH);
            amountsBefore[i] = IERC20(bonusTokens[i]).balanceOf(address(this));
        }

        IPendleMarket(_market).redeemRewards(address(this));

        for (uint256 i; i < bonusTokens.length; i++) {
            if (bonusTokens[i] == NATIVE) bonusTokens[i] = address(WETH);
            uint256 amountAfter = IERC20(bonusTokens[i]).balanceOf(
                address(this)
            );
            uint256 bonusBalance = amountAfter - amountsBefore[i];
            uint256 leftBonusBalance = bonusBalance;
            if (bonusBalance > 0) {
                _sendRewards(
                    _market,
                    bonusTokens[i],
                    poolInfo.rewarder,
                    bonusBalance,
                    leftBonusBalance
                );
            }
        }
    }

    function _harvestBatchMarketRewards(address[] memory _markets, address _caller, uint256 _minEthToRecieve) internal {
        uint256 harvestCallerTotalPendleReward;

        for (uint256 i = 0; i < _markets.length; i++) 
        {
            if (!pools[_markets[i]].isActive) revert OnlyActivePool();
            Pool storage poolInfo = pools[_markets[i]];

            poolInfo.lastHarvestTime = block.timestamp;

            address[] memory bonusTokens = IPendleMarket(_markets[i])
                .getRewardTokens();
            uint256[] memory amountsBefore = new uint256[](bonusTokens.length);

            for (uint256 j; j < bonusTokens.length; j++) {
                if (bonusTokens[j] == NATIVE) bonusTokens[j] = address(WETH);

                amountsBefore[j] = IERC20(bonusTokens[j]).balanceOf(
                    address(this)
                );
            }

            IPendleMarket(_markets[i]).redeemRewards(address(this));

            for (uint256 j; j < bonusTokens.length; j++) {
                uint256 amountAfter = IERC20(bonusTokens[j]).balanceOf(
                    address(this)
                );

                uint256 originalBonusBalance = amountAfter - amountsBefore[j];
                uint256 leftBonusBalance = originalBonusBalance;
                uint256 currentMarketHarvestPendleReward;

                if(originalBonusBalance == 0) continue;

                if (bonusTokens[j] == PENDLE) {
                    currentMarketHarvestPendleReward =
                        (originalBonusBalance * harvestCallerPendleFee) /
                        DENOMINATOR;
                    leftBonusBalance = originalBonusBalance - currentMarketHarvestPendleReward;
                }
                harvestCallerTotalPendleReward += currentMarketHarvestPendleReward;

                _sendRewards(
                    _markets[i],
                    bonusTokens[j],
                    poolInfo.rewarder,
                    originalBonusBalance,
                    leftBonusBalance
                );
            }
        }

        if (harvestCallerTotalPendleReward > 0) {
            IERC20(PENDLE).approve(ETHZapper, harvestCallerTotalPendleReward);

            IETHZapper(ETHZapper).swapExactTokensToETH(
                PENDLE,
                harvestCallerTotalPendleReward,
                _minEthToRecieve,
                _caller
            );
        }
    }

    /// @notice Send rewards to the rewarders
    /// @param _market the PENDLE market
    /// @param _rewardToken the address of the reward token to send
    /// @param _rewarder the rewarder for PENDLE lp that will get the rewards
    /// @param _originalRewardAmount  the initial amount of rewards after harvest
    /// @param _leftRewardAmount the intial amount - harvest caller rewardfee amount after harvest
    function _sendRewards(
        address _market,
        address _rewardToken,
        address _rewarder,
        uint256 _originalRewardAmount ,
        uint256 _leftRewardAmount 
    ) internal {
        if (_leftRewardAmount == 0) return;

        if (_rewardToken == address(PENDLE)) {
            for (uint256 i = 0; i < pendleFeeInfos.length; i++) {
                Fees storage feeInfo = pendleFeeInfos[i];

                if (feeInfo.isActive) {
                    address rewardToken = _rewardToken;
                    uint256 feeAmount = (_originalRewardAmount * feeInfo.value) /
                        DENOMINATOR;
                    _leftRewardAmount -= feeAmount;
                    uint256 feeTosend = feeAmount;

                    if (feeInfo.isMPENDLE) {
                        if (smartPendleConvert != address(0)) {
                            IERC20(PENDLE).safeApprove(
                                smartPendleConvert,
                                feeAmount
                            );
                            uint256 beforeBalance = IERC20(mPendleOFT)
                                .balanceOf(address(this));
                            ISmartPendleConvert(smartPendleConvert)
                                .smartConvert(feeAmount, 0);
                            rewardToken = mPendleOFT;
                            feeTosend =
                                IERC20(mPendleOFT).balanceOf(address(this)) -
                                beforeBalance;
                        } else {
                            IERC20(PENDLE).safeApprove(
                                mPendleConvertor,
                                feeAmount
                            );
                            uint256 beforeBalance = IERC20(mPendleOFT)
                                .balanceOf(address(this));
                            IConvertor(mPendleConvertor).convert(
                                address(this),
                                feeAmount,
                                0
                            );
                            rewardToken = mPendleOFT;
                            feeTosend =
                                IERC20(mPendleOFT).balanceOf(address(this)) -
                                beforeBalance;
                        }
                    }

                    if (!feeInfo.isAddress) {
                        IERC20(rewardToken).safeApprove(feeInfo.to, feeTosend);
                        IBaseRewardPool(feeInfo.to).queueNewRewards(
                            feeTosend,
                            rewardToken
                        );
                    } else {
                        IERC20(rewardToken).safeTransfer(feeInfo.to, feeTosend);
                    }

                    emit RewardPaidTo(
                        _market,
                        feeInfo.to,
                        rewardToken,
                        feeTosend
                    );
                }
            }
        } else {
            // other than PENDLE reward token.
            // if auto Bribe fee is 0, then all go to LP rewarder
             if (autoBribeFee > 0 && bribeManager != address(0)) {
                uint256 bribePid = IPenpieBribeManager(bribeManager).marketToPid(_market);
                if (IPenpieBribeManager(bribeManager).pools(bribePid)._active) {
                    uint256 autoBribeAmount = (_originalRewardAmount * autoBribeFee) / DENOMINATOR;
                    _leftRewardAmount -= autoBribeAmount;
                    IERC20(_rewardToken).safeApprove(bribeManager, autoBribeAmount);
                    IPenpieBribeManager(bribeManager).addBribeERC20(1, bribePid, _rewardToken, autoBribeAmount);

                    emit RewardPaidTo(
                        _market,
                        bribeManager,
                        _rewardToken,
                        autoBribeAmount
                    );
                }
            } 
        }

        IERC20(_rewardToken).safeApprove(_rewarder, 0);
        IERC20(_rewardToken).safeApprove(_rewarder, _leftRewardAmount);
        IBaseRewardPool(_rewarder).queueNewRewards(_leftRewardAmount, _rewardToken);
        emit RewardPaidTo(_market, _rewarder, _rewardToken, _leftRewardAmount);
    }
}
