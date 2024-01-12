// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

import "./Multicall.sol";
import "./IConvexBoosterV2.sol";
import "./ISupplyBooster.sol";
import "./IDepegShieldWrapper.sol";

interface ILendingSponsor {
    function addSponsor(bytes32 _lendingId, address _user) external payable;

    function payFee(bytes32 _lendingId, address payable _user) external;
}

contract LendingMarketV2 is Initializable, ReentrancyGuard, Multicall {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public convexBooster;
    address public supplyBooster;
    address public lendingSponsor;

    uint256 public liquidateThresholdBlockNumbers;
    uint256 public version;

    address public owner;
    address public governance;

    enum UserLendingState {
        LENDING,
        EXPIRED,
        LIQUIDATED
    }

    struct PoolInfo {
        uint256 convexPid;
        uint256[] supportPids;
        int128[] curveCoinIds;
        uint256 lendingThreshold;
        uint256 liquidateThreshold;
        uint256 borrowIndex;
    }

    struct UserLending {
        bytes32 lendingId;
        uint256 token0;
        uint256 token0Price;
        uint256 lendingAmount;
        uint256 borrowAmount;
        uint256 borrowInterest;
        uint256 supportPid;
        int128 curveCoinId;
        uint256 borrowNumbers;
    }

    struct LendingInfo {
        address user;
        uint256 pid;
        uint256 userLendingIndex;
        uint256 borrowIndex;
        uint256 startedBlock;
        uint256 utilizationRate;
        uint256 supplyRatePerBlock;
        UserLendingState state;
    }

    struct BorrowInfo {
        uint256 borrowAmount;
        uint256 supplyAmount;
    }

    struct Statistic {
        uint256 totalCollateral;
        uint256 totalBorrow;
        uint256 recentRepayAt;
    }

    struct LendingParams {
        uint256 lendingAmount;
        uint256 borrowAmount;
        uint256 borrowInterest;
        uint256 lendingRate;
        uint256 utilizationRate;
        uint256 supplyRatePerBlock;
        address lpToken;
        uint256 token0Price;
    }

    PoolInfo[] public poolInfo;

    address private constant ZERO_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant MIN_LIQUIDATE_BLOCK_NUMBERS = 50;
    uint256 private constant MIN_LENDING_THRESHOLD = 100;
    uint256 private constant MIN_LIQUIDATE_THRESHOLD = 50;
    uint256 private constant MAX_LIQUIDATE_BLOCK_NUMBERS = 100;
    uint256 private constant MAX_LENDING_THRESHOLD = 300;
    uint256 private constant MAX_LIQUIDATE_THRESHOLD = 300;
    uint256 private constant RATE_DENOMINATOR = 1e18;
    uint256 private constant MAX_LENDFLARE_TOTAL_RATE = 0.5 * 1e18;
    uint256 private constant THRESHOLD_DENOMINATOR = 1000;
    uint256 private constant BLOCKS_PER_YEAR = 2102400; // Reference Compound WhitePaperInterestRateModel contract
    uint256 private constant BLOCKS_PER_DAY = 5760;
    // user address => container
    mapping(address => UserLending[]) public userLendings;
    // lending id => user address
    mapping(bytes32 => LendingInfo) public lendings;
    // pool id => (borrowIndex => user lendingId)
    mapping(uint256 => mapping(uint256 => bytes32)) public poolLending;
    mapping(bytes32 => BorrowInfo) public borrowInfos;
    mapping(bytes32 => Statistic) public myStatistics;
    // number => bool
    mapping(uint256 => bool) public borrowBlocks;
    // pid => (user => amount)
    mapping(uint256 => mapping(address => uint256)) public deposits;

    event LendingBase(bytes32 indexed lendingId, uint256 marketPid, uint256 supplyPid, int128 curveCoinId, uint256 borrowBlocks);

    event Borrow(
        bytes32 indexed lendingId,
        address indexed user,
        uint256 pid,
        uint256 token0,
        uint256 token0Price,
        uint256 lendingAmount,
        uint256 borrowNumber
    );
    event Initialized(address indexed thisAddress);
    event RepayBorrow(bytes32 indexed lendingId, address user, UserLendingState state);

    event Liquidate(bytes32 indexed lendingId, address user, uint256 liquidateAmount, uint256 gasSpent, UserLendingState state);

    event SetOwner(address owner);
    event SetGovernance(address governance);
    event SetBorrowBlock(uint256 borrowBlock, bool state);
    event TogglePausedPool(uint256 pid, bool pause);
    event Deposit(address user, uint256 pid, uint256 token0);
    event Withdraw(address user, uint256 pid, uint256 token0);
    event SetLiquidateThresholdBlockNumbers(uint256 blockNumbers);
    event SetLendingThreshold(uint256 pid, uint256 threshold);
    event SetLiquidateThreshold(uint256 pid, uint256 threshold);
    event AddMarketPool(uint256 convexBoosterPid, uint256[] supplyBoosterPids, int128[] curveCoinIds, uint256 lendingThreshold, uint256 liquidateThreshold);
    event UpdatePoolMapping(uint256 pid, uint256[] supportPids, int128[] curveCoinIds);
    event Depeg(bytes32 indexed lendingId, uint256 leveragePrice);
    event TriggerDepegShield(uint256 pid, int128 coinId, address underlyingToken, uint256 tokensWhenTriggered);

    modifier onlyOwner() {
        require(owner == msg.sender, "LendingMarket: Caller is not the owner");
        _;
    }

    modifier onlyGovernance() {
        require(governance == msg.sender, "LendingMarket: Caller is not the governance");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    /* 
    The default governance user is GenerateLendingPools contract.
    It will be set to DAO in the future 
    */
    function setGovernance(address _governance) public onlyOwner {
        governance = _governance;

        emit SetGovernance(_governance);
    }

    function initialize(
        address _owner,
        address _lendingSponsor,
        address _convexBooster,
        address _supplyBooster
    ) public initializer {
        owner = _owner;
        governance = _owner;
        lendingSponsor = _lendingSponsor;
        convexBooster = _convexBooster;
        supplyBooster = _supplyBooster;

        setBorrowBlock(BLOCKS_PER_DAY * 90, true);
        setBorrowBlock(BLOCKS_PER_DAY * 180, true);
        setBorrowBlock(BLOCKS_PER_YEAR, true);

        liquidateThresholdBlockNumbers = 50;
        version = 1;

        emit Initialized(address(this));
    }

    function deposit(uint256 _pid, uint256 _token0) public {
        require(_pid < poolInfo.length, "!_pid");

        PoolInfo storage pool = poolInfo[_pid];

        address lpToken = IConvexBoosterV2(convexBooster).getPoolToken(pool.convexPid);

        IERC20(lpToken).safeTransferFrom(msg.sender, address(this), _token0);
        IERC20(lpToken).safeApprove(convexBooster, 0);
        IERC20(lpToken).safeApprove(convexBooster, _token0);

        IConvexBooster(convexBooster).depositFor(pool.convexPid, _token0, msg.sender);

        deposits[_pid][msg.sender] = deposits[_pid][msg.sender].add(_token0);

        emit Deposit(msg.sender, _pid, _token0);
    }

    function withdraw(uint256 _pid, uint256 _token0) public nonReentrant {
        require(_pid < poolInfo.length, "!_pid");

        PoolInfo storage pool = poolInfo[_pid];

        require(deposits[_pid][msg.sender] >= _token0, "!deposits");

        deposits[_pid][msg.sender] = deposits[_pid][msg.sender].sub(_token0);

        IConvexBooster(convexBooster).withdrawFor(pool.convexPid, _token0, msg.sender, false);

        emit Withdraw(msg.sender, _pid, _token0);
    }

    function borrowForDeposit(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid
    ) public payable nonReentrant returns (bytes32) {
        require(borrowBlocks[_borrowBlock], "!borrowBlocks");
        require(msg.value == 0.1 ether, "!lendingSponsor");

        deposits[_pid][msg.sender] = deposits[_pid][msg.sender].sub(_token0);

        return _borrow(_pid, _supportPid, _borrowBlock, _token0, true);
    }

    function borrow(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid
    ) public payable nonReentrant returns (bytes32) {
        require(borrowBlocks[_borrowBlock], "!borrowBlocks");
        require(msg.value == 0.1 ether, "!lendingSponsor");

        return _borrow(_pid, _supportPid, _borrowBlock, _token0, false);
    }

    function _protect(
        uint256 _pid,
        bytes32 _lendingId,
        uint256 _tokens
    ) internal {
        address depegShield = _depegShield();
        address _underlyingToken = ISupplyBooster(supplyBooster).getLendingUnderlyToken(_lendingId);

        if (depegShield != address(0)) {
            require(!IDepegShieldWrapper(depegShield).isTriggered(_pid, _underlyingToken), "LendingMarket: Pool is depeged");

            IDepegShieldWrapper(depegShield).protect(_pid, _lendingId, _tokens, _underlyingToken);
        }
    }

    function protect(bytes32 _lendingId) external nonReentrant {
        LendingInfo storage lendingInfo = lendings[_lendingId];

        require(lendingInfo.startedBlock > 0, "LendingMarket: Invalid lendingId");

        UserLending storage userLending = userLendings[lendingInfo.user][lendingInfo.userLendingIndex];

        _protect(lendingInfo.pid, _lendingId, userLending.token0);
    }

    function getBorrowInfo(
        uint256 _convexPid,
        int128 _curveCoinId,
        uint256 _token0
    ) internal returns (address lpToken, uint256 token0Price) {
        lpToken = IConvexBoosterV2(convexBooster).getPoolToken(_convexPid);
        token0Price = IConvexBoosterV2(convexBooster).updateMovingLeverage(_convexPid, _token0, _curveCoinId);
    }

    function _borrow(
        uint256 _pid,
        uint256 _supportPid,
        uint256 _borrowBlocks,
        uint256 _token0,
        bool _preStored
    ) internal returns (bytes32) {
        PoolInfo storage pool = poolInfo[_pid];

        pool.borrowIndex++;

        bytes32 lendingId = generateId(msg.sender, _pid, pool.borrowIndex + block.number);

        LendingParams memory lendingParams = getLendingInfo(
            _token0,
            pool.convexPid,
            pool.curveCoinIds[_supportPid],
            pool.supportPids[_supportPid],
            pool.lendingThreshold,
            pool.liquidateThreshold,
            _borrowBlocks
        );

        if (!_preStored) {
            IERC20(lendingParams.lpToken).safeTransferFrom(msg.sender, address(this), _token0);

            IERC20(lendingParams.lpToken).safeApprove(convexBooster, 0);
            IERC20(lendingParams.lpToken).safeApprove(convexBooster, _token0);

            IConvexBooster(convexBooster).depositFor(pool.convexPid, _token0, msg.sender);
        }

        ISupplyBooster(supplyBooster).borrow(
            pool.supportPids[_supportPid],
            lendingId,
            msg.sender,
            lendingParams.lendingAmount,
            lendingParams.borrowInterest,
            _borrowBlocks
        );

        BorrowInfo storage borrowInfo = borrowInfos[generateId(address(0), _pid, pool.supportPids[_supportPid])];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.add(lendingParams.token0Price);
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.add(lendingParams.lendingAmount);

        Statistic storage statistic = myStatistics[generateId(msg.sender, _pid, pool.supportPids[_supportPid])];

        statistic.totalCollateral = statistic.totalCollateral.add(_token0);
        statistic.totalBorrow = statistic.totalBorrow.add(lendingParams.lendingAmount);

        userLendings[msg.sender].push(
            UserLending({
                lendingId: lendingId,
                token0: _token0,
                token0Price: lendingParams.token0Price,
                lendingAmount: lendingParams.lendingAmount,
                borrowAmount: lendingParams.borrowAmount,
                borrowInterest: lendingParams.borrowInterest,
                supportPid: pool.supportPids[_supportPid],
                curveCoinId: pool.curveCoinIds[_supportPid],
                borrowNumbers: _borrowBlocks
            })
        );

        lendings[lendingId] = LendingInfo({
            user: msg.sender,
            pid: _pid,
            borrowIndex: pool.borrowIndex,
            userLendingIndex: userLendings[msg.sender].length - 1,
            startedBlock: block.number,
            utilizationRate: lendingParams.utilizationRate,
            supplyRatePerBlock: lendingParams.supplyRatePerBlock,
            state: UserLendingState.LENDING
        });

        poolLending[_pid][pool.borrowIndex] = lendingId;

        ILendingSponsor(lendingSponsor).addSponsor{ value: msg.value }(lendingId, msg.sender);

        _protect(_pid, lendingId, _token0);

        emit LendingBase(lendingId, _pid, pool.supportPids[_supportPid], pool.curveCoinIds[_supportPid], _borrowBlocks);

        emit Borrow(lendingId, msg.sender, _pid, _token0, lendingParams.token0Price, lendingParams.lendingAmount, _borrowBlocks);

        return lendingId;
    }

    function _repayBorrow(
        bytes32 _lendingId,
        uint256 _amount,
        bool _freezeTokens
    ) internal nonReentrant {
        LendingInfo storage lendingInfo = lendings[_lendingId];

        require(lendingInfo.startedBlock > 0, "LendingMarket:: Invalid lendingId");

        UserLending storage userLending = userLendings[lendingInfo.user][lendingInfo.userLendingIndex];
        PoolInfo storage pool = poolInfo[lendingInfo.pid];

        require(lendingInfo.state == UserLendingState.LENDING, "!UserLendingState");
        require(block.number <= lendingInfo.startedBlock.add(userLending.borrowNumbers), "LendingMarket: Expired");

        bool isTriggered;
        uint256 depegAmount;
        address depegShield = _depegShield();

        if (depegShield != address(0)) {
            (bool isProtect, address underlyingToken) = IDepegShieldWrapper(depegShield).isProtect(_lendingId);

            if (isProtect) {
                isTriggered = IDepegShieldWrapper(depegShield).isTriggered(lendingInfo.pid, underlyingToken);

                if (isTriggered) {
                    (, depegAmount) = IDepegShieldWrapper(depegShield).solved(_lendingId, address(this));

                    require(depegAmount > 0, "!depegAmount");
                } else {
                    IDepegShieldWrapper(depegShield).unprotect(_lendingId);
                }
            }
        }

        if (!isTriggered) {
            IConvexBooster(convexBooster).withdrawFor(pool.convexPid, userLending.token0, lendingInfo.user, _freezeTokens);
        }

        address underlyToken = ISupplyBooster(supplyBooster).getLendingUnderlyToken(userLending.lendingId);

        if (underlyToken == ZERO_ADDRESS) {
            if (!isTriggered) {
                require(msg.value == _amount && _amount == userLending.lendingAmount, "!_amount");
            } else {
                if (depegAmount < userLending.lendingAmount) {
                    require(userLending.lendingAmount.sub(depegAmount) == msg.value, "!_amount");
                }
            }

            ISupplyBooster(supplyBooster).repayBorrow{ value: userLending.lendingAmount }(userLending.lendingId, lendingInfo.user, userLending.borrowInterest);
        } else {
            require(msg.value == 0, "!msg.value");

            if (!isTriggered) {
                require(_amount == userLending.lendingAmount, "!_amount");

                IERC20(underlyToken).safeTransferFrom(msg.sender, supplyBooster, userLending.lendingAmount);
            } else {
                if (depegAmount < userLending.lendingAmount) {
                    require(userLending.lendingAmount.sub(depegAmount) == _amount, "!_amount");

                    uint256 extraErc20Amount = userLending.lendingAmount.sub(depegAmount);

                    IERC20(underlyToken).safeTransferFrom(msg.sender, address(this), extraErc20Amount);
                    IERC20(underlyToken).safeTransfer(supplyBooster, depegAmount.add(extraErc20Amount));
                } else {
                    uint256 extraErc20Amount = depegAmount.sub(userLending.lendingAmount);

                    IERC20(underlyToken).safeTransfer(supplyBooster, userLending.lendingAmount);
                    IERC20(underlyToken).safeTransfer(lendingInfo.user, extraErc20Amount);
                }
            }

            ISupplyBooster(supplyBooster).repayBorrow(userLending.lendingId, lendingInfo.user, userLending.lendingAmount, userLending.borrowInterest);
        }

        BorrowInfo storage borrowInfo = borrowInfos[generateId(address(0), lendingInfo.pid, userLending.supportPid)];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(userLending.token0Price);
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(userLending.lendingAmount);

        Statistic storage statistic = myStatistics[generateId(lendingInfo.user, lendingInfo.pid, userLending.supportPid)];

        statistic.totalCollateral = statistic.totalCollateral.sub(userLending.token0);
        statistic.totalBorrow = statistic.totalBorrow.sub(userLending.lendingAmount);
        statistic.recentRepayAt = block.timestamp;

        ILendingSponsor(lendingSponsor).payFee(userLending.lendingId, payable(lendingInfo.user));

        lendingInfo.state = UserLendingState.EXPIRED;

        emit RepayBorrow(userLending.lendingId, lendingInfo.user, lendingInfo.state);
    }

    function repayBorrow(bytes32 _lendingId) public payable {
        _repayBorrow(_lendingId, msg.value, false);
    }

    function repayBorrowERC20(bytes32 _lendingId, uint256 _amount) public {
        _repayBorrow(_lendingId, _amount, false);
    }

    function repayBorrowAndFreezeTokens(bytes32 _lendingId) public payable {
        _repayBorrow(_lendingId, msg.value, true);
    }

    function repayBorrowERC20AndFreezeTokens(bytes32 _lendingId, uint256 _amount) public {
        _repayBorrow(_lendingId, _amount, true);
    }

    /**
    @notice Used to liquidate asset
    @dev If repayment is overdue, it is used to liquidate asset. If valued LP is not enough, can use msg.value or _extraErc20Amount force liquidation
    @param _lendingId Lending ID
    @param _extraErc20Amount If liquidate erc-20 asset, fill in extra amount. If native asset, send msg.value
     */
    function liquidate(bytes32 _lendingId, uint256 _extraErc20Amount) public payable nonReentrant {
        uint256 gasStart = gasleft();
        LendingInfo storage lendingInfo = lendings[_lendingId];

        if (lendingInfo.user == _autoCompounding()) {
            require(msg.sender == lendingInfo.user, "LendingMarket:: Invalid caller");
        }

        require(lendingInfo.startedBlock > 0, "LendingMarket: Invalid lendingId");

        UserLending storage userLending = userLendings[lendingInfo.user][lendingInfo.userLendingIndex];

        require(lendingInfo.state == UserLendingState.LENDING, "!UserLendingState");
        require(lendingInfo.startedBlock.add(userLending.borrowNumbers).sub(liquidateThresholdBlockNumbers) < block.number, "!BorrowNumbers");

        PoolInfo storage pool = poolInfo[lendingInfo.pid];

        lendingInfo.state = UserLendingState.LIQUIDATED;

        BorrowInfo storage borrowInfo = borrowInfos[generateId(address(0), lendingInfo.pid, userLending.supportPid)];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(userLending.token0Price);
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(userLending.lendingAmount);

        Statistic storage statistic = myStatistics[generateId(lendingInfo.user, lendingInfo.pid, userLending.supportPid)];

        statistic.totalCollateral = statistic.totalCollateral.sub(userLending.token0);
        statistic.totalBorrow = statistic.totalBorrow.sub(userLending.lendingAmount);

        ILendingSponsor(lendingSponsor).payFee(userLending.lendingId, msg.sender);

        bool isTriggered;
        uint256 liquidateAmount;
        address underlyToken;
        address depegShield = _depegShield();

        if (depegShield != address(0)) {
            (bool isProtect, address underlyingToken) = IDepegShieldWrapper(depegShield).isProtect(_lendingId);

            if (isProtect) {
                isTriggered = IDepegShieldWrapper(depegShield).isTriggered(lendingInfo.pid, underlyingToken);

                if (isTriggered) {
                    (underlyToken, liquidateAmount) = IDepegShieldWrapper(depegShield).solved(_lendingId, address(this));

                    require(liquidateAmount > 0, "!liquidateAmount");
                } else {
                    IDepegShieldWrapper(depegShield).unprotect(_lendingId);
                }
            }
        }

        if (!isTriggered) {
            (underlyToken, liquidateAmount) = IConvexBooster(convexBooster).liquidate(
                pool.convexPid,
                userLending.curveCoinId,
                lendingInfo.user,
                userLending.token0
            );
        }

        if (underlyToken == ZERO_ADDRESS) {
            liquidateAmount = liquidateAmount.add(msg.value);

            ISupplyBooster(supplyBooster).liquidate{ value: liquidateAmount }(userLending.lendingId, userLending.borrowInterest);
        } else {
            IERC20(underlyToken).safeTransfer(supplyBooster, liquidateAmount);

            if (_extraErc20Amount > 0) {
                // Failure without authorization
                IERC20(underlyToken).safeTransferFrom(msg.sender, supplyBooster, _extraErc20Amount);
            }

            ISupplyBooster(supplyBooster).liquidate(userLending.lendingId, userLending.borrowInterest);
        }

        uint256 gasSpent = (21000 + gasStart - gasleft()).mul(tx.gasprice);

        emit Liquidate(userLending.lendingId, lendingInfo.user, liquidateAmount, gasSpent, lendingInfo.state);
    }

    function setLiquidateThresholdBlockNumbers(uint256 _v) public onlyGovernance {
        require(_v >= MIN_LIQUIDATE_BLOCK_NUMBERS && _v <= MAX_LIQUIDATE_BLOCK_NUMBERS, "!_v");

        liquidateThresholdBlockNumbers = _v;

        emit SetLiquidateThresholdBlockNumbers(liquidateThresholdBlockNumbers);
    }

    function setBorrowBlock(uint256 _number, bool _state) public onlyGovernance {
        require(_number.sub(liquidateThresholdBlockNumbers) > liquidateThresholdBlockNumbers, "!_number");

        borrowBlocks[_number] = _state;

        emit SetBorrowBlock(_number, borrowBlocks[_number]);
    }

    function setLendingThreshold(uint256 _pid, uint256 _v) public onlyGovernance {
        require(_v >= MIN_LENDING_THRESHOLD && _v <= MAX_LENDING_THRESHOLD, "!_v");

        PoolInfo storage pool = poolInfo[_pid];

        pool.lendingThreshold = _v;

        emit SetLendingThreshold(_pid, pool.lendingThreshold);
    }

    function setLiquidateThreshold(uint256 _pid, uint256 _v) public onlyGovernance {
        require(_v >= MIN_LIQUIDATE_THRESHOLD && _v <= MAX_LIQUIDATE_THRESHOLD, "!_v");

        PoolInfo storage pool = poolInfo[_pid];

        pool.liquidateThreshold = _v;

        emit SetLiquidateThreshold(_pid, pool.lendingThreshold);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /* 
    @param _convexBoosterPid convexBooster contract
    @param _supplyBoosterPids supply contract
    @param _curveCoinIds curve coin id of curve COINS
     */
    function addMarketPool(
        uint256 _convexBoosterPid,
        uint256[] calldata _supplyBoosterPids,
        int128[] calldata _curveCoinIds,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold
    ) public onlyGovernance {
        require(_lendingThreshold >= MIN_LENDING_THRESHOLD && _lendingThreshold <= MAX_LENDING_THRESHOLD, "!_lendingThreshold");
        require(_liquidateThreshold >= MIN_LIQUIDATE_THRESHOLD && _liquidateThreshold <= MAX_LIQUIDATE_THRESHOLD, "!_liquidateThreshold");
        require(_supplyBoosterPids.length == _curveCoinIds.length, "!_supportPids && _curveCoinIds");

        poolInfo.push(
            PoolInfo({
                convexPid: _convexBoosterPid,
                supportPids: _supplyBoosterPids,
                curveCoinIds: _curveCoinIds,
                lendingThreshold: _lendingThreshold,
                liquidateThreshold: _liquidateThreshold,
                borrowIndex: 0
            })
        );

        emit AddMarketPool(_convexBoosterPid, _supplyBoosterPids, _curveCoinIds, _lendingThreshold, _liquidateThreshold);
    }

    function updatePoolMapping(
        uint256 _pid,
        uint256[] calldata _supplyBoosterPids,
        int128[] calldata _curveCoinIds
    ) public onlyGovernance {
        require(_pid < poolInfo.length, "!_pid");

        PoolInfo storage pool = poolInfo[_pid];

        pool.supportPids = _supplyBoosterPids;
        pool.curveCoinIds = _curveCoinIds;

        emit UpdatePoolMapping(_pid, _supplyBoosterPids, _curveCoinIds);
    }

    function triggerDepegShield(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "!_pid");

        address depegShield = _depegShield();

        if (depegShield != address(0)) {
            PoolInfo storage pool = poolInfo[_pid];

            for (uint256 i = 0; i < pool.curveCoinIds.length; i++) {
                (address underlyingToken, , , , , ) = ISupplyBooster(supplyBooster).poolInfo(pool.supportPids[i]);
                (, uint256 totalCollateral, uint256 underlyingBalance) = IDepegShieldWrapper(depegShield).getInfo(_pid, underlyingToken);

                if (IDepegShieldWrapper(depegShield).checkAndToggleTrigger(_pid, underlyingToken)) {
                    if (underlyingBalance > 0) continue;

                    (, uint256 tokensWhenTriggered) = IConvexBoosterV2(convexBooster).depeg(pool.convexPid, totalCollateral, pool.curveCoinIds[i], depegShield);

                    IDepegShieldWrapper(depegShield).trigger(_pid, underlyingToken, tokensWhenTriggered);

                    emit TriggerDepegShield(_pid, pool.curveCoinIds[i], underlyingToken, tokensWhenTriggered);
                }
            }
        }
    }

    function _depegShield() internal pure returns (address) {
        return 0x8a06635c5a84Bd0f2Edaeb31C0d5DA0F5523Af77;
    }

    function _autoCompounding() internal pure returns (address) {
        return 0x803FFDFF8150093BE6fc78a0963f443e9bD9c378;
    }

    /* function toBytes16(uint256 x) internal pure returns (bytes16 b) {
        return bytes16(bytes32(x));
    } */

    function generateId(
        address x,
        uint256 y,
        uint256 z
    ) public pure returns (bytes32) {
        /* return toBytes16(uint256(keccak256(abi.encodePacked(x, y, z)))); */
        return keccak256(abi.encodePacked(x, y, z));
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function cursor(
        uint256 _pid,
        uint256 _offset,
        uint256 _size
    ) public view returns (bytes32[] memory, uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 size = _offset.add(_size) > pool.borrowIndex ? pool.borrowIndex.sub(_offset) : _size;

        bytes32[] memory userLendingIds = new bytes32[](size);

        for (uint256 i = 0; i < size; i++) {
            bytes32 userLendingId = poolLending[_pid][_offset.add(i)];

            userLendingIds[i] = userLendingId;
        }

        return (userLendingIds, pool.borrowIndex);
    }

    function calculateRepayAmount(bytes32 _lendingId) public view returns (uint256) {
        LendingInfo storage lendingInfo = lendings[_lendingId];
        UserLending storage userLending = userLendings[lendingInfo.user][lendingInfo.userLendingIndex];

        if (lendingInfo.state == UserLendingState.LENDING) return userLending.lendingAmount;

        return 0;
    }

    function getPoolSupportPid(uint256 _pid, uint256 _supportPid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        return pool.supportPids[_supportPid];
    }

    function getCurveCoinId(uint256 _pid, uint256 _supportPid) public view returns (int128) {
        PoolInfo storage pool = poolInfo[_pid];

        return pool.curveCoinIds[_supportPid];
    }

    function getLendingInfo(
        uint256 _token0,
        uint256 _convexPid,
        int128 _curveCoinId,
        uint256 _supplyPid,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold,
        uint256 _borrowBlocks
    ) public returns (LendingParams memory) {
        (address lpToken, uint256 token0Price) = getBorrowInfo(_convexPid, _curveCoinId, _token0);

        uint256 utilizationRate = ISupplyBooster(supplyBooster).getUtilizationRate(_supplyPid);
        uint256 supplyRatePerBlock = ISupplyBooster(supplyBooster).getBorrowRatePerBlock(_supplyPid);
        uint256 supplyRate = getSupplyRate(supplyRatePerBlock, _borrowBlocks);
        uint256 lendflareTotalRate;

        if (utilizationRate > 0) {
            lendflareTotalRate = getLendingRate(supplyRate, getAmplificationFactor(utilizationRate));
        } else {
            lendflareTotalRate = supplyRate.sub(RATE_DENOMINATOR);
        }

        uint256 lendingAmount = token0Price.mul(RATE_DENOMINATOR);

        lendingAmount = lendingAmount.mul(THRESHOLD_DENOMINATOR.sub(_lendingThreshold).sub(_liquidateThreshold));
        lendingAmount = lendingAmount.div(THRESHOLD_DENOMINATOR);

        uint256 repayBorrowAmount = lendingAmount.div(RATE_DENOMINATOR);
        uint256 borrowAmount = lendingAmount.div(RATE_DENOMINATOR.add(lendflareTotalRate));
        uint256 borrowInterest = repayBorrowAmount.sub(borrowAmount);

        return
            LendingParams({
                lendingAmount: repayBorrowAmount,
                borrowAmount: borrowAmount,
                borrowInterest: borrowInterest,
                lendingRate: lendflareTotalRate,
                utilizationRate: utilizationRate,
                supplyRatePerBlock: supplyRatePerBlock,
                lpToken: lpToken,
                token0Price: token0Price
            });
    }

    function getUserLendingsLength(address _user) public view returns (uint256) {
        return userLendings[_user].length;
    }

    function getUserLending(address _user, uint256 _lendingIndex) public view returns (UserLending memory) {
        return userLendings[_user][_lendingIndex];
    }

    function getSupplyRate(uint256 _supplyBlockRate, uint256 n)
        public
        pure
        returns (
            uint256 total // _supplyBlockRate and the result are scaled to 1e18
        )
    {
        uint256 term = 1e18; // term0 = xn, term1 = n(n-1)/2! * x^2, term2 = term1 * (n - 2) / (i + 1) * x
        uint256 result = 1e18; // partial sum of terms
        uint256 MAX_TERMS = 10; // up to MAX_TERMS are calculated, the error is negligible

        for (uint256 i = 0; i < MAX_TERMS && i < n; ++i) {
            term = term.mul(n - i).div(i + 1).mul(_supplyBlockRate).div(1e18);

            total = total.add(term);
        }

        total = total.add(result);
    }

    function getAmplificationFactor(uint256 _utilizationRate) public pure returns (uint256) {
        if (_utilizationRate <= 0.9 * 1e18) {
            return uint256(10).mul(_utilizationRate).div(9).add(1e18);
        }

        return uint256(20).mul(_utilizationRate).sub(16 * 1e18);
    }

    // lendflare total rate
    function getLendingRate(uint256 _supplyRate, uint256 _amplificationFactor) public pure returns (uint256) {
        return _supplyRate.sub(1e18).mul(_amplificationFactor).div(1e18);
    }
}
