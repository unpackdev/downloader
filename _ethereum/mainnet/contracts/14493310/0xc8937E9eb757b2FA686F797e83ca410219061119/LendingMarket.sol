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
import "./IConvexBooster.sol";
import "./ISupplyBooster.sol";

interface ICurveSwap {
    function calc_withdraw_one_coin(uint256 _tokenAmount, int128 _tokenId)
        external
        view
        returns (uint256);
}

interface ILendingSponsor {
    function addSponsor(bytes32 _lendingId, address _user) external payable;

    function payFee(bytes32 _lendingId, address payable _user) external;
}

contract LendingMarket is Initializable, ReentrancyGuard {
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

    address public constant ZERO_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant MIN_LIQUIDATE_BLOCK_NUMBERS = 50;
    uint256 public constant MIN_LENDING_THRESHOLD = 100;
    uint256 public constant MIN_LIQUIDATE_THRESHOLD = 50;
    uint256 public constant MAX_LIQUIDATE_BLOCK_NUMBERS = 100;
    uint256 public constant MAX_LENDING_THRESHOLD = 300;
    uint256 public constant MAX_LIQUIDATE_THRESHOLD = 300;
    uint256 public constant SUPPLY_RATE_DENOMINATOR = 1e18;
    uint256 public constant MAX_LENDFLARE_TOTAL_RATE = 0.5 * 1e18;
    uint256 public constant THRESHOLD_DENOMINATOR = 1000;
    uint256 public constant BLOCKS_PER_YEAR = 2102400; // Reference Compound WhitePaperInterestRateModel contract
    uint256 public constant BLOCKS_PER_DAY = 5760;
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

    event LendingBase(
        bytes32 indexed lendingId,
        uint256 marketPid,
        uint256 supplyPid,
        int128 curveCoinId,
        uint256 borrowBlocks
    );

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
    event RepayBorrow(
        bytes32 indexed lendingId,
        address user,
        UserLendingState state
    );

    event Liquidate(
        bytes32 indexed lendingId,
        address user,
        uint256 liquidateAmount,
        uint256 gasSpent,
        UserLendingState state
    );

    event SetOwner(address owner);
    event SetGovernance(address governance);
    event SetBorrowBlock(uint256 borrowBlock, bool state);

    modifier onlyOwner() {
        require(owner == msg.sender, "LendingMarket: caller is not the owner");
        _;
    }

    modifier onlyGovernance() {
        require(
            governance == msg.sender,
            "LendingMarket: caller is not the governance"
        );
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

    function borrow(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid
    ) public payable nonReentrant {
        require(borrowBlocks[_borrowBlock], "!borrowBlocks");
        require(msg.value == 0.1 ether, "!lendingSponsor");

        _borrow(_pid, _supportPid, _borrowBlock, _token0);
    }

    function _getCurveInfo(
        uint256 _convexPid,
        int128 _curveCoinId,
        uint256 _token0
    ) internal view returns (address lpToken, uint256 token0Price) {
        address curveSwapAddress;

        (, curveSwapAddress, lpToken, , , , , , ) = IConvexBooster(
            convexBooster
        ).poolInfo(_convexPid);

        token0Price = ICurveSwap(curveSwapAddress).calc_withdraw_one_coin(
            _token0,
            _curveCoinId
        );
    }

    function _borrow(
        uint256 _pid,
        uint256 _supportPid,
        uint256 _borrowBlocks,
        uint256 _token0
    ) internal returns (LendingParams memory) {
        PoolInfo storage pool = poolInfo[_pid];

        pool.borrowIndex++;

        bytes32 lendingId = generateId(
            msg.sender,
            _pid,
            pool.borrowIndex + block.number
        );

        LendingParams memory lendingParams = getLendingInfo(
            _token0,
            pool.convexPid,
            pool.curveCoinIds[_supportPid],
            pool.supportPids[_supportPid],
            pool.lendingThreshold,
            pool.liquidateThreshold,
            _borrowBlocks
        );

        IERC20(lendingParams.lpToken).safeTransferFrom(
            msg.sender,
            address(this),
            _token0
        );

        IERC20(lendingParams.lpToken).safeApprove(convexBooster, 0);
        IERC20(lendingParams.lpToken).safeApprove(convexBooster, _token0);

        ISupplyBooster(supplyBooster).borrow(
            pool.supportPids[_supportPid],
            lendingId,
            msg.sender,
            lendingParams.lendingAmount,
            lendingParams.borrowInterest,
            _borrowBlocks
        );

        IConvexBooster(convexBooster).depositFor(
            pool.convexPid,
            _token0,
            msg.sender
        );

        BorrowInfo storage borrowInfo = borrowInfos[
            generateId(address(0), _pid, pool.supportPids[_supportPid])
        ];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.add(
            lendingParams.token0Price
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.add(
            lendingParams.lendingAmount
        );

        Statistic storage statistic = myStatistics[
            generateId(msg.sender, _pid, pool.supportPids[_supportPid])
        ];

        statistic.totalCollateral = statistic.totalCollateral.add(_token0);
        statistic.totalBorrow = statistic.totalBorrow.add(
            lendingParams.lendingAmount
        );

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

        ILendingSponsor(lendingSponsor).addSponsor{value: msg.value}(
            lendingId,
            msg.sender
        );

        emit LendingBase(
            lendingId,
            _pid,
            pool.supportPids[_supportPid],
            pool.curveCoinIds[_supportPid],
            _borrowBlocks
        );

        emit Borrow(
            lendingId,
            msg.sender,
            _pid,
            _token0,
            lendingParams.token0Price,
            lendingParams.lendingAmount,
            _borrowBlocks
        );
    }

    function _repayBorrow(
        bytes32 _lendingId,
        uint256 _amount,
        bool _freezeTokens
    ) internal nonReentrant {
        LendingInfo storage lendingInfo = lendings[_lendingId];

        require(lendingInfo.startedBlock > 0, "!invalid lendingId");

        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingIndex
        ];
        address underlyToken = ISupplyBooster(supplyBooster)
            .getLendingUnderlyToken(userLending.lendingId);
        PoolInfo storage pool = poolInfo[lendingInfo.pid];

        require(
            lendingInfo.state == UserLendingState.LENDING,
            "!UserLendingState"
        );

        require(
            block.number <=
                lendingInfo.startedBlock.add(userLending.borrowNumbers),
            "Expired"
        );

        if (underlyToken == ZERO_ADDRESS) {
            require(
                msg.value == _amount && _amount == userLending.lendingAmount,
                "!_amount"
            );

            ISupplyBooster(supplyBooster).repayBorrow{
                value: userLending.lendingAmount
            }(
                userLending.lendingId,
                lendingInfo.user,
                userLending.borrowInterest
            );
        } else {
            require(
                msg.value == 0 && _amount == userLending.lendingAmount,
                "!_amount"
            );

            IERC20(underlyToken).safeTransferFrom(
                msg.sender,
                supplyBooster,
                userLending.lendingAmount
            );

            ISupplyBooster(supplyBooster).repayBorrow(
                userLending.lendingId,
                lendingInfo.user,
                userLending.lendingAmount,
                userLending.borrowInterest
            );
        }

        IConvexBooster(convexBooster).withdrawFor(
            pool.convexPid,
            userLending.token0,
            lendingInfo.user,
            _freezeTokens
        );

        BorrowInfo storage borrowInfo = borrowInfos[
            generateId(address(0), lendingInfo.pid, userLending.supportPid)
        ];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(
            userLending.token0Price
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(
            userLending.lendingAmount
        );

        Statistic storage statistic = myStatistics[
            generateId(
                lendingInfo.user,
                lendingInfo.pid,
                userLending.supportPid
            )
        ];

        statistic.totalCollateral = statistic.totalCollateral.sub(
            userLending.token0
        );
        statistic.totalBorrow = statistic.totalBorrow.sub(
            userLending.lendingAmount
        );
        statistic.recentRepayAt = block.timestamp;

        ILendingSponsor(lendingSponsor).payFee(
            userLending.lendingId,
            payable(lendingInfo.user)
        );

        lendingInfo.state = UserLendingState.EXPIRED;

        emit RepayBorrow(
            userLending.lendingId,
            lendingInfo.user,
            lendingInfo.state
        );
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

    function repayBorrowERC20AndFreezeTokens(
        bytes32 _lendingId,
        uint256 _amount
    ) public {
        _repayBorrow(_lendingId, _amount, true);
    }

    /**
    @notice Used to liquidate asset
    @dev If repayment is overdue, it is used to liquidate asset. If valued LP is not enough, can use msg.value or _extraErc20Amount force liquidation
    @param _lendingId Lending ID
    @param _extraErc20Amount If liquidate erc-20 asset, fill in extra amount. If native asset, send msg.value
     */
    function liquidate(bytes32 _lendingId, uint256 _extraErc20Amount)
        public
        payable
        nonReentrant
    {
        uint256 gasStart = gasleft();
        LendingInfo storage lendingInfo = lendings[_lendingId];

        require(lendingInfo.startedBlock > 0, "!invalid lendingId");

        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingIndex
        ];

        require(
            lendingInfo.state == UserLendingState.LENDING,
            "!UserLendingState"
        );

        require(
            lendingInfo.startedBlock.add(userLending.borrowNumbers).sub(
                liquidateThresholdBlockNumbers
            ) < block.number,
            "!borrowNumbers"
        );

        PoolInfo storage pool = poolInfo[lendingInfo.pid];

        lendingInfo.state = UserLendingState.LIQUIDATED;

        BorrowInfo storage borrowInfo = borrowInfos[
            generateId(address(0), lendingInfo.pid, userLending.supportPid)
        ];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(
            userLending.token0Price
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(
            userLending.lendingAmount
        );

        Statistic storage statistic = myStatistics[
            generateId(
                lendingInfo.user,
                lendingInfo.pid,
                userLending.supportPid
            )
        ];

        statistic.totalCollateral = statistic.totalCollateral.sub(
            userLending.token0
        );
        statistic.totalBorrow = statistic.totalBorrow.sub(
            userLending.lendingAmount
        );

        (address underlyToken, uint256 liquidateAmount) = IConvexBooster(
            convexBooster
        ).liquidate(
                pool.convexPid,
                userLending.curveCoinId,
                lendingInfo.user,
                userLending.token0
            );

        if (underlyToken == ZERO_ADDRESS) {
            liquidateAmount = liquidateAmount.add(msg.value);

            ISupplyBooster(supplyBooster).liquidate{value: liquidateAmount}(
                userLending.lendingId,
                userLending.borrowInterest
            );
        } else {
            IERC20(underlyToken).safeTransfer(supplyBooster, liquidateAmount);

            if (_extraErc20Amount > 0) {
                // Failure without authorization
                IERC20(underlyToken).safeTransferFrom(
                    msg.sender,
                    supplyBooster,
                    _extraErc20Amount
                );
            }

            ISupplyBooster(supplyBooster).liquidate(
                userLending.lendingId,
                userLending.borrowInterest
            );
        }

        ILendingSponsor(lendingSponsor).payFee(
            userLending.lendingId,
            msg.sender
        );

        uint256 gasSpent = (21000 + gasStart - gasleft()).mul(tx.gasprice);

        emit Liquidate(
            userLending.lendingId,
            lendingInfo.user,
            liquidateAmount,
            gasSpent,
            lendingInfo.state
        );
    }

    function setLiquidateThresholdBlockNumbers(uint256 _v)
        public
        onlyGovernance
    {
        require(
            _v >= MIN_LIQUIDATE_BLOCK_NUMBERS &&
                _v <= MAX_LIQUIDATE_BLOCK_NUMBERS,
            "!_v"
        );

        liquidateThresholdBlockNumbers = _v;
    }

    function setBorrowBlock(uint256 _number, bool _state)
        public
        onlyGovernance
    {
        require(
            _number.sub(liquidateThresholdBlockNumbers) >
                liquidateThresholdBlockNumbers,
            "!_number"
        );

        borrowBlocks[_number] = _state;

        emit SetBorrowBlock(_number, borrowBlocks[_number]);
    }

    function setLendingThreshold(uint256 _pid, uint256 _v)
        public
        onlyGovernance
    {
        require(
            _v >= MIN_LENDING_THRESHOLD && _v <= MAX_LENDING_THRESHOLD,
            "!_v"
        );

        PoolInfo storage pool = poolInfo[_pid];

        pool.lendingThreshold = _v;
    }

    function setLiquidateThreshold(uint256 _pid, uint256 _v)
        public
        onlyGovernance
    {
        require(
            _v >= MIN_LIQUIDATE_THRESHOLD && _v <= MAX_LIQUIDATE_THRESHOLD,
            "!_v"
        );

        PoolInfo storage pool = poolInfo[_pid];

        pool.liquidateThreshold = _v;
    }

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
        require(
            _lendingThreshold >= MIN_LENDING_THRESHOLD &&
                _lendingThreshold <= MAX_LENDING_THRESHOLD,
            "!_lendingThreshold"
        );
        require(
            _liquidateThreshold >= MIN_LIQUIDATE_THRESHOLD &&
                _liquidateThreshold <= MAX_LIQUIDATE_THRESHOLD,
            "!_liquidateThreshold"
        );
        require(
            _supplyBoosterPids.length == _curveCoinIds.length,
            "!_supportPids && _curveCoinIds"
        );

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

        uint256 size = _offset.add(_size) > pool.borrowIndex
            ? pool.borrowIndex.sub(_offset)
            : _size;

        bytes32[] memory userLendingIds = new bytes32[](size);

        for (uint256 i = 0; i < size; i++) {
            bytes32 userLendingId = poolLending[_pid][_offset.add(i)];

            userLendingIds[i] = userLendingId;
        }

        return (userLendingIds, pool.borrowIndex);
    }

    function calculateRepayAmount(bytes32 _lendingId)
        public
        view
        returns (uint256)
    {
        LendingInfo storage lendingInfo = lendings[_lendingId];
        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingIndex
        ];

        if (lendingInfo.state == UserLendingState.LIQUIDATED) return 0;

        return userLending.lendingAmount;
    }

    function getPoolSupportPids(uint256 _pid)
        public
        view
        returns (uint256[] memory)
    {
        PoolInfo storage pool = poolInfo[_pid];

        return pool.supportPids;
    }

    function getCurveCoinId(uint256 _pid, uint256 _supportPid)
        public
        view
        returns (int128)
    {
        PoolInfo storage pool = poolInfo[_pid];

        return pool.curveCoinIds[_supportPid];
    }

    function getUserLendingState(bytes32 _lendingId)
        public
        view
        returns (UserLendingState)
    {
        LendingInfo storage lendingInfo = lendings[_lendingId];

        return lendingInfo.state;
    }

    function getLendingInfo(
        uint256 _token0,
        uint256 _convexPid,
        int128 _curveCoinId,
        uint256 _supplyPid,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold,
        uint256 _borrowBlocks
    ) public view returns (LendingParams memory) {
        (address lpToken, uint256 token0Price) = _getCurveInfo(
            _convexPid,
            _curveCoinId,
            _token0
        );

        uint256 utilizationRate = ISupplyBooster(supplyBooster)
            .getUtilizationRate(_supplyPid);
        uint256 supplyRatePerBlock = ISupplyBooster(supplyBooster)
            .getBorrowRatePerBlock(_supplyPid);
        uint256 supplyRate = getSupplyRate(supplyRatePerBlock, _borrowBlocks);
        uint256 lendflareTotalRate;

        if (utilizationRate > 0) {
            lendflareTotalRate = getLendingRate(
                supplyRate,
                getAmplificationFactor(utilizationRate)
            );
        } else {
            lendflareTotalRate = supplyRate.sub(SUPPLY_RATE_DENOMINATOR);
        }

        uint256 lendingAmount = token0Price.mul(SUPPLY_RATE_DENOMINATOR);

        lendingAmount = lendingAmount.mul(
            THRESHOLD_DENOMINATOR.sub(_lendingThreshold).sub(
                _liquidateThreshold
            )
        );

        lendingAmount = lendingAmount.div(THRESHOLD_DENOMINATOR);

        uint256 repayBorrowAmount = lendingAmount.div(SUPPLY_RATE_DENOMINATOR);
        uint256 borrowAmount = lendingAmount.div(
            SUPPLY_RATE_DENOMINATOR.add(lendflareTotalRate)
        );

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

    function getUserLendingsLength(address _user)
        public
        view
        returns (uint256)
    {
        return userLendings[_user].length;
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

    function getAmplificationFactor(uint256 _utilizationRate)
        public
        pure
        returns (uint256)
    {
        if (_utilizationRate <= 0.9 * 1e18) {
            return uint256(10).mul(_utilizationRate).div(9).add(1e18);
        }

        return uint256(20).mul(_utilizationRate).sub(16 * 1e18);
    }

    // lendflare total rate
    function getLendingRate(uint256 _supplyRate, uint256 _amplificationFactor)
        public
        pure
        returns (uint256)
    {
        return _supplyRate.sub(1e18).mul(_amplificationFactor).div(1e18);
    }
}
