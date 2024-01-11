 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./IUniRouter02.sol";
import "./IWETH.sol";
interface IToken {
     /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);
}

contract BrewlabsLockupV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Whether it is initialized
    bool public isInitialized;
    uint256 public duration = 365; // 365 days

    // Whether a limit is set for users
    bool public hasUserLimit;
    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;


    // The block number when staking starts.
    uint256 public startBlock;
    // The block number when staking ends.
    uint256 public bonusEndBlock;


    // swap router and path, slipPage
    uint256 public slippageFactor = 800; // 20% default slippage tolerance
    uint256 public constant slippageFactorUL = 995;

    address public uniRouterAddress;
    address[] public reflectionToStakedPath;
    address[] public earnedToStakedPath;

    address public walletA;
    address public buyBackWallet = 0xE1f1dd010BBC2860F81c8F90Ea4E38dB949BB16F;
    uint256 public performanceFee = 0.00089 ether;

    // The precision factor
    uint256 public PRECISION_FACTOR;
    uint256 public PRECISION_FACTOR_REFLECTION;

    // The staked token
    IERC20 public stakingToken;
    // The earned token
    IERC20 public earnedToken;
    // The dividend token of staking token
    address public dividendToken;

    // Accrued token per share
    uint256 public accDividendPerShare;

    uint256 public totalStaked;

    uint256 private totalEarned;
    uint256 private totalReflections;
    uint256 private reflectionDebt;

    struct Lockup {
        uint256 duration;
        uint256 depositFee;
        uint256 withdrawFee;
        uint256 rate;
        uint256 accTokenPerShare;
        uint256 lastRewardBlock;
        uint256 totalStaked;
    }

    struct UserInfo {
        uint256 amount;         // total staked amount
        uint256 firstIndex;     // first index for unlocked elements
        uint256 reflectionDebt; // Reflection debt
    }

    struct Stake {
        uint256 amount;     // amount to stake
        uint256 duration;   // the lockup duration of the stake
        uint256 end;        // when does the staking period end
        uint256 rewardDebt; // Reward debt
    }
    uint256 constant MAX_STAKES = 256;
    uint256 private processingLimit = 30;

    Lockup public lockupInfo;
    mapping(address => Stake[]) public userStakes;
    mapping(address => UserInfo) public userStaked;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);

    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event LockupUpdated(uint256 _duration, uint256 _fee0, uint256 _fee1, uint256 _rate);
    event RewardsStop(uint256 blockNumber);
    event UpdatePoolLimit(uint256 poolLimitPerUser, bool hasLimit);

    event ServiceInfoUpadted(address _addr, uint256 _fee);
    event WalletAUpdated(address _addr);
    event DurationUpdated(uint256 _duration);

    event SetSettings(
        uint256 _slippageFactor,
        address _uniRouter,
        address[] _path0,
        address[] _path1
    );

    constructor() {}

    /*
     * @notice Initialize the contract
     * @param _stakingToken: staked token address
     * @param _earnedToken: earned token address
     * @param _dividendToken: reflection token address
     * @param _uniRouter: uniswap router address for swap tokens
     * @param _earnedToStakedPath: swap path to compound (earned -> staking path)
     * @param _reflectionToStakedPath: swap path to compound (reflection -> staking path)
     */
    function initialize(
        IERC20 _stakingToken,
        IERC20 _earnedToken,
        address _dividendToken,
        uint256 _rewardPerBlock,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _lockDuration,
        address _uniRouter,
        address[] memory _earnedToStakedPath,
        address[] memory _reflectionToStakedPath
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");

        // Make this contract initialized
        isInitialized = true;

        stakingToken = _stakingToken;
        earnedToken = _earnedToken;
        dividendToken = _dividendToken;

        walletA = msg.sender;

        uint256 decimalsRewardToken = uint256(IToken(address(earnedToken)).decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10**(40 - decimalsRewardToken));

        uint256 decimalsdividendToken = 18;
        if(address(dividendToken) != address(0x0)) {
            decimalsdividendToken = uint256(IToken(address(dividendToken)).decimals());
            require(decimalsdividendToken < 30, "Must be inferior to 30");
        }
        PRECISION_FACTOR_REFLECTION = uint256(10**(40 - decimalsdividendToken));

        uniRouterAddress = _uniRouter;
        earnedToStakedPath = _earnedToStakedPath;
        reflectionToStakedPath = _reflectionToStakedPath;

        lockupInfo.duration = _lockDuration;
        lockupInfo.depositFee = _depositFee;
        lockupInfo.withdrawFee = _withdrawFee;
        lockupInfo.rate = _rewardPerBlock;
        lockupInfo.accTokenPerShare = 0;
        lockupInfo.lastRewardBlock = 0;
        lockupInfo.totalStaked = 0;
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in earnedToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        require(startBlock > 0 && startBlock < block.number, "Staking hasn't started yet");
        require(_amount > 0, "Amount should be greator than 0");

        _updatePool();

        UserInfo storage user = userStaked[msg.sender];        
        uint256 pendingReflection = user.amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION - user.reflectionDebt;
        if (pendingReflection > 0) {
            if(address(dividendToken) == address(0x0)) {
                payable(msg.sender).transfer(pendingReflection);
            } else {
                IERC20(dividendToken).safeTransfer(address(msg.sender), pendingReflection);
            }
            totalReflections = totalReflections - pendingReflection;
        }


        uint256 beforeAmount = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        uint256 afterAmount = stakingToken.balanceOf(address(this));        
        uint256 realAmount = afterAmount - beforeAmount;

        if (hasUserLimit) {
            require(
                realAmount + user.amount <= poolLimitPerUser,
                "User amount above limit"
            );
        }
        if (lockupInfo.depositFee > 0) {
            uint256 fee = realAmount * lockupInfo.depositFee / 10000;
            if (fee > 0) {
                stakingToken.safeTransfer(walletA, fee);
                realAmount = realAmount - fee;
            }
        }
        
        _addStake(msg.sender, lockupInfo.duration, realAmount, user.firstIndex);

        user.amount = user.amount + realAmount;
        user.reflectionDebt = user.amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION;

        lockupInfo.totalStaked = lockupInfo.totalStaked + realAmount;
        totalStaked = totalStaked + realAmount;

        emit Deposit(msg.sender, realAmount);
    }

    function _addStake(address _account, uint256 _duration, uint256 _amount, uint256 firstIndex) internal {
        Stake[] storage stakes = userStakes[_account];

        uint256 end = block.timestamp + _duration * 1 days;
        uint256 i = stakes.length;
        require(i < MAX_STAKES, "Max stakes");

        stakes.push(); // grow the array
        // find the spot where we can insert the current stake
        // this should make an increasing list sorted by end
        while (i != 0 && stakes[i - 1].end > end && i >= firstIndex) {
            // shift it back one
            stakes[i] = stakes[i - 1];
            i -= 1;
        }
        
        // insert the stake
        Stake storage newStake = stakes[i];
        newStake.duration = _duration;
        newStake.end = end;
        newStake.amount = _amount;
        newStake.rewardDebt = newStake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR;
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in earnedToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount should be greator than 0");

        _updatePool();

        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];
        
        bool bUpdatable = true;
        uint256 firstIndex = user.firstIndex;

        uint256 pending = 0;
        uint256 pendingCompound = 0;
        uint256 compounded = 0;
        uint256 remained = _amount;
        for(uint256 j = user.firstIndex; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if(bUpdatable && stake.amount == 0) firstIndex = j;
            if(stake.amount == 0) continue;
            if(remained == 0) break;

            if(j - user.firstIndex > processingLimit) break;

            uint256 _pending = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR - stake.rewardDebt;
            if(stake.end > block.timestamp) {
                pendingCompound = pendingCompound + _pending;

                if(address(stakingToken) != address(earnedToken) && _pending > 0) {
                    uint256 _beforeAmount = stakingToken.balanceOf(address(this));
                    _safeSwap(_pending, earnedToStakedPath, address(this));
                    uint256 _afterAmount = stakingToken.balanceOf(address(this));
                    _pending = _afterAmount - _beforeAmount;
                }
                compounded = compounded + _pending;
                stake.amount = stake.amount + _pending;
            } else {
                pending = pending + _pending;
                if(stake.amount > remained) {
                    stake.amount = stake.amount - remained;
                    remained = 0;
                } else {
                    remained = remained - stake.amount;
                    stake.amount = 0;

                    if(bUpdatable) firstIndex = j;
                }
            }
            stake.rewardDebt = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR;

            if(stake.amount > 0) bUpdatable = false;
        }

        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            earnedToken.safeTransfer(address(msg.sender), pending);
            
            if(totalEarned > pending) {
                totalEarned = totalEarned - pending;
            } else {
                totalEarned = 0;
            }
        }

        if (pendingCompound > 0) {
            require(availableRewardTokens() >= pendingCompound, "Insufficient reward tokens");
            
            if(totalEarned > pendingCompound) {
                totalEarned = totalEarned - pendingCompound;
            } else {
                totalEarned = 0;
            }
            
            emit Deposit(msg.sender, compounded);
        }
        
        uint256 pendingReflection = user.amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION - user.reflectionDebt;
        if (pendingReflection > 0) {
            if(address(dividendToken) == address(0x0)) {
                payable(msg.sender).transfer(pendingReflection);
            } else {
                IERC20(dividendToken).safeTransfer(address(msg.sender), pendingReflection);
            }
            totalReflections = totalReflections - pendingReflection;
        }

        uint256 realAmount = _amount - remained;

        user.firstIndex = firstIndex;
        user.amount = user.amount - realAmount + pendingCompound;
        user.reflectionDebt = user.amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION;

        lockupInfo.totalStaked = lockupInfo.totalStaked - realAmount + pendingCompound;
        totalStaked = totalStaked - realAmount + pendingCompound;

        if(realAmount > 0) {
            if (lockupInfo.withdrawFee > 0) {
                uint256 fee = realAmount * lockupInfo.withdrawFee / 10000;
                stakingToken.safeTransfer(walletA, fee);
                realAmount = realAmount - fee;
            }

            stakingToken.safeTransfer(address(msg.sender), realAmount);
        }

        emit Withdraw(msg.sender, realAmount);
    }

    function claimReward() external payable nonReentrant {
        if(startBlock == 0) return;

        _transferPerformanceFee();
        _updatePool();

        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];

        uint256 pending = 0;
        uint256 pendingCompound = 0;
        uint256 compounded = 0;
        for(uint256 j = user.firstIndex; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if(stake.amount == 0) continue;
            if(j - user.firstIndex > processingLimit) break;

            uint256 _pending = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR - stake.rewardDebt;

            if(stake.end > block.timestamp) {
                pendingCompound = pendingCompound + _pending;

                if(address(stakingToken) != address(earnedToken) && _pending > 0) {
                    uint256 _beforeAmount = stakingToken.balanceOf(address(this));
                    _safeSwap(_pending, earnedToStakedPath, address(this));
                    uint256 _afterAmount = stakingToken.balanceOf(address(this));
                    _pending = _afterAmount - _beforeAmount;
                }
                compounded = compounded + _pending;
                stake.amount = stake.amount + _pending;
            } else {
                pending = pending + _pending;
            }
            stake.rewardDebt = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR;
        }

        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            earnedToken.safeTransfer(address(msg.sender), pending);
            
            if(totalEarned > pending) {
                totalEarned = totalEarned - pending;
            } else {
                totalEarned = 0;
            }
        }

        if (pendingCompound > 0) {
            require(availableRewardTokens() >= pendingCompound, "Insufficient reward tokens");
            
            if(totalEarned > pendingCompound) {
                totalEarned = totalEarned - pendingCompound;
            } else {
                totalEarned = 0;
            }

            user.amount = user.amount + compounded;
            user.reflectionDebt = user.reflectionDebt + compounded * accDividendPerShare / PRECISION_FACTOR_REFLECTION;

            lockupInfo.totalStaked = lockupInfo.totalStaked + compounded;
            totalStaked = totalStaked + compounded;

            emit Deposit(msg.sender, compounded);
        }
    }

    function claimDividend() external payable nonReentrant {
        if(startBlock == 0) return;

        _transferPerformanceFee();
        _updatePool();

        UserInfo storage user = userStaked[msg.sender];
        if (user.amount == 0) return;

        uint256 pendingReflection = user.amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION - user.reflectionDebt;
        if (pendingReflection > 0) {
            if(address(dividendToken) == address(0x0)) {
                payable(msg.sender).transfer(pendingReflection);
            } else {
                IERC20(dividendToken).safeTransfer(address(msg.sender), pendingReflection);
            }
            totalReflections = totalReflections - pendingReflection;
        }
        user.reflectionDebt = user.amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION;
    }

    function compoundReward() external payable nonReentrant {
        if(startBlock == 0) return;

        _transferPerformanceFee();
        _updatePool();

        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];

        uint256 pending = 0;
        uint256 compounded = 0;
        for(uint256 j = user.firstIndex; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if(stake.amount == 0) continue;
            if(j - user.firstIndex > processingLimit) break;

            uint256 _pending = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR - stake.rewardDebt;
            pending = pending + _pending;

            if(address(stakingToken) != address(earnedToken) && _pending > 0) {
                uint256 _beforeAmount = stakingToken.balanceOf(address(this));
                _safeSwap(_pending, earnedToStakedPath, address(this));
                uint256 _afterAmount = stakingToken.balanceOf(address(this));
                _pending = _afterAmount - _beforeAmount;
            }
            compounded = compounded + _pending;

            stake.amount = stake.amount + _pending;
            stake.rewardDebt = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR;
        }

        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            
            if(totalEarned > pending) {
                totalEarned = totalEarned - pending;
            } else {
                totalEarned = 0;
            }

            user.amount = user.amount + compounded;
            user.reflectionDebt = user.reflectionDebt + compounded * accDividendPerShare / PRECISION_FACTOR_REFLECTION;

            lockupInfo.totalStaked = lockupInfo.totalStaked + compounded;
            totalStaked = totalStaked + compounded;

            emit Deposit(msg.sender, compounded);
        }
    }

    function compoundDividend() external payable nonReentrant {
        if(startBlock == 0) return;

        _transferPerformanceFee();
        _updatePool();

        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];

        uint256 pending = user.amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION - user.reflectionDebt;
        if(address(stakingToken) != address(dividendToken) && pending > 0) {
            if(address(dividendToken) == address(0x0)) {
                address wethAddress = IUniRouter02(uniRouterAddress).WETH();
                IWETH(wethAddress).deposit{ value: pending }();
            }
            totalReflections = totalReflections - pending;

            uint256 _beforeAmount = stakingToken.balanceOf(address(this));
            _safeSwap(pending, reflectionToStakedPath, address(this));
            uint256 _afterAmount = stakingToken.balanceOf(address(this));
            pending = _afterAmount - _beforeAmount;
        }

        if(pending > 0) {            
            Stake storage stake = stakes[user.firstIndex];
            stake.amount = stake.amount + pending;
            stake.rewardDebt = stake.rewardDebt + pending * lockupInfo.accTokenPerShare / PRECISION_FACTOR;
        
            user.amount = user.amount + pending;
            user.reflectionDebt = user.amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION;

            lockupInfo.totalStaked = lockupInfo.totalStaked + pending;
            totalStaked = totalStaked + pending;

            emit Deposit(msg.sender, pending);
        }
    }

    function _transferPerformanceFee() internal {
        require(msg.value >= performanceFee, 'should pay small gas to compound or harvest');

        payable(buyBackWallet).transfer(performanceFee);
        if(msg.value > performanceFee) {
            payable(msg.sender).transfer(msg.value - performanceFee);
        }
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];

        uint256 firstIndex = user.firstIndex;
        uint256 amountToTransfer = 0;
        for(uint256 j = user.firstIndex; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if(stake.amount == 0) {
                firstIndex = j;
                continue;
            }
            if(j - user.firstIndex > processingLimit) break;

            amountToTransfer = amountToTransfer + stake.amount;

            stake.amount = 0;
            stake.rewardDebt = 0;
            
            firstIndex = j;
        }

        if (amountToTransfer > 0) {
            stakingToken.safeTransfer(address(msg.sender), amountToTransfer);

            uint256 pendingReflection = user.amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION - user.reflectionDebt;
            totalReflections = totalReflections - pendingReflection;

            user.firstIndex = firstIndex;
            user.amount = user.amount - amountToTransfer;
            user.reflectionDebt = user.amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION;

            lockupInfo.totalStaked = lockupInfo.totalStaked - amountToTransfer;
            totalStaked = totalStaked - amountToTransfer;
        }

        emit EmergencyWithdraw(msg.sender, amountToTransfer);
    }

    function rewardPerBlock() external view returns (uint256) {
        return lockupInfo.rate;
    }

    /**
     * @notice Available amount of reward token
     */
    function availableRewardTokens() public view returns (uint256) {
        if(address(earnedToken) == address(dividendToken)) return totalEarned;

        uint256 _amount = earnedToken.balanceOf(address(this));
        if (address(earnedToken) == address(stakingToken)) {
            if (_amount < totalStaked) return 0;
            return _amount - totalStaked;
        }

        return _amount;
    }

    /**
     * @notice Available amount of reflection token
     */
    function availabledividendTokens() public view returns (uint256) {
        if(address(dividendToken) == address(0x0)) {
            return address(this).balance;
        }

        uint256 _amount = IERC20(dividendToken).balanceOf(address(this));
        
        if(address(dividendToken) == address(earnedToken)) {
            if(_amount < totalEarned) return 0;
            _amount = _amount - totalEarned;
        }

        if(address(dividendToken) == address(stakingToken)) {
            if(_amount < totalStaked) return 0;
            _amount = _amount - totalStaked;
        }

        return _amount;
    }

    function userInfo(address _account) external view returns (uint256 amount, uint256 available, uint256 locked) {
        UserInfo memory user = userStaked[msg.sender];
        Stake[] memory stakes = userStakes[_account];
        
        for(uint256 i = user.firstIndex; i < stakes.length; i++) {
            Stake memory stake = stakes[i];
            if(stake.amount == 0) continue;
            
            amount = amount + stake.amount;
            if(block.timestamp > stake.end) {
                available = available + stake.amount;
            } else {
                locked = locked + stake.amount;
            }
        }
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _account) external view returns (uint256) {
        if(startBlock == 0) return 0;

        UserInfo memory user = userStaked[_account];
        Stake[] memory stakes = userStakes[_account];

        if(lockupInfo.totalStaked == 0) return 0;
        
        uint256 adjustedTokenPerShare = lockupInfo.accTokenPerShare;
        if (block.number > lockupInfo.lastRewardBlock && lockupInfo.totalStaked != 0 && lockupInfo.lastRewardBlock > 0) {
            uint256 multiplier = _getMultiplier(lockupInfo.lastRewardBlock, block.number);
            uint256 reward = multiplier * lockupInfo.rate;
            adjustedTokenPerShare =
                lockupInfo.accTokenPerShare + (
                    reward * PRECISION_FACTOR / lockupInfo.totalStaked
                );
        }

        uint256 pending = 0;
        for(uint256 i = user.firstIndex; i < stakes.length; i++) {
            Stake memory stake = stakes[i];
            if(stake.amount == 0) continue;

            pending = pending + (
                stake.amount * adjustedTokenPerShare / PRECISION_FACTOR - stake.rewardDebt
            );
        }
        return pending;
    }

    function pendingDividends(address _account) external view returns (uint256) {
        if(startBlock == 0) return 0;
        if(totalStaked == 0) return 0;
        
        UserInfo memory user = userStaked[_account];
        if(user.amount == 0) return 0;

        uint256 reflectionAmount = availabledividendTokens();
        uint256 sTokenBal = stakingToken.balanceOf(address(this));
        if(address(stakingToken) == dividendToken) {
            sTokenBal = sTokenBal - reflectionAmount;
        }

        uint256 adjustedReflectionPerShare = accDividendPerShare + (
                (reflectionAmount - totalReflections) * PRECISION_FACTOR_REFLECTION / sTokenBal
            );
        
        uint256 pendingReflection = user.amount * adjustedReflectionPerShare / PRECISION_FACTOR_REFLECTION - user.reflectionDebt;
        return pendingReflection;
    }

    /************************
    ** Admin Methods
    *************************/
    function harvest() external onlyOwner {
        _updatePool();

        uint256 _amount = stakingToken.balanceOf(address(this));
        _amount = _amount - totalStaked;

        uint256 pendingReflection = _amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION - reflectionDebt;
        if(pendingReflection > 0) {
            if(address(dividendToken) == address(0x0)) {
                payable(walletA).transfer(pendingReflection);
            } else {
                IERC20(dividendToken).safeTransfer( walletA, pendingReflection);
            }
            totalReflections = totalReflections - pendingReflection;
        }
        
        reflectionDebt = _amount * accDividendPerShare / PRECISION_FACTOR_REFLECTION;
    }

    /*
     * @notice Deposit reward token
     * @dev Only call by owner. Needs to be for deposit of reward token when reflection token is same with reward token.
     */
    function depositRewards(uint _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "invalid amount");

        uint256 beforeAmt = earnedToken.balanceOf(address(this));
        earnedToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 afterAmt = earnedToken.balanceOf(address(this));

        totalEarned = totalEarned + afterAmt - beforeAmt;
    }

    /*
     * @notice Withdraw reward token
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require( block.number > bonusEndBlock, "Pool is running");
        require(availableRewardTokens() >= _amount, "Insufficient reward tokens");

        earnedToken.safeTransfer(address(msg.sender), _amount);
        
        if (totalEarned > 0) {
            if (_amount > totalEarned) {
                totalEarned = 0;
            } else {
                totalEarned = totalEarned - _amount;
            }
        }
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(
            _tokenAddress != address(earnedToken),
            "Cannot be reward token"
        );

        if(_tokenAddress == address(stakingToken)) {
            uint256 tokenBal = stakingToken.balanceOf(address(this));
            require(_tokenAmount <= tokenBal - totalStaked, "Insufficient balance");
        }

        if(_tokenAddress == address(0x0)) {
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        }

        emit AdminTokenRecovered(_tokenAddress, _tokenAmount);
    }

    function startReward() external onlyOwner {
        require(startBlock == 0, "Pool was already started");

        startBlock = block.number + 100;
        bonusEndBlock = startBlock + duration * 6426;
        lockupInfo.lastRewardBlock = startBlock;
        
        emit NewStartAndEndBlocks(startBlock, bonusEndBlock);
    }

    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
        emit RewardsStop(bonusEndBlock);
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser( bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        if (_hasUserLimit) {
            require(
                _poolLimitPerUser > poolLimitPerUser,
                "New limit must be higher"
            );
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            poolLimitPerUser = 0;
        }
        hasUserLimit = _hasUserLimit;

        emit UpdatePoolLimit(poolLimitPerUser, hasUserLimit);
    }

    function updateLockup(uint256 _duration, uint256 _depositFee, uint256 _withdrawFee, uint256 _rate) external onlyOwner {
        // require(block.number < startBlock, "Pool was already started");
        require(_depositFee < 2000, "Invalid deposit fee");
        require(_withdrawFee < 2000, "Invalid withdraw fee");

        _updatePool();

        lockupInfo.duration = _duration;
        lockupInfo.depositFee = _depositFee;
        lockupInfo.withdrawFee = _withdrawFee;
        lockupInfo.rate = _rate;
        
        emit LockupUpdated(_duration, _depositFee, _withdrawFee, _rate);
    }

    function setServiceInfo(address _addr, uint256 _fee) external {
        require(msg.sender == buyBackWallet, "setServiceInfo: FORBIDDEN");
        require(_addr != address(0x0), "Invalid address");
        require(_fee < 0.05 ether, "fee cannot exceed 0.05 ether");

        buyBackWallet = _addr;
        performanceFee = _fee;

        emit ServiceInfoUpadted(_addr, _fee);
    }
    
    function setDuration(uint256 _duration) external onlyOwner {
        require(startBlock == 0, "Pool was already started");

        duration = _duration;
        emit DurationUpdated(_duration);
    }
    
    function setProcessingLimit(uint256 _limit) external onlyOwner {
        require(_limit > 0, "Invalid limit");
        processingLimit = _limit;
    }

    function setSettings(
        uint256 _slippageFactor, 
        address _uniRouter, 
        address[] memory _earnedToStakedPath, 
        address[] memory _reflectionToStakedPath
    ) external onlyOwner {
        require(_slippageFactor <= slippageFactorUL, "_slippageFactor too high");

        slippageFactor = _slippageFactor;
        uniRouterAddress = _uniRouter;
        reflectionToStakedPath = _reflectionToStakedPath;
        earnedToStakedPath = _earnedToStakedPath;

        emit SetSettings(_slippageFactor, _uniRouter, _earnedToStakedPath, _reflectionToStakedPath);
    }
    
    function updateWalletA(address _walletA) external onlyOwner {
        require(_walletA != address(0x0) || _walletA != walletA, "Invalid address");

        walletA = _walletA;
        emit WalletAUpdated(_walletA);
    }

    /************************
    ** Internal Methods
    *************************/
    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        // calc reflection rate
        if(totalStaked > 0) {
            uint256 reflectionAmount = availabledividendTokens();
            uint256 sTokenBal = stakingToken.balanceOf(address(this));
            if(address(stakingToken) == dividendToken) {
                sTokenBal = sTokenBal - reflectionAmount;
            }

            accDividendPerShare = accDividendPerShare + (
                    (reflectionAmount - totalReflections) * PRECISION_FACTOR_REFLECTION / sTokenBal
                );

            totalReflections = reflectionAmount;
        }

        if (block.number <= lockupInfo.lastRewardBlock || lockupInfo.lastRewardBlock == 0) return;

        if (lockupInfo.totalStaked == 0) {
            lockupInfo.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lockupInfo.lastRewardBlock, block.number);
        uint256 _reward = multiplier * lockupInfo.rate;
        lockupInfo.accTokenPerShare = lockupInfo.accTokenPerShare + (
            _reward * PRECISION_FACTOR / lockupInfo.totalStaked
        );
        lockupInfo.lastRewardBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    function _safeSwap(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length - 1];
        
        IERC20(_path[0]).safeApprove(uniRouterAddress, _amountIn);
        IUniRouter02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            amountOut * slippageFactor / 1000,
            _path,
            _to,
            block.timestamp + 600
        );
    }

    receive() external payable {}
}