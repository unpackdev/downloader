// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";

import "./IAddressProvider.sol";
import "./IPriceOracleAggregator.sol";
import "./IERC20MintableBurnable.sol";

contract Farming is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 dividendsDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint256 dividendsPerShare;
    }

    /// @notice address provider
    IAddressProvider public addressProvider;

    /// @notice reward token rate
    uint256 public tokenPerBlock;

    /// @notice pool info array
    PoolInfo[] public poolInfo;

    /// @notice mapping pool => user => info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice total alloc point of all pools
    uint256 public totalAllocPoint;

    /// @notice LP pool exist
    mapping(address => bool) private isLPPoolAdded;

    uint256 public constant SHARE_MULTIPLIER = 1e12;

    /* ======== EVENTS ======== */

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(
        address indexed user,
        uint256 indexed pid,
        uint256 reward,
        uint256 dividends
    );
    event RewardPerBlockChanged(uint256 reward);

    /* ======== ERRORS ======== */

    error INVALID_ADDRESS();
    error INVALID_AMOUNT();
    error STAKING_NOT_STARTED();
    error EXCEED_DEPOSIT();
    error POOL_EXIST();
    error POOL_NOT_EXIST();

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _addressProvider,
        uint256 _tokenPerBlock
    ) external initializer {
        if (_addressProvider == address(0)) revert INVALID_ADDRESS();

        // address provider
        addressProvider = IAddressProvider(_addressProvider);

        // reward token rate
        tokenPerBlock = _tokenPerBlock;

        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        emit RewardPerBlockChanged(_tokenPerBlock);
    }

    /* ======== MODIFIER ======== */

    modifier validatePoolByPid(uint256 _pid) {
        if (_pid >= poolInfo.length) revert POOL_NOT_EXIST();

        _;
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     * @notice set address provider
     * @param _addressProvider address
     */
    function setAddressProvider(address _addressProvider) external onlyOwner {
        if (_addressProvider == address(0)) revert INVALID_ADDRESS();
        addressProvider = IAddressProvider(_addressProvider);
    }

    /**
     * @notice recover tokens
     */
    function recoverERC20(IERC20 _token) external onlyOwner {
        uint256 amount = _token.balanceOf(address(this));

        if (amount > 0) {
            _token.safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @notice recover ETH
     */
    function recoverETH() external onlyOwner {
        uint256 amount = address(this).balance;

        if (amount > 0) {
            payable(msg.sender).call{value: amount}('');
        }
    }

    /**
     * @notice pause
     */
    function pause() external onlyOwner whenNotPaused {
        return _pause();
    }

    /**
     * @notice unpause
     */
    function unpause() external onlyOwner whenPaused {
        return _unpause();
    }

    /**
     * @notice add new pool
     */
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) external onlyOwner {
        if (isLPPoolAdded[address(_lpToken)]) revert POOL_EXIST();
        isLPPoolAdded[address(_lpToken)] = true;

        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint += _allocPoint;

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: block.number,
                accTokenPerShare: 0,
                dividendsPerShare: 0
            })
        );
    }

    /**
     * @notice update existing pool
     */
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint =
            totalAllocPoint -
            (poolInfo[_pid].allocPoint) +
            (_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @notice set token reward per block
     */
    function setTokenPerBlock(uint256 _tokenPerBlock) external onlyOwner {
        if (_tokenPerBlock == 0) revert INVALID_AMOUNT();

        tokenPerBlock = _tokenPerBlock;

        emit RewardPerBlockChanged(_tokenPerBlock);
    }

    /* ======== VIEW FUNCTIONS ======== */

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPoolInfo(
        uint256 _pid
    ) external view validatePoolByPid(_pid) returns (uint256 tvl, uint256 apr) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (lpSupply > 0) {
            tvl = (_viewPriceInUSD(address(pool.lpToken)) * lpSupply) / 1e18;
            apr =
                (((_viewPriceInUSD(addressProvider.getOptionShezmu()) *
                    tokenPerBlock *
                    ((365 * 86400) / 12) *
                    pool.allocPoint) / totalAllocPoint) * SHARE_MULTIPLIER) /
                (_viewPriceInUSD(address(pool.lpToken)) * lpSupply);
        }
    }

    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public pure returns (uint256) {
        return _to - (_from);
    }

    /**
     * @notice get Pending Rewards of a user
     */
    function pendingToken(
        uint256 _pid,
        address _user
    )
        external
        view
        validatePoolByPid(_pid)
        returns (uint256 reward, uint256 dividends)
    {
        if (_user == address(0)) revert INVALID_ADDRESS();

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 tokenReward = (multiplier *
                (tokenPerBlock) *
                (pool.allocPoint)) / (totalAllocPoint);
            accTokenPerShare =
                accTokenPerShare +
                ((tokenReward * (SHARE_MULTIPLIER)) / (lpSupply));
        }

        reward =
            (user.amount * (accTokenPerShare)) /
            (SHARE_MULTIPLIER) -
            (user.rewardDebt);
        dividends =
            (user.amount * (pool.dividendsPerShare)) /
            (SHARE_MULTIPLIER) -
            (user.dividendsDebt);
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _viewPriceInUSD(address _token) internal view returns (uint256) {
        return
            IPriceOracleAggregator(addressProvider.getPriceOracleAggregator())
                .viewPriceInUSD(_token);
    }

    function _processRewards(uint256 _pid, address _addr) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_addr];

        uint256 reward = (user.amount * pool.accTokenPerShare) /
            SHARE_MULTIPLIER -
            user.rewardDebt;

        if (reward > 0) {
            IERC20MintableBurnable(addressProvider.getOptionShezmu()).mint(
                _addr,
                reward
            );
        }

        uint256 dividends = (user.amount * pool.dividendsPerShare) /
            SHARE_MULTIPLIER -
            user.dividendsDebt;

        if (dividends > 0) {
            payable(_addr).call{value: _min(address(this).balance, dividends)}(
                ''
            );
        }

        emit Claim(_addr, _pid, reward, dividends);
    }

    /* ======== PUBLIC FUNCTIONS ======== */

    function receiveETHForDividends() external payable nonReentrant {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 dividendsReward = (msg.value * pool.allocPoint) /
                totalAllocPoint;
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));

            if (lpSupply > 0) {
                pool.dividendsPerShare += ((dividendsReward *
                    (SHARE_MULTIPLIER)) / (lpSupply));
            }
        }
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @notice updatePool distribute pendingRewards
     */
    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = (multiplier *
            (tokenPerBlock) *
            (pool.allocPoint)) / (totalAllocPoint);
        pool.accTokenPerShare =
            pool.accTokenPerShare +
            ((tokenReward * (SHARE_MULTIPLIER)) / (lpSupply));
        pool.lastRewardBlock = block.number;
    }

    /**
     * @notice deposit token
     */
    function deposit(
        uint256 _pid,
        uint256 _amount
    ) external nonReentrant whenNotPaused validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        if (user.amount > 0) {
            _processRewards(_pid, msg.sender);
        }

        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount += _amount;
        }
        user.rewardDebt =
            (user.amount * (pool.accTokenPerShare)) /
            (SHARE_MULTIPLIER);
        user.dividendsDebt =
            (user.amount * (pool.dividendsPerShare)) /
            (SHARE_MULTIPLIER);

        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @notice withdraw token
     */
    function withdraw(
        uint256 _pid,
        uint256 _amount
    ) external nonReentrant whenNotPaused validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amount < _amount) revert EXCEED_DEPOSIT();

        updatePool(_pid);

        if (user.amount > 0) {
            _processRewards(_pid, msg.sender);
        }

        if (_amount > 0) {
            user.amount -= _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt =
            (user.amount * pool.accTokenPerShare) /
            SHARE_MULTIPLIER;
        user.dividendsDebt =
            (user.amount * (pool.dividendsPerShare)) /
            (SHARE_MULTIPLIER);

        emit Withdraw(msg.sender, _pid, _amount);
    }
}
