// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./INonfungiblePositionManager.sol";
import "./IERC721Receiver.sol";
import "./SafeERC20.sol";
import "./RewardsBoosterErrors.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./IRewardsBooster.sol";
import "./IValidator.sol";
import "./ITicket.sol";
import "./IValuer.sol";
import "./IOracle.sol";
import "./BuybackV2.sol";
import "./IWETH.sol";

/**
 * @title Asymetrix Protocol V2 RewardsBoosterV2
 * @author Asymetrix Protocol Inc Team
 * @notice A contract where users can create locks (positions) to boost their incentivization rewards in the
 *         StakePrizePool contract. This contract supports Balancer Weighted pools and Uniswap V3 pools.
 */
contract RewardsBoosterV2 is BuybackV2, IRewardsBooster, IERC721Receiver {
    using SafeERC20 for IERC20;

    mapping(uint8 => Pool) private pools;
    mapping(uint8 => mapping(uint8 => LockDurationSettings)) private lockDurationSettings;
    mapping(uint8 => mapping(address => User)) private users;
    mapping(uint8 => mapping(address => Lock[])) private locks;
    mapping(address => uint256) private stakeTokens;
    ITicket private ticket;
    IOracle private stEthOracle;
    INonfungiblePositionManager private nonfungiblePositionManager;
    uint16 private minBoostThreshold;
    uint16 private maxBoostThreshold;
    uint16 private maxBoost;
    uint8 private poolsNumber;

    uint8 public constant MAX_LOCKS_NUMBER = 10;

    uint256 private constant STAKE_TOKEN = 1;

    uint256 private constant NON_FUNGIBLE = 0;
    uint256 private constant FUNGIBLE = 1;

    /**
     * @notice Checks if staking pool exists.
     * @param _pid Staking pool ID which to check for existence.
     */
    modifier onlyExistingPool(uint8 _pid) {
        if (_pid >= poolsNumber) revert RewardsBoosterErrors.NotExistingPool();
        _;
    }

    /**
     * @notice Checks if lock (position) exists for the user in the specified staking pool.
     * @param _pid Staking pool ID where to check lock (position) existence.
     * @param _user A user for whom to check lock (position) existence.
     * @param _lid An ID of the lock (position) which to check for existence.
     */
    modifier onlyExistingLock(
        uint8 _pid,
        address _user,
        uint8 _lid
    ) {
        if (_lid >= uint8(locks[_pid][_user].length) || !locks[_pid][_user][_lid].isInitialized)
            revert RewardsBoosterErrors.NotExistingLock();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the RewardsBooster V2 contract.
     * @param _name Name of the contract [EIP712].
     * @param _version Version of the contract [EIP712].
     * @param _priceSupplier Address of the price supplier.
     */
    function initializeV2(
        string calldata _name,
        string calldata _version,
        address _priceSupplier
    ) external reinitializer(2) {
        __Buyback_init_V2(_name, _version, _priceSupplier);
    }

    /**
     * @notice Allows this contract to receive native token (ETH).
     */
    receive() external payable {}

    /**
     * @notice Accepts deposits (ERC-20 LP or ERC-721 NFT positions) of an authorized pool from users and stakes them in
     *         the contract in the specified staking pool to boost rewards of esASX in the StakePrizePoolV2.
     * @param _amountOrId An amount of ERC-20 LP tokens (or ERC-721 NFT position ID) to stake.
     * @param _lockDuration A duration (in seconds) for the lock of the position.
     */
    function stake(uint8 _pid, uint256 _amountOrId, uint32 _lockDuration) external onlyExistingPool(_pid) {
        Pool memory _pool = pools[_pid];

        IValidator(_pool.validator).validateStake(_pid, _amountOrId);

        if (_lockDuration < _pool.minLockDuration || _lockDuration > _pool.maxLockDuration)
            revert RewardsBoosterErrors.WrongLockDurtion();

        uint8 _lid;
        Lock memory _lock;

        if (users[_pid][msg.sender].initializedLocksNumber == MAX_LOCKS_NUMBER)
            revert RewardsBoosterErrors.NoEmptySlotsInThisPool();

        uint8 _locksLength = uint8(locks[_pid][msg.sender].length);

        if (_locksLength < MAX_LOCKS_NUMBER) {
            _lid = _locksLength;
            _lock = _pushLock(_pid, _lid, _amountOrId, _lockDuration, true);
        } else {
            for (; _lid < MAX_LOCKS_NUMBER; ++_lid) {
                if (!locks[_pid][msg.sender][_lid].isInitialized) {
                    _lock = _pushLock(_pid, _lid, _amountOrId, _lockDuration, false);

                    break;
                }
            }
        }

        if (_pool.isFungible == FUNGIBLE) {
            IERC20(_pool.stakeToken).safeTransferFrom(msg.sender, address(this), _amountOrId);
        } else {
            IERC721(_pool.stakeToken).safeTransferFrom(msg.sender, address(this), _amountOrId);
        }

        emit LockCreated(_pid, msg.sender, _lid, _lock);
    }

    /**
     * @notice Unstakes users' deposits (ERC-20 LP or ERC-721 NFT positions) from the specified staking pool and returns
     *         them to users. Additionally, collects fees from Uniswap V3 ASX/WETH locks (psotions), unwraps WETH, swaps
     *         ETH for ASX, and burns all ASX.
     * @param _pid Staking pool ID where to unstake.
     * @param _lid An ID of the lock (position) which to unstake.
     * @param _asxPriceInEthOffchain An offchain ASX price in ETH.
     * @param _signature Signature of the price by price supplier address.
     */
    function unstake(
        uint8 _pid,
        uint8 _lid,
        uint256 _asxPriceInEthOffchain,
        bytes calldata _signature
    ) external onlyExistingPool(_pid) onlyExistingLock(_pid, msg.sender, _lid) {
        Lock memory _lock = locks[_pid][msg.sender][_lid];

        if (!_isFinishedLock(_lock)) revert RewardsBoosterErrors.LockIsNotFinished();

        Pool memory _pool = pools[_pid];

        if (_pool.stakeToken == address(nonfungiblePositionManager)) {
            uint256[] memory _ids = new uint256[](1);

            _ids[0] = _lock.amountOrId;

            buybackAndBurnAsx(_ids, _asxPriceInEthOffchain, _signature);
        }

        delete locks[_pid][msg.sender][_lid];

        --users[_pid][msg.sender].initializedLocksNumber;

        if (_pool.isFungible == FUNGIBLE) {
            IERC20(_pool.stakeToken).safeTransfer(msg.sender, _lock.amountOrId);
        } else {
            IERC721(_pool.stakeToken).safeTransferFrom(address(this), msg.sender, _lock.amountOrId);
        }

        emit LockClosed(_pid, msg.sender, _lid);
    }

    /**
     * @notice Extends a lock duration for the position where the lock was already finished. Only the lock (position)
     *         creator can extend its lock duration. Additionally, collects fees from Uniswap V3 ASX/WETH locks
     *         (psotions), unwraps WETH, swaps ETH for ASX, and burns all ASX.
     * @param _pid Staking pool ID where to extend a lock duration for the position.
     * @param _lid An ID of the lock (position) where to extend a lock duration.
     * @param _newLockDuration A new duration (in seconds) for the lock of the position.
     * @param _asxPriceInEthOffchain An offchain ASX price in ETH.
     * @param _signature Signature of the price by price supplier address.
     */
    function extendLock(
        uint8 _pid,
        uint8 _lid,
        uint32 _newLockDuration,
        uint256 _asxPriceInEthOffchain,
        bytes calldata _signature
    ) external onlyExistingPool(_pid) onlyExistingLock(_pid, msg.sender, _lid) {
        Pool memory _pool = pools[_pid];

        if (_newLockDuration < _pool.minLockDuration || _newLockDuration > _pool.maxLockDuration)
            revert RewardsBoosterErrors.WrongLockDurtion();

        Lock memory _lock = locks[_pid][msg.sender][_lid];

        if (!_isFinishedLock(_lock)) revert RewardsBoosterErrors.LockIsNotFinished();

        if (pools[_pid].stakeToken == address(nonfungiblePositionManager)) {
            uint256[] memory _ids = new uint256[](1);

            _ids[0] = _lock.amountOrId;

            buybackAndBurnAsx(_ids, _asxPriceInEthOffchain, _signature);
        }

        locks[_pid][msg.sender][_lid].duration = _newLockDuration;
        locks[_pid][msg.sender][_lid].updatedAt = uint32(block.timestamp);

        emit LockExtended(_pid, msg.sender, _lid, _newLockDuration);
    }

    /**
     * @notice Creates a new staking pool by an owner.
     * @param _stakeToken Token address to stake in the staking pool.
     * @param _stakeTokenValuer Valuer for the staked token.
     * @param _liquidityPool Liquidity pool where liquidity is stored.
     * @param _validator Validator whose main role is to execute different validations in time of stakes and unstakes.
     * @param _isFungible Indicates if staking pool accepts fungible ERC-20 or non fungible ERC-721 tokens.
     * @param _lockDurationSettings An array with LockDurationSettings structures which will be applied additionally to
     *                              users' lock durations coefficients.
     * @return Newly created staking pool ID.
     */
    function createPool(
        address _stakeToken,
        address _stakeTokenValuer,
        address _liquidityPool,
        address _validator,
        bool _isFungible,
        LockDurationSettings[] memory _lockDurationSettings
    ) external onlyOwner returns (uint256) {
        _onlyContract(_stakeToken);
        _onlyContract(_stakeTokenValuer);
        _onlyContract(_liquidityPool);
        _onlyContract(_validator);

        uint8 _pid = poolsNumber;

        pools[_pid] = Pool({
            isFungible: _isFungible ? FUNGIBLE : NON_FUNGIBLE,
            stakeToken: _stakeToken,
            stakeTokenValuer: _stakeTokenValuer,
            liquidityPool: _liquidityPool,
            validator: _validator,
            minLockDuration: 0,
            maxLockDuration: 0,
            lockDurationSettingsNumber: 0
        });

        _setLockDurationSettings(_pid, _lockDurationSettings);

        stakeTokens[_stakeToken] = STAKE_TOKEN;
        ++poolsNumber;

        emit PoolCreated(_pid, pools[_pid]);

        return _pid;
    }

    /**
     * @notice Sets a new Ticket contract by an owner.
     * @param _newTicket A new Ticket contract address.
     */
    function setTicket(address _newTicket) external onlyOwner {
        _setTicket(_newTicket);
    }

    /**
     * @notice Sets a new oracle for stETH token by an owner.
     * @param _newStEthOracle A new oracle for stETH token.
     */
    function setStEthOracle(address _newStEthOracle) external onlyOwner {
        _setStEthOracle(_newStEthOracle);
    }

    /**
     * @notice Sets a new NonfungiblePositionManager contract by an owner.
     * @param _newNonfungiblePositionManager A new NonfungiblePositionManager contract address.
     */
    function setNonfungiblePositionManager(address _newNonfungiblePositionManager) external onlyOwner {
        _setNonfungiblePositionManager(_newNonfungiblePositionManager);
    }

    /**
     * @notice Sets a new minimum boost threshold by an owner.
     * @param _newMinBoostThreshold A threshold (in %) that all of the user's locks (positions) together must overcome
     *                              for a boost to be awarded during a rewards claim on the StakePrizePool contract.
     */
    function setMinBoostThreshold(uint16 _newMinBoostThreshold) external onlyOwner {
        _setMinBoostThreshold(_newMinBoostThreshold);
    }

    /**
     * @notice Sets a new maximum boost threshold by an owner.
     * @param _newMaxBoostThreshold A threshold (in %) that all of the user's locks (positions) together must achieve to
     *                              get the maximum boost during a rewards claim on the StakePrizePool contract.
     */
    function setMaxBoostThreshold(uint16 _newMaxBoostThreshold) external onlyOwner {
        _setMaxBoostThreshold(_newMaxBoostThreshold);
    }

    /**
     * @notice Sets a new maximum possible boost coefficient by an owner.
     * @param _newMaxBoost A new maximum possible boost coefficient that is used when lock (position) is created by a
     *                     user.
     */
    function setMaxBoost(uint16 _newMaxBoost) external onlyOwner {
        _setMaxBoost(_newMaxBoost);
    }

    /**
     * @notice Sets a new valuer for the stake token in the specified staking pool.
     * @param _pid Staking pool ID where to set new stake token valuer.
     * @param _newStakeTokenValuer A new valuer for the stake token in the staking pool.
     */
    function setStakeTokenValuer(uint8 _pid, address _newStakeTokenValuer) external onlyOwner onlyExistingPool(_pid) {
        _onlyContract(_newStakeTokenValuer);

        pools[_pid].stakeTokenValuer = _newStakeTokenValuer;
    }

    /**
     * @notice Sets a new validator in the specified staking pool by an owner.
     * @param _pid Staking pool ID where to set new validator.
     * @param _newValidator A new validator whose main role is to execute different validations in time of stakes and
     *                      unstakes.
     */
    function setValidator(uint8 _pid, address _newValidator) external onlyOwner onlyExistingPool(_pid) {
        _onlyContract(_newValidator);

        pools[_pid].validator = _newValidator;
    }

    /**
     * @notice Sets a new array with LockDurationSettings structures by an owner.
     * @param _pid Staking pool ID where to set new lock duration settings.
     * @param _lockDurationSettings An array with LockDurationSettings structures which will be applied additionally to
     *                              users' lock durations coefficients.
     */
    function setLockDurationSettings(
        uint8 _pid,
        LockDurationSettings[] memory _lockDurationSettings
    ) external onlyOwner onlyExistingPool(_pid) {
        _setLockDurationSettings(_pid, _lockDurationSettings);
    }

    /**
     * @notice Rescues accidentally transferred to this contract tokens. Callable only by an owner.
     * @param _token A token address to withdraw. If equals to zero address - withdraws ETH.
     * @param _amountOrId An amount of native/ERC-20 tokens or ID of ERC-721 NFT token to withdraw.
     * @param _isFungible Indicates if token to withdraw is fungible ERC-20 token.
     * @param _recipient A recipient of withdrawn tokens.
     */
    function rescue(address _token, uint256 _amountOrId, bool _isFungible, address _recipient) external onlyOwner {
        if (_amountOrId == 0) revert RewardsBoosterErrors.ZeroAmount();
        if (_recipient == address(0)) revert RewardsBoosterErrors.ZeroAddress();

        if (_token == address(0)) {
            payable(_recipient).transfer(_amountOrId);
        } else if (stakeTokens[_token] != STAKE_TOKEN) {
            if (_isFungible) {
                IERC20(_token).safeTransfer(_recipient, _amountOrId);
            } else {
                IERC721(_token).safeTransferFrom(address(this), _recipient, _amountOrId, "");
            }
        } else {
            revert RewardsBoosterErrors.StakeTokenWithdraw();
        }

        emit Rescued(_token, _amountOrId, _isFungible, _recipient);
    }

    /**
     * @notice Collects fees from Uniswap V3 ASX/WETH pool, unwraps WETH, swaps ETH for ASX, and burns all ASX. Callable
     *         only by the owner.
     * @param _ids An array of Uniswap V3 positions (NFTs) IDs from which to collect fees.
     * @param _asxPriceInEthOffchain An offchain ASX price in ETH.
     * @param _signature Signature of the price by price supplier address.
     */
    function buybackAndBurnAsx(
        uint256[] memory _ids,
        uint256 _asxPriceInEthOffchain,
        bytes calldata _signature
    ) public {
        uint8 _length = uint8(_ids.length);
        uint256 _totalWethAmount;
        uint256 _totalAsxAmount;

        for (uint8 _i; _i < _length; ++_i) {
            (uint256 _wethAmount, uint256 _asxAmount) = _collectUniswapV3Fees(_ids[_i]);

            _totalWethAmount += _wethAmount;
            _totalAsxAmount += _asxAmount;
        }

        IWETH(weth).withdraw(_totalWethAmount);
        _buybackAndBurn(address(this).balance, _totalAsxAmount, _asxPriceInEthOffchain, _signature);
    }

    /// @inheritdoc IRewardsBooster
    function getBoostBatch(
        address[] calldata _users
    ) external view returns (uint32[] memory _coefficients, bool[] memory _eligibility) {
        _coefficients = new uint32[](_users.length);
        _eligibility = new bool[](_users.length);

        for (uint i; i < _users.length; ++i) {
            (uint32 _coefficient, bool _isEligible) = getBoost(_users[i]);

            _coefficients[i] = _coefficient;
            _eligibility[i] = _isEligible;
        }

        return (_coefficients, _eligibility);
    }

    /// @inheritdoc IRewardsBooster
    function getBoost(address _user) public view returns (uint32, bool) {
        uint8 _poolsNumber = poolsNumber;
        (uint256 _lockedLiquidityTotalValue, uint256[][] memory _lockedLiquidityValues) = _getLockedLiqudityValue(
            _user,
            _poolsNumber
        );
        uint256 _lockedStEthValue = _getLockedStEthValue(_user);

        if (_lockedLiquidityTotalValue == 0 || _lockedStEthValue == 0) return (100, false);

        uint32 _lockedLiquidityRatio = uint32((_lockedLiquidityTotalValue * ONE_HUNDRED_PERCENTS) / _lockedStEthValue);
        (uint32 _lockedLiquidityBoost, uint32 _lockDurationBoost) = _getBoost(
            _user,
            _lockedLiquidityRatio,
            _poolsNumber,
            _lockedLiquidityTotalValue,
            _lockedLiquidityValues
        );

        if (_lockedLiquidityRatio >= minBoostThreshold) {
            // Сan use boost
            return (_lockedLiquidityBoost + _lockDurationBoost, true);
        } else {
            // Сan't use boost
            return (_lockDurationBoost, false);
        }
    }

    /**
     * @notice Calculates the value (in USD) of each locked and active position of a user + the total value of all
     *         user's locked positions.
     * @param _user A user to calculate locked positions value (in USD) for.
     * @return _lockedLiquidityTotalValue A total value (in USD) of all user's locked and active positions.
     * @return _lockedLiquidityValues An array of values (in USD) for the user's staking pools and locked and active
     *                                positions in them.
     */
    function getLockedLiqudityValue(
        address _user
    ) external view returns (uint256 _lockedLiquidityTotalValue, uint256[][] memory _lockedLiquidityValues) {
        return _getLockedLiqudityValue(_user, poolsNumber);
    }

    /// @inheritdoc IRewardsBooster
    function getPoolInfo(uint8 _pid) external view returns (Pool memory) {
        return pools[_pid];
    }

    /**
     * @notice Returns all lock duration settings in the staking pool.
     * @param _pid Staking pool ID.
     * @return All lock duration settings in the staking pool.
     */
    function getLockDurationSettings(uint8 _pid) external view returns (LockDurationSettings[] memory) {
        uint8 _lockDurationSettingsNumber = pools[_pid].lockDurationSettingsNumber;
        LockDurationSettings[] memory _lockDurationSettings = new LockDurationSettings[](_lockDurationSettingsNumber);

        for (uint8 _i; _i < _lockDurationSettingsNumber; ++_i) {
            _lockDurationSettings[_i] = lockDurationSettings[_pid][_i];
        }

        return _lockDurationSettings;
    }

    /**
     * @notice Returns lock duration settings in the staking pool by their IDs.
     * @param _pid Staking pool ID.
     * @param _ldsid Lock duration settings ID.
     * @return Lock duration settings.
     */
    function getLockDurationSettings(uint8 _pid, uint8 _ldsid) external view returns (LockDurationSettings memory) {
        return lockDurationSettings[_pid][_ldsid];
    }

    /**
     * @notice Returns user info by staking pool ID and user's address.
     * @param _pid Staking pool ID.
     * @param _user User address to fetch info about.
     * @return User info.
     */
    function getUserInfo(uint8 _pid, address _user) external view returns (User memory) {
        return users[_pid][_user];
    }

    /**
     * @notice Returns lock (position) info by staking pool ID, user's address, and lock's (position's) ID.
     * @param _pid Staking pool ID.
     * @param _user User address to fetch lock (position) info about.
     * @param _lid Lock (position) ID.
     * @return Lock (position) info.
     */
    function getLockInfo(
        uint8 _pid,
        address _user,
        uint8 _lid
    ) external view onlyExistingPool(_pid) onlyExistingLock(_pid, _user, _lid) returns (Lock memory) {
        return locks[_pid][_user][_lid];
    }

    /**
     * @notice Returns info about all initialized locks (positions) by staking pool ID and user's address.
     * @param _pid Staking pool ID.
     * @param _user User address to fetch info about all initialized locks (positions).
     * @return _locks Info about all initialized locks (positions) by staking pool ID and user's address.
     * @return _lids corresponding ids of the lock
     */
    function getInitializedLocksInfo(
        uint8 _pid,
        address _user
    ) external view returns (Lock[] memory _locks, uint8[] memory _lids) {
        uint8 _locksLength = uint8(locks[_pid][_user].length);
        uint8 _j;

        uint8 _initializedLocksNumber = users[_pid][_user].initializedLocksNumber;

        _locks = new Lock[](_initializedLocksNumber);
        _lids = new uint8[](_initializedLocksNumber);

        for (uint8 _lid; _lid < _locksLength; ++_lid) {
            if (locks[_pid][_user][_lid].isInitialized) {
                _lids[_j] = _lid;
                _locks[_j] = locks[_pid][_user][_lid];
                _j++;
            }
        }
    }

    /**
     * @notice Returns an indicator that token can be staked in one of the staking pools.
     * @param _token An address of the token to check.
     * @return An indicator that token can be staked in one of the staking pools.
     */
    function isStakeToken(address _token) external view returns (bool) {
        return stakeTokens[_token] == STAKE_TOKEN;
    }

    /**
     * @notice Returns Ticket contract address.
     * @return Ticket contract address.
     */
    function getTicket() external view returns (ITicket) {
        return ticket;
    }

    /**
     * @notice Returns stETH oracle address.
     * @return stETH oracle address.
     */
    function getStEthOracle() external view returns (IOracle) {
        return stEthOracle;
    }

    /**
     * @notice Returns NonfungiblePositionManager contract address.
     * @return NonfungiblePositionManager contract address.
     */
    function getNonfungiblePositionManager() external view returns (INonfungiblePositionManager) {
        return nonfungiblePositionManager;
    }

    /**
     * @notice Returns minumum boost threshold percentage.
     * @return Minimum boost threshold percentage.
     */
    function getMinBoostThreshold() external view returns (uint16) {
        return minBoostThreshold;
    }

    /**
     * @notice Returns maximum boost threshold percentage.
     * @return Maximum boost threshold percentage.
     */
    function getMaxBoostThreshold() external view returns (uint16) {
        return maxBoostThreshold;
    }

    /**
     * @notice Returns staking pools number.
     * @return Staking pools number.
     */
    function getPoolsNumber() external view returns (uint8) {
        return poolsNumber;
    }

    /**
     * @notice Returns current max boost coefficient.
     * @return Current max boost coefficient.
     */
    function getMaxBoost() external view returns (uint16) {
        return maxBoost;
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Sets a new array with LockDurationSettings structures for the staking pool.
     * @param _pid Staking pool ID.
     * @param _lds An array with LockDurationSettings structures which will be applied additionally to users' lock
     *             durations coefficients.
     */
    function _setLockDurationSettings(uint8 _pid, LockDurationSettings[] memory _lds) internal {
        uint8 _lockDurationSettingsNumber = pools[_pid].lockDurationSettingsNumber;

        for (uint8 _i; _i < _lockDurationSettingsNumber; ++_i) {
            delete lockDurationSettings[_pid][_i];
        }

        uint8 _newLockDurationSettingsNumber = uint8(_lds.length);

        if (_newLockDurationSettingsNumber == 0) revert RewardsBoosterErrors.WrongLockDurtionSettingsNumber();

        for (uint8 _i; _i < _newLockDurationSettingsNumber; ++_i) {
            if (_lds[_i].lowerLockDuration > _lds[_i].upperLockDuration)
                revert RewardsBoosterErrors.WrongLockDurtionSettings();

            if (_i > 0 && _lds[_i - 1].upperLockDuration != _lds[_i].lowerLockDuration - 1)
                revert RewardsBoosterErrors.WrongLockDurtionSettings();

            if (_i > 0 && _lds[_i - 1].additionalBoost >= _lds[_i].additionalBoost)
                revert RewardsBoosterErrors.WrongLockDurtionSettings();

            lockDurationSettings[_pid][_i] = _lds[_i];
        }

        pools[_pid].lockDurationSettingsNumber = _newLockDurationSettingsNumber;
        pools[_pid].minLockDuration = _lds[0].lowerLockDuration;
        pools[_pid].maxLockDuration = _lds[_newLockDurationSettingsNumber - 1].upperLockDuration;
    }

    /**
     * @notice Pushes a lock (position) at the end of the array with locks (positions) or just inserts using _lid.
     * @param _pid Staking pool ID where to stake.
     * @param _lid An ID of the lock (position) where to stake.
     * @param _amountOrId An amount of ERC-20 LP tokens (or ERC-721 NFT position ID) to stake.
     * @param _lockDuration A duration (in seconds) for the lock of the position.
     * @param _push A flag that indicates if a lock (position) should be pushed at the end of the array with locks
     *              (positions) or just inserted using _lid.
     */
    function _pushLock(
        uint8 _pid,
        uint8 _lid,
        uint256 _amountOrId,
        uint32 _lockDuration,
        bool _push
    ) internal returns (Lock memory) {
        Lock memory _lock = Lock({
            amountOrId: _amountOrId,
            createdAt: uint32(block.timestamp),
            updatedAt: uint32(block.timestamp),
            duration: _lockDuration,
            maxBoost: maxBoost,
            isInitialized: true
        });

        if (_push) {
            locks[_pid][msg.sender].push(_lock);
        } else {
            locks[_pid][msg.sender][_lid] = _lock;
        }

        users[_pid][msg.sender].initializedLocksNumber += 1;

        return _lock;
    }

    /**
     * @notice Collects fees from Uniswap V3 ASX/WETH pool.
     * @param _id An ID of Uniswap V3 position (ERC-721 NFT) from which to collect fees.
     * @return _wethAmount An amount of collected WETH tokens.
     * @return _asxAmount An amount of collected ASX tokens.
     */
    function _collectUniswapV3Fees(uint256 _id) internal returns (uint256 _wethAmount, uint256 _asxAmount) {
        INonfungiblePositionManager.CollectParams memory _collectParams = INonfungiblePositionManager.CollectParams({
            tokenId: _id,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });
        INonfungiblePositionManager _nonfungiblePositionManager = nonfungiblePositionManager;
        (_asxAmount, _wethAmount) = _nonfungiblePositionManager.collect(_collectParams);
    }

    /**
     * @notice Returns whether the lock (position) is finished or not.
     * @param _lock A lock (position) to check whether it is finished or not.
     * @return Flag whether the lock (position) is finished or not.
     */
    function _isFinishedLock(Lock memory _lock) internal view returns (bool) {
        return uint32(block.timestamp) >= _lock.updatedAt + _lock.duration;
    }

    /**
     * @notice Calculates the value (in USD) of each locked and active position of a user + the total value of all
     *         user's locked positions.
     * @param _user A user to calculate locked positions value (in USD) for.
     * @param _poolsNumber A number of staking pools.
     * @return _lockedLiquidityTotalValue A total value (in USD) of all user's locked and active positions.
     * @return _lockedLiquidityValues An array of values (in USD) for the user's staking pools and locked and active
     *                                positions in them.
     */
    function _getLockedLiqudityValue(
        address _user,
        uint8 _poolsNumber
    ) internal view returns (uint256 _lockedLiquidityTotalValue, uint256[][] memory _lockedLiquidityValues) {
        _lockedLiquidityValues = new uint256[][](_poolsNumber);

        for (uint8 _pid; _pid < _poolsNumber; ++_pid) {
            uint8 _locksNumber = uint8(Math.min(MAX_LOCKS_NUMBER, uint8(locks[_pid][_user].length)));
            Pool memory _pool = pools[_pid];

            _lockedLiquidityValues[_pid] = new uint256[](_locksNumber);

            for (uint8 _lid; _lid < _locksNumber; ++_lid) {
                Lock memory _lock = locks[_pid][_user][_lid];

                if (!_isFinishedLock(_lock)) {
                    uint256 _value = IValuer(_pool.stakeTokenValuer).value(_lock.amountOrId);

                    _lockedLiquidityTotalValue += _value;
                    _lockedLiquidityValues[_pid][_lid] = _value;
                }
            }
        }
    }

    /**
     * @notice Calculates the value (in USD) of the user's position (in stETH) in the StakePrizePool contract.
     * @param _user A user to calculate stETH position value (in USD) for.
     * return _lockedStEthValue A value (in USD) of the user's position (in stETH) in the StakePrizePool contract.
     */
    function _getLockedStEthValue(address _user) internal view returns (uint256 _lockedStEthValue) {
        IOracle _stEthOracle = stEthOracle;
        uint256 _stEthPrice = (uint256(_stEthOracle.latestAnswer()) * 1e18) / 10 ** _stEthOracle.decimals();

        _lockedStEthValue = (_stEthPrice * ticket.getBalanceAt(_user, uint64(block.timestamp))) / 1e18;
    }

    /**
     * @notice Calculates a boost coefficient for a user.
     * @param _user A user to calculate boost coefficient for.
     * @param _lockedLiquidityRatio A ratio of user's locked liquidity (in USD) in the booster to locked stETH (in USD)
     *                              in the StakePrizePool.
     * @param _poolsNumber A number of staking pools.
     * @param _lockedLiquidityTotalValue A total value (in USD) of all user's locked positions.
     * @param _lockedLiquidityValues An array of values (in USD) for the user's staking pools and locked positions in
     *                               them.
     * @return _lockedLiquidityBoost The boost for the user's locked liquidity in all positions between all staking
     *                               pools.
     * @return _lockDurationBoost The boost for the duration of all locks (positions) of the user.
     */
    function _getBoost(
        address _user,
        uint32 _lockedLiquidityRatio,
        uint8 _poolsNumber,
        uint256 _lockedLiquidityTotalValue,
        uint256[][] memory _lockedLiquidityValues
    ) internal view returns (uint32 _lockedLiquidityBoost, uint32 _lockDurationBoost) {
        uint16 _halfMaxBoost = maxBoost >> 1;

        if (_lockedLiquidityRatio >= minBoostThreshold) {
            _lockedLiquidityBoost += _getLockedLiqudityValueBoostCoefficient(_lockedLiquidityRatio, maxBoostThreshold);

            if (_lockedLiquidityBoost > _halfMaxBoost) _lockedLiquidityBoost = _halfMaxBoost;
        }

        for (uint8 _pid; _pid < _poolsNumber; ++_pid) {
            uint8 _locksNumber = uint8(Math.min(MAX_LOCKS_NUMBER, uint8(locks[_pid][_user].length)));
            Pool memory _pool = pools[_pid];

            for (uint8 _lid; _lid < _locksNumber; ++_lid) {
                Lock memory _lock = locks[_pid][_user][_lid];

                if (!_isFinishedLock(_lock)) {
                    uint256 _percent = Math.ceilDiv(
                        (_lockedLiquidityValues[_pid][_lid] * ONE_HUNDRED_PERCENTS),
                        _lockedLiquidityTotalValue
                    );
                    uint32 _lockDurationBoostCoefficient = _getLockDurationBoostCoefficient(_pool, _lock);
                    uint32 _additionalLockDurationBoostCoefficient = _getAdditionalLockDurationBoostCoefficient(
                        _pid,
                        _pool.lockDurationSettingsNumber,
                        _lock.duration
                    );

                    _lockDurationBoost += uint32(
                        Math.ceilDiv(
                            ((_lockDurationBoostCoefficient * 100) + (_additionalLockDurationBoostCoefficient * 100)) *
                                _percent,
                            ONE_HUNDRED_PERCENTS
                        )
                    );
                }
            }
        }

        _lockDurationBoost = uint32(_lockDurationBoost / 100);
    }

    /**
     * @notice Calculates additional boost coefficient for lock duration that will be added to previously calculated
     *         user's boost coefficient for lock duration.
     * @param _pid Staking pool ID.
     * @param _lockDurationSettingsNumber An amount of settings in the mapping with lock duration settings.
     * @param _lockDuration A duration of user's lock (in seconds).
     * @return Additional boost coefficient for lock duration that will be added to previously calculated user's boost
     *         coefficient for lock duration.
     */
    function _getAdditionalLockDurationBoostCoefficient(
        uint8 _pid,
        uint8 _lockDurationSettingsNumber,
        uint32 _lockDuration
    ) internal view returns (uint16) {
        for (uint8 _i; _i < _lockDurationSettingsNumber; ++_i) {
            LockDurationSettings memory _lockDurationSettings = lockDurationSettings[_pid][_i];

            if (
                _lockDuration >= _lockDurationSettings.lowerLockDuration &&
                _lockDuration <= _lockDurationSettings.upperLockDuration
            ) {
                return _lockDurationSettings.additionalBoost;
            }
        }

        return 0;
    }

    /**
     * @notice Calculates the boost coefficient for the user's locked liquidity value ratio.
     * @param _lockedLiquidityRatio A ratio of user's locked liquidity (in USD) in the booster to locked stETH (in USD)
     *                              in the StakePrizePool.
     * @param _maxBoostThreshold A threshold (in %) that all of the user's locks (positions) together must achieve to
     *                           get the maximum boost during a rewards claim on the StakePrizePool contract.
     * @return _lockedLiqudityValueBoostCoefficient The boost coefficient for the user's locked liquidity value ratio.
     */
    function _getLockedLiqudityValueBoostCoefficient(
        uint32 _lockedLiquidityRatio,
        uint16 _maxBoostThreshold
    ) internal view returns (uint16 _lockedLiqudityValueBoostCoefficient) {
        _lockedLiqudityValueBoostCoefficient = uint16(
            (((uint256(_lockedLiquidityRatio) * 1e18) / _maxBoostThreshold) * (ONE_HUNDRED_PERCENTS >> 1) * maxBoost) /
                1e18 /
                ONE_HUNDRED_PERCENTS
        );
    }

    /**
     * @notice Calculates the boost for the user's lock (position) in the specified staking pool.
     * @param _pool A staking pool is used to get the maximum lock (position) duration.
     * @param _lock A user's lock (position) for which to calculate the boost.
     * @return _lockDurationBoostCoefficient A boost coefficient for the specified lock (position) in the specified
     *                                       staking pool.
     */
    function _getLockDurationBoostCoefficient(
        Pool memory _pool,
        Lock memory _lock
    ) internal view returns (uint16 _lockDurationBoostCoefficient) {
        _lockDurationBoostCoefficient = uint16(
            Math.ceilDiv(
                ((((uint256(_lock.duration) * 1e18) / _pool.maxLockDuration) * (ONE_HUNDRED_PERCENTS >> 1) * maxBoost) /
                    1e18),
                ONE_HUNDRED_PERCENTS
            )
        );
    }

    /**
     * @notice Sets a new Ticket contract.
     * @param _newTicket A new Ticket contract address.
     */
    function _setTicket(address _newTicket) private {
        _onlyContract(_newTicket);

        ticket = ITicket(_newTicket);
    }

    /**
     * @notice Sets a new oracle for stETH token.
     * @param _newStEthOracle A new oracle for stETH token.
     */
    function _setStEthOracle(address _newStEthOracle) private {
        _onlyContract(_newStEthOracle);

        stEthOracle = IOracle(_newStEthOracle);
    }

    /**
     * @notice Sets a new NonfungiblePositionManager contract.
     * @param _newNonfungiblePositionManager A new NonfungiblePositionManager contract address.
     */
    function _setNonfungiblePositionManager(address _newNonfungiblePositionManager) private {
        _onlyContract(_newNonfungiblePositionManager);

        nonfungiblePositionManager = INonfungiblePositionManager(_newNonfungiblePositionManager);
    }

    /**
     * @notice Sets a new minimum boost threshold.
     * @param _newMinBoostThreshold A threshold (in %) that all of the user's locks (positions) together must overcome
     *                              for a boost to be awarded during a rewards claim on the StakePrizePool contract.
     */
    function _setMinBoostThreshold(uint16 _newMinBoostThreshold) private {
        if (_newMinBoostThreshold > maxBoostThreshold) revert RewardsBoosterErrors.TooBigBoostThreshold();

        minBoostThreshold = _newMinBoostThreshold;
    }

    /**
     * @notice Sets a new maximum boost threshold.
     * @param _newMaxBoostThreshold A threshold (in %) that all of the user's locks (positions) together must achieve to
     *                              get the maximum boost during a rewards claim on the StakePrizePool contract.
     */
    function _setMaxBoostThreshold(uint16 _newMaxBoostThreshold) private {
        if (_newMaxBoostThreshold < minBoostThreshold) revert RewardsBoosterErrors.TooSmallBoostThreshold();
        if (_newMaxBoostThreshold > ONE_HUNDRED_PERCENTS) revert RewardsBoosterErrors.TooBigBoostThreshold();

        maxBoostThreshold = _newMaxBoostThreshold;
    }

    /**
     * @notice Sets a new maximum possible boost coefficient.
     * @param _newMaxBoost A new maximum possible boost coefficient that is used when lock (position) is created by a
     *                     user.
     */
    function _setMaxBoost(uint16 _newMaxBoost) private {
        maxBoost = _newMaxBoost;
    }
}
