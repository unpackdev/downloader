// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./ConvexInterfacesV2.sol";
import "./IVirtualBalanceWrapper.sol";

contract ConvexBoosterV2 is Initializable, ReentrancyGuard, IConvexBoosterV2 {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // https://curve.readthedocs.io/registry-address-provider.html
    ICurveAddressProvider public curveAddressProvider;

    address private constant ZERO_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public convexRewardFactory;
    address public virtualBalanceWrapperFactory;
    address public originConvexBooster;
    address public rewardCrvToken;
    address public rewardCvxToken;
    uint256 public version;

    address public lendingMarket;
    address public owner;
    address public governance;

    struct PoolInfo {
        uint256 originConvexPid;
        address curveSwapAddress; /* like 3pool https://github.com/curvefi/curve-js/blob/master/src/constants/abis/abis-ethereum.ts */
        address lpToken;
        address originCrvRewards;
        address originStash;
        address virtualBalance;
        address rewardCrvPool;
        address rewardCvxPool;
        bool shutdown;
    }

    struct MetaPoolInfo {
        address swapAddress;
        address zapAddress;
        address basePoolAddress;
        bool isMeta;
        bool isMetaFactory;
    }

    struct MovingLeverage {
        uint256 prev;
        uint256 origin;
    }

    PoolInfo[] public override poolInfo;

    mapping(uint256 => mapping(address => uint256)) public frozenTokens; // pid => (user => amount)
    mapping(address => MetaPoolInfo) public metaPoolInfo;
    mapping(uint256 => mapping(int128 => MovingLeverage)) public movingLeverages; // pid =>(coin id => MovingLeverage)

    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);
    event Initialized(address indexed thisAddress);
    event ToggleShutdownPool(uint256 pid, bool shutdown);
    event SetOwner(address owner);
    event SetGovernance(address governance);
    event CurveZap(address lpToken, address curveZapAddress);
    event SetLendingMarket(address lendingMarket);
    event AddConvexPool(uint256 originConvexPid, address lpToken, address curveSwapAddress);
    event RemoveLiquidity(address lpToken, address curveSwapAddress, uint256 amount, int128 coinId);
    event ClaimRewardToken(uint256 pid, bool remarkTag);
    event SetOriginMovingLeverage(uint256 pid, int128 curveCoinId, uint256 base, uint256 current, uint256 blockNumber);
    event UpdateMovingLeverage(uint256 pid, int128 curveCoinId, uint256 prev, uint256 current);
    event UpgradeRewards(uint256 pid, address oldRewardCrvPool, address newRewardCrvPool, address extraRewardToken, address extraRewardPool);

    modifier onlyOwner() {
        require(owner == msg.sender, "ConvexBooster: caller is not the owner");
        _;
    }

    modifier onlyGovernance() {
        require(governance == msg.sender, "ConvexBooster: caller is not the governance");
        _;
    }

    modifier onlyLendingMarket() {
        require(lendingMarket == msg.sender, "ConvexBooster: caller is not the lendingMarket");

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

    function setLendingMarket(address _v) public onlyOwner {
        require(_v != address(0), "!_v");

        lendingMarket = _v;

        emit SetLendingMarket(lendingMarket);
    }

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() public initializer {}

    function initialize(
        address _owner,
        address _originConvexBooster,
        address _convexRewardFactory,
        address _virtualBalanceWrapperFactory,
        address _rewardCrvToken,
        address _rewardCvxToken
    ) public initializer {
        owner = _owner;
        governance = _owner;
        convexRewardFactory = _convexRewardFactory;
        originConvexBooster = _originConvexBooster;
        virtualBalanceWrapperFactory = _virtualBalanceWrapperFactory;
        rewardCrvToken = _rewardCrvToken;
        rewardCvxToken = _rewardCvxToken;
        version = 1;

        curveAddressProvider = ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);

        emit Initialized(address(this));
    }

    function _addConvexPool(
        uint256 _originConvexPid,
        address _lpToken,
        address _originCrvRewards,
        address _originStash,
        address _curveSwapAddress
    ) internal {
        address virtualBalance = IVirtualBalanceWrapperFactory(virtualBalanceWrapperFactory).createWrapper(address(this));
        address rewardCrvPool = IConvexRewardFactoryV2(convexRewardFactory).createReward(rewardCrvToken, virtualBalance, address(this), address(this));
        address rewardCvxPool = IConvexRewardFactoryV2(convexRewardFactory).createReward(rewardCvxToken, virtualBalance, address(this), address(this));
        uint256 extraRewardsLength = IOriginConvexRewardPool(_originCrvRewards).extraRewardsLength();

        for (uint256 i = 0; i < extraRewardsLength; i++) {
            address extraReward = IOriginConvexRewardPool(_originCrvRewards).extraRewards(i);
            address extraRewardPool = IConvexRewardFactoryV2(convexRewardFactory).createReward(
                IOriginConvexRewardPool(extraReward).rewardToken(),
                virtualBalance,
                rewardCrvPool,
                address(this)
            );

            IConvexRewardPool(rewardCrvPool).addExtraReward(extraRewardPool);
        }

        poolInfo.push(
            PoolInfo({
                originConvexPid: _originConvexPid,
                curveSwapAddress: _curveSwapAddress,
                lpToken: _lpToken,
                originCrvRewards: _originCrvRewards,
                originStash: _originStash,
                virtualBalance: virtualBalance,
                rewardCrvPool: rewardCrvPool,
                rewardCvxPool: rewardCvxPool,
                shutdown: false
            })
        );

        emit AddConvexPool(_originConvexPid, _lpToken, _curveSwapAddress);
    }

    function addConvexPool(uint256 _originConvexPid) public override onlyGovernance {
        (address lpToken, , , address originCrvRewards, address originStash, bool shutdown) = IOriginConvexBooster(originConvexBooster).poolInfo(
            _originConvexPid
        );

        require(!shutdown, "!shutdown");
        require(lpToken != address(0), "!lpToken");

        ICurveRegistry registry = ICurveRegistry(ICurveAddressProvider(curveAddressProvider).get_registry());

        address curveSwapAddress = registry.get_pool_from_lp_token(lpToken);

        _addConvexPool(_originConvexPid, lpToken, originCrvRewards, originStash, curveSwapAddress);
    }

    // Reference https://curve.readthedocs.io/ref-addresses.html?highlight=zap#deposit-zaps
    function addConvexPool(
        uint256 _originConvexPid,
        address _curveSwapAddress,
        address _curveZapAddress,
        address _basePoolAddress,
        bool _isMeta,
        bool _isMetaFactory
    ) public override onlyGovernance {
        require(_curveSwapAddress != address(0), "!_curveSwapAddress");
        require(_curveZapAddress != address(0), "!_curveZapAddress");
        require(_basePoolAddress != address(0), "!_basePoolAddress");

        (address lpToken, , , address originCrvRewards, address originStash, bool shutdown) = IOriginConvexBooster(originConvexBooster).poolInfo(
            _originConvexPid
        );

        require(!shutdown, "!shutdown");
        require(lpToken != address(0), "!lpToken");

        metaPoolInfo[lpToken] = MetaPoolInfo(_curveSwapAddress, _curveZapAddress, _basePoolAddress, _isMeta, _isMetaFactory);

        _addConvexPool(_originConvexPid, lpToken, originCrvRewards, originStash, _curveSwapAddress);

        emit CurveZap(lpToken, _curveZapAddress);
    }

    function toggleShutdownPool(uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        pool.shutdown = !pool.shutdown;

        emit ToggleShutdownPool(_pid, pool.shutdown);
    }

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) public override onlyLendingMarket nonReentrant returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        claimRewardToken(_pid);

        IERC20(pool.lpToken).safeTransferFrom(msg.sender, address(this), _amount);

        /* (
            address lpToken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        ) */
        (, , , , , bool shutdown) = IOriginConvexBooster(originConvexBooster).poolInfo(pool.originConvexPid);

        require(!shutdown, "!convex shutdown");
        require(!pool.shutdown, "!shutdown");

        IERC20(pool.lpToken).safeApprove(originConvexBooster, 0);
        IERC20(pool.lpToken).safeApprove(originConvexBooster, _amount);

        IOriginConvexBooster(originConvexBooster).deposit(pool.originConvexPid, _amount, true);

        IConvexRewardPool(pool.rewardCrvPool).stake(_user);
        IConvexRewardPool(pool.rewardCvxPool).stake(_user);

        IVirtualBalanceWrapper(pool.virtualBalance).stakeFor(_user, _amount);

        emit Deposited(_user, _pid, _amount);

        return true;
    }

    function withdrawFrozenTokens(uint256 _pid, uint256 _amount) public nonReentrant {
        require(_amount > 0, "!_amount");

        PoolInfo storage pool = poolInfo[_pid];

        frozenTokens[_pid][msg.sender] = frozenTokens[_pid][msg.sender].sub(_amount);

        IOriginConvexRewardPool(pool.originCrvRewards).withdrawAndUnwrap(_amount, true);

        IERC20(pool.lpToken).safeTransfer(msg.sender, _amount);
    }

    function withdrawFor(
        uint256 _pid,
        uint256 _amount,
        address _user,
        bool _frozenTokens
    ) public override onlyLendingMarket nonReentrant returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        if (_frozenTokens) {
            frozenTokens[_pid][_user] = frozenTokens[_pid][_user].add(_amount);
        } else {
            IOriginConvexRewardPool(pool.originCrvRewards).withdrawAndUnwrap(_amount, true);

            IERC20(pool.lpToken).safeTransfer(_user, _amount);
        }

        if (IConvexRewardPool(pool.rewardCrvPool).earned(_user) > 0) {
            IConvexRewardPool(pool.rewardCrvPool).getReward(_user);
        }

        if (IConvexRewardPool(pool.rewardCvxPool).earned(_user) > 0) {
            IConvexRewardPool(pool.rewardCvxPool).getReward(_user);
        }

        IVirtualBalanceWrapper(pool.virtualBalance).withdrawFor(_user, _amount);

        IConvexRewardPool(pool.rewardCrvPool).withdraw(_user);
        IConvexRewardPool(pool.rewardCvxPool).withdraw(_user);

        emit Withdrawn(_user, _pid, _amount);

        return true;
    }

    function _removeLiquidity(
        address _lpToken,
        address _curveSwapAddress,
        uint256 _amount,
        int128 _coinId
    ) internal {
        if (metaPoolInfo[_lpToken].zapAddress != address(0)) {
            if (metaPoolInfo[_lpToken].isMetaFactory) {
                IERC20(_lpToken).safeApprove(metaPoolInfo[_lpToken].zapAddress, 0);
                IERC20(_lpToken).safeApprove(metaPoolInfo[_lpToken].zapAddress, _amount);

                ICurveSwapV2(metaPoolInfo[_lpToken].zapAddress).remove_liquidity_one_coin(metaPoolInfo[_lpToken].swapAddress, _amount, _coinId, 0);

                emit RemoveLiquidity(_lpToken, _curveSwapAddress, _amount, _coinId);

                return;
            }
        }

        IERC20(_lpToken).safeApprove(_curveSwapAddress, 0);
        IERC20(_lpToken).safeApprove(_curveSwapAddress, _amount);

        ICurveSwapV2(_curveSwapAddress).remove_liquidity_one_coin(_amount, _coinId, 0);

        emit RemoveLiquidity(_lpToken, _curveSwapAddress, _amount, _coinId);
    }

    function _liquidate(
        uint256 _pid,
        int128 _coinId,
        address _user,
        uint256 _amount,
        address _recipient
    ) internal returns (address, uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        IOriginConvexRewardPool(pool.originCrvRewards).withdrawAndUnwrap(_amount, true);

        if (_user != address(0)) {
            if (IConvexRewardPool(pool.rewardCrvPool).earned(_user) > 0) {
                IConvexRewardPool(pool.rewardCrvPool).getReward(_user);
            }

            if (IConvexRewardPool(pool.rewardCvxPool).earned(_user) > 0) {
                IConvexRewardPool(pool.rewardCvxPool).getReward(_user);
            }

            IVirtualBalanceWrapper(pool.virtualBalance).withdrawFor(_user, _amount);

            IConvexRewardPool(pool.rewardCrvPool).withdraw(_user);
            IConvexRewardPool(pool.rewardCvxPool).withdraw(_user);
        }

        address underlyToken;

        if (metaPoolInfo[pool.lpToken].zapAddress != address(0)) {
            if (
                metaPoolInfo[pool.lpToken].swapAddress == metaPoolInfo[pool.lpToken].basePoolAddress ||
                (!metaPoolInfo[pool.lpToken].isMeta && !metaPoolInfo[pool.lpToken].isMetaFactory) ||
                _coinId == 0
            ) {
                underlyToken = _coins(pool.curveSwapAddress, _coinId);
            } else {
                underlyToken = _coins(metaPoolInfo[pool.lpToken].basePoolAddress, _coinId - 1);
            }
        } else {
            underlyToken = _coins(pool.curveSwapAddress, _coinId);
        }

        _removeLiquidity(pool.lpToken, pool.curveSwapAddress, _amount, _coinId);

        if (underlyToken == ZERO_ADDRESS) {
            uint256 totalAmount = address(this).balance;

            payable(_recipient).sendValue(totalAmount);

            return (ZERO_ADDRESS, totalAmount);
        } else {
            uint256 totalAmount = IERC20(underlyToken).balanceOf(address(this));

            IERC20(underlyToken).safeTransfer(_recipient, totalAmount);

            return (underlyToken, totalAmount);
        }
    }

    function depeg(
        uint256 _pid,
        uint256 _amount,
        int128 _coinId,
        address _recipient
    ) external override onlyLendingMarket nonReentrant returns (address, uint256) {
        return _liquidate(_pid, _coinId, address(0), _amount, _recipient);
    }

    function liquidate(
        uint256 _pid,
        int128 _coinId,
        address _user,
        uint256 _amount
    ) external override onlyLendingMarket nonReentrant returns (address, uint256) {
        return _liquidate(_pid, _coinId, _user, _amount, msg.sender);
    }

    function getRewards(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];

        if (IConvexRewardPool(pool.rewardCrvPool).earned(msg.sender) > 0) {
            IConvexRewardPool(pool.rewardCrvPool).getReward(msg.sender);
        }

        if (IConvexRewardPool(pool.rewardCvxPool).earned(msg.sender) > 0) {
            IConvexRewardPool(pool.rewardCvxPool).getReward(msg.sender);
        }
    }

    function claimRewardToken(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (pool.shutdown) return;

        // If convex updates the extra contract, we need remark contract.
        bool remarkTag = false;
        uint256 extraRewardsLength = IConvexRewardPool(pool.rewardCrvPool).extraRewardsLength();
        uint256 originExtraRewardsLength = IOriginConvexRewardPool(pool.originCrvRewards).extraRewardsLength();

        if (extraRewardsLength == originExtraRewardsLength) {
            IOriginConvexRewardPool(pool.originCrvRewards).getReward(address(this), true);

            for (uint256 i = 0; i < extraRewardsLength; i++) {
                address currentExtraReward = IConvexRewardPool(pool.rewardCrvPool).extraRewards(i);
                address originExtraReward = IOriginConvexRewardPool(pool.originCrvRewards).extraRewards(i);
                address originExtraRewardToken = IOriginConvexVirtualBalanceRewardPool(originExtraReward).rewardToken();

                IOriginConvexVirtualBalanceRewardPool(originExtraReward).getReward(address(this));

                uint256 extraBalance = IERC20(originExtraRewardToken).balanceOf(address(this));
                if (extraBalance > 0) {
                    IERC20(originExtraRewardToken).safeTransfer(currentExtraReward, extraBalance);
                    IConvexRewardPool(currentExtraReward).notifyRewardAmount(extraBalance);
                }
            }
        } else {
            remarkTag = true;
            IOriginConvexRewardPool(pool.originCrvRewards).getReward(address(this), false);
        }

        uint256 crvBalance = IERC20(rewardCrvToken).balanceOf(address(this));

        if (crvBalance > 0) {
            IERC20(rewardCrvToken).safeTransfer(pool.rewardCrvPool, crvBalance);

            IConvexRewardPool(pool.rewardCrvPool).notifyRewardAmount(crvBalance);
        }

        /* cvx */
        uint256 cvxBal = IERC20(rewardCvxToken).balanceOf(address(this));

        if (cvxBal > 0) {
            IERC20(rewardCvxToken).safeTransfer(pool.rewardCvxPool, cvxBal);

            IConvexRewardPool(pool.rewardCvxPool).notifyRewardAmount(cvxBal);
        }

        emit ClaimRewardToken(_pid, remarkTag);
    }

    function claimAllRewardToken() public {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            claimRewardToken(i);
        }
    }

    function remarkRewards(address[] calldata _oldCrvPools, uint256[] calldata _pids) public {
        require(_oldCrvPools.length >= _pids.length, "!_oldCrvPools");

        for (uint256 i = 0; i < _pids.length; i++) {
            PoolInfo storage pool = poolInfo[_pids[i]];

            address currentOldCrvPools = _oldCrvPools[_pids[i]];

            if (pool.rewardCrvPool != currentOldCrvPools) {
                if (IConvexRewardPool(currentOldCrvPools).earned(msg.sender) > 0) {
                    IConvexRewardPool(currentOldCrvPools).getReward(msg.sender);
                }

                IConvexRewardPool(currentOldCrvPools).withdraw(msg.sender);
                IConvexRewardPoolV2(pool.rewardCrvPool).stake(msg.sender);
            }
        }
    }

    function upgradeRewards(uint256[] calldata _pids) public onlyOwner {
        for (uint256 i = 0; i < _pids.length; i++) {
            PoolInfo storage pool = poolInfo[_pids[i]];

            address oldRewardCrvPool = pool.rewardCrvPool;
            address newRewardCrvPool = IConvexRewardFactoryV2(convexRewardFactory).createReward(
                rewardCrvToken,
                pool.virtualBalance,
                address(this),
                address(this)
            );

            pool.rewardCrvPool = newRewardCrvPool;

            uint256 extraRewardsLength = IOriginConvexRewardPool(pool.originCrvRewards).extraRewardsLength();

            for (uint256 j = 0; j < extraRewardsLength; j++) {
                address extraReward = IOriginConvexRewardPool(pool.originCrvRewards).extraRewards(j);
                address extraRewardPool = IConvexRewardFactoryV2(convexRewardFactory).createReward(
                    IOriginConvexRewardPool(extraReward).rewardToken(),
                    pool.virtualBalance,
                    newRewardCrvPool,
                    address(this)
                );

                IConvexRewardPool(newRewardCrvPool).addExtraReward(extraRewardPool);

                emit UpgradeRewards(_pids[i], oldRewardCrvPool, newRewardCrvPool, extraReward, extraRewardPool);
            }
        }
    }

    function updateMovingLeverage(
        uint256 _pid,
        uint256 _amounts,
        int128 _curveCoinId
    ) public override onlyLendingMarket returns (uint256) {
        MovingLeverage storage movingLeverage = movingLeverages[_pid][_curveCoinId];

        uint256 amount = calculateTokenAmount(_pid, _amounts, _curveCoinId);
        uint256 current = amount.mul(1e18).div(_amounts);

        if (0 == movingLeverage.origin) {
            movingLeverage.origin = IMovingLeverageBase(0xd132C63A09fccfeF56b88c5ACa8Ecbb63F814A46).get(_pid, _curveCoinId);
        }

        require(movingLeverage.origin > 0, "!Origin need to update");

        uint256 originScalePercent = getMovingLeverageScale(movingLeverage.origin, current);

        originScalePercent = originScalePercent.mul(1000).div(1e18);

        // <= 10%
        require(originScalePercent <= 100, "!Origin scale exceeded");

        if (movingLeverage.prev > 0) {
            uint256 prevScalePercent = getMovingLeverageScale(movingLeverage.prev, current);

            prevScalePercent = prevScalePercent.mul(1000).div(1e18);

            // <= 5%
            require(prevScalePercent <= 50, "!Prev scale exceeded");
        }

        movingLeverage.prev = current;

        emit UpdateMovingLeverage(_pid, _curveCoinId, movingLeverage.prev, current);

        return amount;
    }

    function setOriginMovingLeverage(
        uint256 _pid,
        uint256 _tokens,
        int128 _curveCoinId
    ) public onlyOwner {
        require(_tokens >= 10e18, "!Tokens is too small");

        MovingLeverage storage movingLeverage = movingLeverages[_pid][_curveCoinId];

        uint256 amount = calculateTokenAmount(_pid, _tokens, _curveCoinId);

        uint256 oldLeverage = movingLeverage.origin;
        uint256 newLeverage = amount.mul(1e18).div(_tokens);

        movingLeverage.origin = newLeverage;

        emit SetOriginMovingLeverage(_pid, _curveCoinId, oldLeverage, newLeverage, block.timestamp);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /* view functions */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPoolToken(uint256 _pid) external view override returns (address) {
        PoolInfo storage pool = poolInfo[_pid];

        return pool.lpToken;
    }

    function getPoolTotalSupply(uint256 _pid) external view override returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        return IVirtualBalanceWrapper(pool.virtualBalance).totalSupply();
    }

    function getPoolZapAddress(address _lpToken) external view override returns (address) {
        return metaPoolInfo[_lpToken].zapAddress;
    }

    function _coins(address _swapAddress, int128 _coinId) internal view returns (address) {
        // curve v1 base pool
        address susd = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
        address sbtc = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
        address ren = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;

        if (_swapAddress == susd || _swapAddress == sbtc || _swapAddress == ren) {
            return ICurveSwapV2(_swapAddress).coins(_coinId);
        }

        return ICurveSwapV2(_swapAddress).coins(uint256(_coinId));
    }

    function getMovingLeverageScale(uint256 _base, uint256 _current) internal pure returns (uint256) {
        if (_base >= _current) {
            return _base.sub(_current).mul(1e18).div(_base);
        }

        return _current.sub(_base).mul(1e18).div(_base);
    }

    function calculateTokenAmount(
        uint256 _pid,
        uint256 _tokens,
        int128 _curveCoinId
    ) public view override returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        if (metaPoolInfo[pool.lpToken].zapAddress != address(0)) {
            if (metaPoolInfo[pool.lpToken].isMetaFactory) {
                return ICurveSwapV2(metaPoolInfo[pool.lpToken].zapAddress).calc_withdraw_one_coin(pool.curveSwapAddress, _tokens, _curveCoinId);
            }

            return ICurveSwapV2(metaPoolInfo[pool.lpToken].zapAddress).calc_withdraw_one_coin(_tokens, _curveCoinId);
        }

        return ICurveSwapV2(pool.curveSwapAddress).calc_withdraw_one_coin(_tokens, _curveCoinId);
    }
}
