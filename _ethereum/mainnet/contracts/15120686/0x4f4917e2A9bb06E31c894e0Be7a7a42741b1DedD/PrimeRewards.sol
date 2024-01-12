// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./SafeCast.sol";
import "./Math.sol";

/// @title The PrimeRewards staking contract
/// @notice Staking for PrimeKey, PrimeSets, CatalystDrive. It allows for a fixed PRIME token
/// rewards distributed evenly across all staked tokens per second.
contract PrimeRewards is Ownable, ERC1155Holder {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice Info of each Deposit.
    /// `amount` Number of nft sets the user has provided.
    /// `rewardDebt` The amount of PRIME the user is not eligible for either from
    ///  having already harvesting or from not staking in the past.
    struct DepositInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each pool.
    /// Contains the weighted allocation of the reward pool
    /// as well as the ParallelAlpha tokenIds required to stake in the pool
    struct PoolInfo {
        uint256 accPrimePerShare;
        uint256 allocPoint;
        uint256 lastRewardTimestamp;
        uint256[] tokenIds;
        uint256 totalSupply;
    }

    /// @notice Address of PRIME contract.
    IERC20 public PRIME;

    /// @notice Address of Parallel Alpha erc1155
    IERC1155 public immutable parallelAlpha;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;

    /// @notice Deposit info of each user that stakes nft sets.
    // poolID(per set) => user address => deposit info
    mapping(uint256 => mapping(address => DepositInfo)) public depositInfo;

    /// @notice Prime amount distributed for given period. primeAmountPerSecond = primeAmount / (endTimestamp - startTimestamp)
    uint256 public startTimestamp; // caching start timestamp.
    uint256 public endTimestamp; // caching end timestamp.
    uint256 public primeAmount; // the amount of PRIME to give out as rewards.
    uint256 public primeAmountPerSecond; // the amount of PRIME to give out as rewards per second.
    uint256 public constant primeAmountPerSecondPrecision = 1e18; // primeAmountPerSecond is carried around with extra precision to reduce rounding errors

    uint256 public primeUpdateCutoff = 1667304000;

    /// @dev Limit number of pools added
    uint256 public maxNumPools = 500;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    /// @dev Deposits can be paused
    bool public depositsPaused;

    /// @dev Constants passed into event data
    uint256 public constant ID_PRIME = 0;
    uint256 public constant ID_ETH = 1;

    /// @dev internal lock for receiving ERC1155 tokens. Only allow during deposit calls
    bool public onReceiveLocked = true;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Claim(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 indexed currencyId
    );
    event LogPoolAddition(uint256 indexed pid, uint256[] tokenIds);

    event EndTimestampUpdated(uint256 endTimestamp, uint256 indexed currencyID);
    event RewardIncrease(uint256 amount, uint256 indexed currencyID);
    event RewardDecrease(uint256 amount, uint256 indexed currencyID);

    event DepositsPaused(bool depositsPaused);
    event LogPoolSetAllocPoint(
        uint256 indexed pid,
        uint256 allocPoint,
        uint256 totalAllocPoint,
        uint256 indexed currencyId
    );
    event LogUpdatePool(
        uint256 indexed pid,
        uint256 lastRewardTimestamp,
        uint256 supply,
        uint256 accPerShare,
        uint256 indexed currencyId
    );
    event LogSetPerSecond(
        uint256 amount,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 indexed currencyId
    );

    /// @param _prime The PRIME token contract address.
    /// @param _parallelAlpha The Parallel Alpha contract address.
    constructor(IERC20 _prime, IERC1155 _parallelAlpha) {
        parallelAlpha = _parallelAlpha;
        PRIME = _prime;
    }

    /// @notice Sets new prime token address
    /// @param _prime The PRIME token contract address.
    function setPrimeTokenAddress(IERC20 _prime) external onlyOwner {
        require(
            block.timestamp < primeUpdateCutoff,
            "PRIME address update window has has passed"
        );
        PRIME = _prime;
    }

    /// @notice Sets new max number of pools. New max cannot be less than
    /// current number of pools.
    /// @param _maxNumPools The new max number of pools.
    function setMaxNumPools(uint256 _maxNumPools) external onlyOwner {
        require(
            _maxNumPools >= poolLength(),
            "Can't set maxNumPools less than poolLength"
        );
        maxNumPools = _maxNumPools;
    }

    /// @notice Returns the number of pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @param _pid Pool to get IDs for
    function getPoolTokenIds(uint256 _pid)
        external
        view
        returns (uint256[] memory)
    {
        return poolInfo[_pid].tokenIds;
    }

    function updateAllPools() internal {
        uint256 len = poolLength();
        for (uint256 i = 0; i < len; ++i) {
            updatePool(i);
        }
    }

    /// @notice Add a new set of tokenIds as a new pool. Can only be called by the owner.
    /// DO NOT add the same token id more than once. Rewards will be messed up if you do.
    /// @param _allocPoint AP of the new pool.
    /// @param _tokenIds TokenIds for ParallelAlpha ERC1155, set of tokenIds for pool.
    function addPool(uint256 _allocPoint, uint256[] memory _tokenIds)
        public
        virtual
        onlyOwner
    {
        require(poolInfo.length < maxNumPools, "Max num pools reached");
        require(_tokenIds.length > 0, "TokenIds cannot be empty");
        require(_allocPoint > 0, "Allocation point cannot be 0 or negative");
        // Update all Pools cause allocpoints
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
        }
        totalAllocPoint += _allocPoint;
        poolInfo.push(
            PoolInfo({
                accPrimePerShare: 0,
                allocPoint: _allocPoint,
                lastRewardTimestamp: Math.max(block.timestamp, startTimestamp),
                tokenIds: _tokenIds,
                totalSupply: 0
            })
        );
        emit LogPoolAddition(poolInfo.length - 1, _tokenIds);
        emit LogPoolSetAllocPoint(
            poolInfo.length - 1,
            _allocPoint,
            totalAllocPoint,
            ID_PRIME
        );
    }

    /// @notice Set new cycle/period to distribute rewards between endTimestamp-startTimestamp
    /// evenly per second. primeAmountPerSecond = _primeAmount / _endTimestamp - _startTimestamp
    /// @param _startTimestamp Timestamp for staking period to start at
    /// @param _endTimestamp Timestamp for staking period to end at
    /// @param _primeAmount Amount of Prime to distribute evenly across whole period
    function setPrimePerSecond(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _primeAmount
    ) external onlyOwner {
        require(
            _startTimestamp < _endTimestamp,
            "Endtimestamp cant be less than Starttimestamp"
        );
        require(
            block.timestamp < startTimestamp || endTimestamp < block.timestamp,
            "Only updates after endTimestamp or before startTimestamp"
        );

        // Update all pools before proceeding, ensure rewards calculated up to this timestamp
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
            poolInfo[i].lastRewardTimestamp = _startTimestamp;
        }
        primeAmount = _primeAmount;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        primeAmountPerSecond =
            (_primeAmount * primeAmountPerSecondPrecision) /
            (_endTimestamp - _startTimestamp);
        emit LogSetPerSecond(
            _primeAmount,
            _startTimestamp,
            _endTimestamp,
            ID_PRIME
        );
    }

    /// @notice Update endTimestamp, only possible to call this when staking for
    /// a period has already begun and new endTimestamp can't be in the past
    /// @param _endTimestamp New timestamp for staking period to end at
    function setEndTimestamp(uint256 _endTimestamp) external onlyOwner {
        require(
            startTimestamp < block.timestamp,
            "caching have not started yet"
        );
        require(block.timestamp < _endTimestamp, "invalid end timestamp");
        updateAllPools();

        // Update primeAmountPerSecond based on the new endTimestamp
        startTimestamp = block.timestamp;
        endTimestamp = _endTimestamp;
        primeAmountPerSecond =
            (primeAmount * primeAmountPerSecondPrecision) /
            (endTimestamp - startTimestamp);
        emit EndTimestampUpdated(_endTimestamp, ID_PRIME);
    }

    /// @notice Function for 'Top Ups', adds additional prime to distribute for remaining time
    /// in the period.
    /// @param _addPrimeAmount Amount of Prime to add to the remaining reward pool
    function addPrimeAmount(uint256 _addPrimeAmount) external onlyOwner {
        require(
            startTimestamp < block.timestamp && block.timestamp < endTimestamp,
            "Only topups inside a period"
        );
        // Update all pools
        updateAllPools();
        // Top up current cycle's PRIME
        primeAmount += _addPrimeAmount;
        primeAmountPerSecond =
            (primeAmount * primeAmountPerSecondPrecision) /
            (endTimestamp - block.timestamp);
        emit RewardIncrease(_addPrimeAmount, ID_PRIME);
    }

    /// @notice Function for 'Top Downs', removes additional prime to distribute for remaining time
    /// in the period.
    /// @param _removePrimeAmount Amount of Prime to remove from the remaining reward pool
    function removePrimeAmount(uint256 _removePrimeAmount) external onlyOwner {
        require(
            startTimestamp < block.timestamp && block.timestamp < endTimestamp,
            "Only topdowns inside a period"
        );

        // Update all pools
        updateAllPools();

        // Top up current cycle's PRIME
        // Using min to make sure the admin is able to reduce the primeAmount to zero
        _removePrimeAmount = Math.min(_removePrimeAmount, primeAmount);
        primeAmount -= _removePrimeAmount;
        primeAmountPerSecond =
            (primeAmount * primeAmountPerSecondPrecision) /
            (endTimestamp - block.timestamp);
        emit RewardDecrease(_removePrimeAmount, ID_PRIME);
    }

    /// @notice Update the given pool's PRIME allocation point. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function setPoolAllocPoint(uint256 _pid, uint256 _allocPoint)
        external
        onlyOwner
    {
        // Update all pools
        updateAllPools();
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit LogPoolSetAllocPoint(_pid, _allocPoint, totalAllocPoint, ID_PRIME);
    }

    /// @notice Enable/disable deposits for pools. Can only be called by the owner.
    /// @param _depositsPaused boolean value to set
    function setDepositsPaused(bool _depositsPaused) external onlyOwner {
        depositsPaused = _depositsPaused;
        emit DepositsPaused(depositsPaused);
    }

    /// @notice View function to see deposit amounts for pools on frontend.
    /// @param _pids List of pool index ids. See `poolInfo`.
    /// @param _addresses List of user addresses.
    /// @return amounts List of deposit amounts.
    function getPoolDepositAmounts(
        uint256[] calldata _pids,
        address[] calldata _addresses
    ) external view returns (uint256[] memory) {
        require(
            _pids.length == _addresses.length,
            "pids and addresses length miss-match"
        );

        uint256[] memory amounts = new uint256[](_pids.length);
        for (uint256 i = 0; i < _pids.length; ++i) {
            amounts[i] = depositInfo[_pids[i]][_addresses[i]].amount;
        }

        return amounts;
    }

    /// @notice View function to see pending PRIME on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending PRIME reward for a given user.
    function pendingPrime(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        DepositInfo storage _deposit = depositInfo[_pid][_user];
        uint256 accPrimePerShare = pool.accPrimePerShare;
        uint256 totalSupply = pool.totalSupply;

        if (
            startTimestamp <= block.timestamp &&
            pool.lastRewardTimestamp < block.timestamp &&
            totalSupply > 0
        ) {
            uint256 updateToTimestamp = Math.min(block.timestamp, endTimestamp);
            uint256 secondsStaked = updateToTimestamp -
                pool.lastRewardTimestamp;
            uint256 primeReward = (secondsStaked *
                primeAmountPerSecond *
                pool.allocPoint) / totalAllocPoint;
            accPrimePerShare += primeReward / totalSupply;
        }
        pending =
            ((_deposit.amount * accPrimePerShare).toInt256() -
                _deposit.rewardDebt).toUint256() /
            primeAmountPerSecondPrecision;
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param _pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata _pids) external {
        uint256 len = _pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(_pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param _pid The index of the pool. See `poolInfo`.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (
            startTimestamp > block.timestamp ||
            pool.lastRewardTimestamp >= block.timestamp ||
            (startTimestamp == 0 && endTimestamp == 0)
        ) {
            return;
        }

        uint256 updateToTimestamp = Math.min(block.timestamp, endTimestamp);
        uint256 totalSupply = pool.totalSupply;
        uint256 secondsStaked = updateToTimestamp - pool.lastRewardTimestamp;
        uint256 primeReward = (secondsStaked *
            primeAmountPerSecond *
            pool.allocPoint) / totalAllocPoint;
        primeAmount -= primeReward / primeAmountPerSecondPrecision;
        if (totalSupply > 0) {
            pool.accPrimePerShare += primeReward / totalSupply;
        }
        pool.lastRewardTimestamp = updateToTimestamp;
        emit LogUpdatePool(
            _pid,
            pool.lastRewardTimestamp,
            totalSupply,
            pool.accPrimePerShare,
            ID_PRIME
        );
    }

    /// @notice Deposit for PRIME allocation.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of 'tokenIds sets' to deposit for _pid.
    function deposit(uint256 _pid, uint256 _amount) public virtual {
        require(!depositsPaused, "Deposits are paused");
        require(_amount > 0, "Specify valid tokenId set amount to deposit");
        updatePool(_pid);
        DepositInfo storage _deposit = depositInfo[_pid][msg.sender];

        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = _amount;
        }

        // Effects
        poolInfo[_pid].totalSupply += _amount;
        _deposit.amount += _amount;
        _deposit.rewardDebt += (_amount * poolInfo[_pid].accPrimePerShare)
            .toInt256();

        onReceiveLocked = false;
        parallelAlpha.safeBatchTransferFrom(
            msg.sender,
            address(this),
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );
        onReceiveLocked = true;

        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw from pool
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of tokenId sets to withdraw from the pool
    function withdraw(uint256 _pid, uint256 _amount) public virtual {
        updatePool(_pid);
        DepositInfo storage _deposit = depositInfo[_pid][msg.sender];

        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = _amount;
        }

        // Effects
        poolInfo[_pid].totalSupply -= _amount;
        _deposit.rewardDebt -= (_amount * poolInfo[_pid].accPrimePerShare)
            .toInt256();
        _deposit.amount -= _amount;

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );

        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Claim accumulated PRIME rewards.
    /// @param _pid The index of the pool. See `poolInfo`.
    function claimPrime(uint256 _pid) public {
        updatePool(_pid);
        DepositInfo storage _deposit = depositInfo[_pid][msg.sender];
        int256 accumulatedPrime = (_deposit.amount *
            poolInfo[_pid].accPrimePerShare).toInt256();
        uint256 _pendingPrime = (accumulatedPrime - _deposit.rewardDebt)
            .toUint256() / primeAmountPerSecondPrecision;

        // Effects
        _deposit.rewardDebt = accumulatedPrime;

        // Interactions
        if (_pendingPrime != 0) {
            PRIME.safeTransfer(msg.sender, _pendingPrime);
        }

        emit Claim(msg.sender, _pid, _pendingPrime, ID_PRIME);
    }

    /// @notice claimPrime multiple pools
    /// @param _pids Pool IDs of all to be claimed
    function claimPrimePools(uint256[] calldata _pids) external virtual {
        for (uint256 i = 0; i < _pids.length; ++i) {
            claimPrime(_pids[i]);
        }
    }

    /// @notice Withdraw and claim PRIME rewards.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of tokenId sets to withdraw.
    function withdrawAndClaimPrime(uint256 _pid, uint256 _amount)
        public
        virtual
    {
        updatePool(_pid);
        DepositInfo storage _deposit = depositInfo[_pid][msg.sender];
        int256 accumulatedPrime = (_deposit.amount *
            poolInfo[_pid].accPrimePerShare).toInt256();
        uint256 _pendingPrime = (accumulatedPrime - _deposit.rewardDebt)
            .toUint256() / primeAmountPerSecondPrecision;

        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = _amount;
        }

        // Effects
        poolInfo[_pid].totalSupply -= _amount;
        _deposit.rewardDebt =
            accumulatedPrime -
            (_amount * poolInfo[_pid].accPrimePerShare).toInt256();
        _deposit.amount -= _amount;

        if (_pendingPrime != 0) {
            PRIME.safeTransfer(msg.sender, _pendingPrime);
        }

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );

        emit Withdraw(msg.sender, _pid, _amount);
        emit Claim(msg.sender, _pid, _pendingPrime, ID_PRIME);
    }

    /// @notice Withdraw and forgo rewards. EMERGENCY ONLY.
    /// @param _pid The index of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 _pid) public virtual {
        DepositInfo storage _deposit = depositInfo[_pid][msg.sender];

        uint256 amount = _deposit.amount;
        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = amount;
        }

        // Effects
        poolInfo[_pid].totalSupply -= amount;
        _deposit.rewardDebt = 0;
        _deposit.amount = 0;

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /// @notice Sweep function to transfer erc20 tokens out of contract
    /// Only callable by owner.
    /// @param erc20 Token to transfer out
    /// @param to address to sweep to
    /// @param amount Amount to withdraw
    function sweepERC20(
        IERC20 erc20,
        address to,
        uint256 amount
    ) external onlyOwner {
        erc20.transfer(to, amount);
    }

    /// @notice Disable renounceOwnership. Only callable by owner.
    function renounceOwnership() public virtual override onlyOwner {
        revert("Ownership cannot be renounced");
    }

    /// @notice Revert for calls outside of deposit method
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(onReceiveLocked == false, "onReceive is locked");
        return this.onERC1155Received.selector;
    }

    /// @notice Revert for calls outside of deposit method
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(onReceiveLocked == false, "onReceive is locked");
        return this.onERC1155BatchReceived.selector;
    }
}
