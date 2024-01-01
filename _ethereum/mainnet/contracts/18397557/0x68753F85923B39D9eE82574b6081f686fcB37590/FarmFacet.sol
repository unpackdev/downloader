pragma solidity ^0.8.19;

import "./IOwnable.sol";
import "./LibFarmStorage.sol";
import "./Scale.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./OwnableInternal.sol";

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) external view returns (uint[] memory amounts);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract FarmFacet is IERC20, ReentrancyGuard, Pausable, OwnableInternal {
    uint256 private constant MULTIPLIER = 1 ether;

    error FarmFacet__MinLockDuration();
    error FarmFacet__NotLocker();
    error FarmFacet__AlreadyUnlocked();
    error FarmFacet__StillLocked(uint256 _timeLeft);
    error FarmFacet__NotEnoughRewards();

    error FarmFacet__AlreadyVested();
    error FarmFacet__NotVester();

    error FarmFacet__NotTransferable();

    error FarmFacet__InvalidDuration();

    modifier setLastRewardBalance() {
        _;
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();
        fs.lastRewardBalance = Scale(payable(fs.rewardToken)).baseBalanceOf(
            address(this)
        );
    }

    /* internal */
    function updateRewardIndex(uint reward) internal {
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();

        if (fs.totalSupply != 0) {
            Scale _scale = Scale(payable(fs.rewardToken));
            uint256 currentRewardBalance = _scale.baseBalanceOf(address(this));

            // if S is directly transferred to contract via ERC20.transfer()
            if (reward == 0 && currentRewardBalance > fs.lastRewardBalance) {
                reward = currentRewardBalance - fs.lastRewardBalance;
            }

            fs.rewardIndex = fs.rewardIndex + ((reward * MULTIPLIER) / fs.totalSupply);
        }
    }

    function _calculateRewards(address account) internal view returns (uint) {
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();
        uint shares = fs.balanceOf[account];
        return
            (shares * (fs.rewardIndex - fs.rewardIndexOf[account])) /
            MULTIPLIER;
    }

    function _updateRewards(address account) internal {
        updateRewardIndex(0);
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();
        fs.earned[account] = fs.earned[account] + _calculateRewards(account);

        fs.rewardIndexOf[account] = fs.rewardIndex;
    }

    /* public */
    function lock(
        uint amount,
        uint256 duration
    ) external whenNotPaused nonReentrant setLastRewardBalance {
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();
        uint maxLockDuration = fs.maxLockDuration;
        uint minLockDuration = fs.minLockDuration;

        if (duration < minLockDuration) revert FarmFacet__MinLockDuration();
        if (duration > maxLockDuration) duration = maxLockDuration;

        _updateRewards(msg.sender);

        uint receiptAmount = duration >= maxLockDuration
            ? amount
            : _getReceiptAmount(amount, duration, minLockDuration, maxLockDuration);

        // create lock
        fs.currentLockingIndex = fs.currentLockingIndex + 1;
        fs.lockingIndexToLock[fs.currentLockingIndex] = LibFarmStorage.Lock({
            startTimestamp: block.timestamp,
            amount: amount,
            receiptAmount: receiptAmount,
            duration: duration,
            unlocked: 0,
            locker: msg.sender
        });

        uint256[] storage userLockingIndexList = fs.addressToLockingIndexList[
            msg.sender
        ];
        userLockingIndexList.push(fs.currentLockingIndex);

        // mint receipt tokens
        fs.balanceOf[msg.sender] = fs.balanceOf[msg.sender] + receiptAmount;
        fs.totalSupply = fs.totalSupply + receiptAmount;

        IERC20(fs.stakingToken).transferFrom(msg.sender, address(this), amount);
    }

    function unlock(
        uint _lockingIndex
    ) external whenNotPaused nonReentrant setLastRewardBalance {
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();

        LibFarmStorage.Lock storage _lock = fs.lockingIndexToLock[
            _lockingIndex
        ];

        if (_lock.locker != msg.sender) revert FarmFacet__NotLocker(); // prevent others from unlocking your lock
        if (_lock.unlocked != 0) revert FarmFacet__AlreadyUnlocked(); // prevent double spending
        if (_lock.startTimestamp + _lock.duration > block.timestamp)
            revert FarmFacet__StillLocked(
                _lock.startTimestamp + _lock.duration - block.timestamp
            ); // ensure lock period has passed

        _updateRewards(msg.sender);

        _lock.unlocked = 1;

        fs.balanceOf[msg.sender] = fs.balanceOf[msg.sender]- _lock.receiptAmount;
        fs.totalSupply = fs.totalSupply - _lock.receiptAmount;

        IERC20(fs.stakingToken).transfer(msg.sender, _lock.amount);
    }

    function vest() external whenNotPaused nonReentrant setLastRewardBalance {
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();

        _updateRewards(msg.sender);

        if (fs.earned[msg.sender] <= fs.addressToTotalVesting[msg.sender])
            revert FarmFacet__NotEnoughRewards();

        // create vest
        uint256 vestAmount = fs.earned[msg.sender] -
            fs.addressToTotalVesting[msg.sender];
        fs.currentVestIndex = fs.currentVestIndex + 1;
        fs.vestIndexToVest[fs.currentVestIndex] = LibFarmStorage.Vest({
            startTimestamp: block.timestamp,
            amount: vestAmount,
            vested: 0,
            vester: msg.sender
        });
        fs.addressToTotalVesting[msg.sender] = fs.addressToTotalVesting[msg.sender] + vestAmount;

        fs.addressToVestIndexList[msg.sender].push(fs.currentVestIndex);
    }

    function claim(
        uint256 _vestIndex
    ) external whenNotPaused nonReentrant setLastRewardBalance returns (uint) {
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();
        _updateRewards(msg.sender);

        LibFarmStorage.Vest storage _vest = fs.vestIndexToVest[_vestIndex];

        if (_vest.vested != 0) revert FarmFacet__AlreadyVested();
        if (_vest.vester != msg.sender) revert FarmFacet__NotVester();

        uint256 vestAmount = _vest.amount;

        Scale _scale = Scale(payable(fs.rewardToken));
        uint256 reward = _scale.baseToReflectionAmount(vestAmount);

        // early vest penalty
        uint256 toStaker;
        uint256 toTreasury;
        if (block.timestamp < _vest.startTimestamp + fs.vestDuration) {
            uint256 fees = (reward * fs.earlyVestPenalty) / 10_000; // 50%
            toStaker = fees * fs.penaltyToStaker / 10_000;
            toTreasury = fees * (10_000 - fs.penaltyToStaker) / 10_000;
            reward = reward - toStaker - toTreasury;
        }

        _vest.vested = 1;
        fs.earned[msg.sender] = fs.earned[msg.sender] - vestAmount;
        fs.addressToTotalVesting[msg.sender] = fs.addressToTotalVesting[msg.sender] - vestAmount;

        // transfers
        if (toTreasury != 0) {
            // swap fees to ETH
            IUniswapV2Router02 router = IUniswapV2Router02(fs.router);
            address[] memory path = new address[](2);
            path[0] = fs.rewardToken;
            path[1] = router.WETH();
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                toTreasury,
                0,
                path,
                fs.treasury,
                block.timestamp
            );
        }
        if (toStaker != 0) {
            updateRewardIndex(_scale.reflectionToBaseAmount(toStaker)); // redistribute to stakers
        }
        _scale.transfer(msg.sender, reward);

        return reward;
    }

    /* internal */
    function _getReceiptAmount(
        uint amount,
        uint _duration, 
        uint _minLockDuration, 
        uint _maxLockDuration
    ) internal pure returns(uint) {

        int duration = int(_duration);
        int minLockDuration = int(_minLockDuration);
        int maxLockDuration = int(_maxLockDuration);

        int durationSpan = maxLockDuration - minLockDuration;
        int linearFactor = 1_000 + (9_000 * (duration - minLockDuration) / durationSpan);
        int limit = durationSpan / 172_800;
        int curveFactor = 1_000 * limit;
        for(
            int i = -limit; 
            i < limit;
        ) {
            curveFactor = 
                curveFactor -
                _abs(
                    500 - 
                    (1_000 * (duration + (i * 86_400) - minLockDuration)) / durationSpan
                );
            unchecked { i = i + 1; }
        }
        return amount * uint(linearFactor + curveFactor / 10_000) / 10_000;
    }

    function _abs(int val) internal pure returns (int) {
        return val > 0 ? val : -val;
    }

    /* admin */
    function setLockDurations(
        uint minLockDuration,
        uint maxLockDuration,
        uint earlyVestPenalty,
        uint penaltyToStaker
    ) external onlyOwner {
        if (minLockDuration >= maxLockDuration)
            revert FarmFacet__InvalidDuration();
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();
        fs.minLockDuration = minLockDuration;
        fs.maxLockDuration = maxLockDuration;
        fs.earlyVestPenalty = earlyVestPenalty; // in BP
        fs.penaltyToStaker = penaltyToStaker; // in BP
    }

    function setVestDuration(uint256 vestDuration) external onlyOwner {
        LibFarmStorage.layout().vestDuration = vestDuration;
    }

    function setTokens(
        address _stakingToken,
        address _rewardToken
    ) external onlyOwner {
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();
        fs.stakingToken = _stakingToken;
        fs.rewardToken = _rewardToken;
    }

    function setTreasury(
        address _treasury,
        address _router
    ) external onlyOwner {
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();
        fs.treasury = _treasury;

        // approve
        Scale _scale = Scale(payable(fs.rewardToken));
        _scale.approve(fs.router, 0);
        fs.router = _router;
        _scale.approve(fs.router, type(uint256).max);
    }

    function setPauseStatus(bool _paused) external onlyOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /* view */
    function calculateRewardsEarned(
        address account
    ) external view returns (uint) {
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();

        if (fs.totalSupply != 0) {
            // rewardIndex
            Scale _scale = Scale(payable(fs.rewardToken));
            uint256 _currentRewardBalance = _scale.baseBalanceOf(address(this));
            uint256 _reward = _currentRewardBalance - fs.lastRewardBalance;
            uint256 _rewardIndex = fs.rewardIndex +
                (_reward * MULTIPLIER) /
                fs.totalSupply;

            uint256 _shares = fs.balanceOf[account];

            return
                _scale.baseToReflectionAmount(
                    fs.earned[account] +
                        ((_shares *
                            (_rewardIndex - fs.rewardIndexOf[account])) /
                            MULTIPLIER) -
                        fs.addressToTotalVesting[account]
                );
        }
        return 0;
    }

    function getUserLockList(
        address _address
    )
        external
        view
        returns (
            LibFarmStorage.Lock[] memory _lockList,
            uint256[] memory lockingIndexList
        )
    {
        lockingIndexList = addressToLockingIndexList(_address);

        _lockList = new LibFarmStorage.Lock[](lockingIndexList.length);
        for (uint256 i; i < lockingIndexList.length; i++) {
            _lockList[i] = lockingIndexToLock(lockingIndexList[i]);
        }
    }

    function getUserVestList(
        address _address
    )
        external
        view
        returns (
            LibFarmStorage.Vest[] memory _vestList,
            uint256[] memory vestIndexList
        )
    {
        vestIndexList = addressToVestIndexList(_address);

        _vestList = new LibFarmStorage.Vest[](vestIndexList.length);

        for (uint256 i; i < vestIndexList.length; i++) {
            _vestList[i] = vestIndexToVest(vestIndexList[i]);
        }
    }

    function addressToLockingIndexList(
        address _address
    ) public view returns (uint256[] memory) {
        return LibFarmStorage.layout().addressToLockingIndexList[_address];
    }

    function lockingIndexToLock(
        uint256 _lockingIndex
    ) public view returns (LibFarmStorage.Lock memory) {
        return LibFarmStorage.layout().lockingIndexToLock[_lockingIndex];
    }

    function addressToVestIndexList(
        address _address
    ) public view returns (uint256[] memory) {
        return LibFarmStorage.layout().addressToVestIndexList[_address];
    }

    function vestIndexToVest(
        uint256 _vestIndex
    ) public view returns (LibFarmStorage.Vest memory) {
        return LibFarmStorage.layout().vestIndexToVest[_vestIndex];
    }

    function stakingToken() external view returns (address) {
        return LibFarmStorage.layout().stakingToken;
    }

    function rewardToken() external view returns (address) {
        return LibFarmStorage.layout().rewardToken;
    }

    function earned(address _address) external view returns (uint256) {
        return LibFarmStorage.layout().earned[_address];
    }

    function rewardIndex() external view returns (uint256) {
        return LibFarmStorage.layout().rewardIndex;
    }

    function getLockDuration() external view returns (uint256, uint256) {
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();
        return (fs.minLockDuration, fs.maxLockDuration);
    }

    function getVestDuration() external view returns (uint256, uint256) {
        LibFarmStorage.Layout storage fs = LibFarmStorage.layout();
        return (fs.vestDuration, fs.earlyVestPenalty);
    }

    /* ERC20 functions */
    function totalSupply() external view returns (uint) {
        return LibFarmStorage.layout().totalSupply;
    }

    function balanceOf(address account) external view returns (uint) {
        return LibFarmStorage.layout().balanceOf[account];
    }

    /* some ERC20 functions are disabled for receipt tokens */
    function transfer(
        address recipient,
        uint amount
    ) external pure returns (bool) {
        // receipt tokens are not transferable at this moment
        revert FarmFacet__NotTransferable();
    }

    function allowance(
        address owner,
        address spender
    ) external pure returns (uint) {
        // no allowance since not transferable
        revert FarmFacet__NotTransferable();
    }

    function approve(
        address spender,
        uint amount
    ) external pure returns (bool) {
        // not approvable since not transferable
        revert FarmFacet__NotTransferable();
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external pure returns (bool) {
        // receipt tokens are not transferable at this moment
        revert FarmFacet__NotTransferable();
    }

    // function _transfer(address from, address to, uint256 amount) internal {
    //     require(from != address(0), "ERC20: transfer from the zero address");
    //     require(to != address(0), "ERC20: transfer to the zero address");

    //     LibFarmStorage.Layout storage fs = LibFarmStorage.layout();

    //     uint256 fromBalance = fs.balanceOf[from];
    //     require(
    //         fromBalance >= amount,
    //         "ERC20: transfer amount exceeds balance"
    //     );
    //     unchecked {
    //         fs.balanceOf[from] = fromBalance - amount;
    //         // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
    //         // decrementing then incrementing.
    //         fs.balanceOf[to] += amount;
    //     }

    //     emit Transfer(from, to, amount);
    // }
}
