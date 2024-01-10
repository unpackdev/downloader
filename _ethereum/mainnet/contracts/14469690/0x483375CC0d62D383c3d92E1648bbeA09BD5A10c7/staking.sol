// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IWrappedNative is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract SwapRewardsChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardBlock; // Last block number that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated reward per share, times 1e18. See below.
        uint256 currentDepositAmount; // Current total deposit amount in this pool
    }

    address public wrappedNativeAddress;

    // The reward token
    IERC20 public rewardToken;
    // Reward tokens created per block.
    uint256 public rewardsPerBlock;

    // Emission Settings
    uint256 public denominationEmitAmount; //Blocks
    uint256 public minimumEmitAmount = 0; //Min Output Per Block
    uint256 public maximumEmitAmount = 1 ether; //Max Output Per Block

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when mining starts.
    uint256 public startBlock;

    uint256 public remainingRewards = 0;

    // router
    IUniswapV2Router02 public router;

    // handler
    address public handler;

    event Harvest(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event UpdateEmissionSettings(
        address indexed user,
        uint256 denomination,
        uint256 minimum,
        uint256 maximum,
        uint256 rewardsPerBlock
    );
    event RescueTokens(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event RegisterMovedStakers();

    constructor(
        address _stakeToken, // Token staked (e.g eterna)
        address _rewardToken, // Token distributed to the user
        address _router, // router
        uint256 _denominationEmitAmount // How many blocks should the rewards last?
    ) public {
        rewardToken = IERC20(_rewardToken);

        poolInfo.push(
            PoolInfo({
        lpToken : IERC20(_stakeToken),
        allocPoint : 100,
        lastRewardBlock : startBlock,
        accRewardPerShare : 0,
        currentDepositAmount : 0
        })
        );

        router = IUniswapV2Router02(_router);
        wrappedNativeAddress = router.WETH();
        denominationEmitAmount = _denominationEmitAmount;
        totalAllocPoint = 100;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
    private
    pure
    returns (uint256)
    {
        return _to.sub(_from);
    }

    // View function to see pending rewards on frontend.
    function pendingRewards(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.currentDepositAmount;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            //calculate total rewards based on remaining funds
            if (remainingRewards > 0) {
                uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                uint256 totalRewards = multiplier
                .mul(rewardsPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
                totalRewards = Math.min(totalRewards, remainingRewards);
                accRewardPerShare = accRewardPerShare.add(
                    totalRewards.mul(1e18).div(lpSupply)
                );
            }
        }
        return user.amount.mul(accRewardPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = poolInfo[0];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.currentDepositAmount;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        if (remainingRewards == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        //calculate total rewards based on remaining funds
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 totalRewards = multiplier
        .mul(rewardsPerBlock)
        .mul(pool.allocPoint)
        .div(totalAllocPoint);
        totalRewards = Math.min(totalRewards, remainingRewards);
        remainingRewards = remainingRewards.sub(totalRewards);
        pool.accRewardPerShare = pool.accRewardPerShare.add(
            totalRewards.mul(1e18).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    function income(uint256 _amount) external nonReentrant {
        updatePool();
        uint256 before = rewardToken.balanceOf(address(this));
        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = rewardToken.balanceOf(address(this)).sub(before);
        remainingRewards = remainingRewards.add(_amount);
        updateEmissionRate();
    }

    function updateEmissionRate() private {
        if (remainingRewards > 0) {
            rewardsPerBlock = remainingRewards.div(denominationEmitAmount);
            rewardsPerBlock = Math.min(maximumEmitAmount, rewardsPerBlock);
            rewardsPerBlock = Math.max(minimumEmitAmount, rewardsPerBlock);
        } else {
            rewardsPerBlock = 0;
        }
    }

    // Deposit LP tokens to Chef
    function deposit(uint256 _amount) public nonReentrant {
        require(msg.sender == handler);
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e18).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                safeRewardTransfer(msg.sender, pending, (msg.sender == handler));
                emit Harvest(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            // We add checks for fee tokens
            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)).sub(before);
            user.amount = user.amount.add(_amount);
            pool.currentDepositAmount = pool.currentDepositAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e18);
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw LP tokens from Chef.
    function withdraw(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e18).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeRewardTransfer(msg.sender, pending, (msg.sender == handler));
            emit Harvest(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.currentDepositAmount = pool.currentDepositAmount.sub(_amount);
            pool.lpToken.safeTransfer(msg.sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e18);
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.currentDepositAmount = pool.currentDepositAmount.sub(amount);
        pool.lpToken.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    struct Stake {
        address user;
        uint256 amount;
    }

    function registerStakes(Stake[] memory _array, uint256 _sumAmount) external onlyOwner {
        PoolInfo storage pool = poolInfo[0];
        for (uint i = 0; i < _array.length; i++) {
            UserInfo memory user;
            user.amount = user.amount.add(_array[i].amount);
        }
        pool.currentDepositAmount = pool.currentDepositAmount.add(_sumAmount);
        emit RegisterMovedStakers();
    }

    // Safe rewards transfer function, just in case if rounding error causes pool to not have enough tokens.    // Safe rewards transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeRewardTransfer(
        address _to,
        uint256 _amount,
        bool _convert
    ) internal {
        PoolInfo memory pool = poolInfo[0];
        if (address(rewardToken) == wrappedNativeAddress) {
            uint256 balance = rewardToken.balanceOf(address(this));
            uint256 transferAmount = Math.min(balance, _amount);

            if (_convert) {
                rewardToken.transfer(_to, transferAmount);
            } else {
                // We swap and send the result
                address[] memory path;
                path[0] = address(rewardToken);
                path[1] = address(pool.lpToken);

                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    transferAmount,
                    0,
                    path,
                    _to,
                    block.timestamp + 60
                );
            }
        } else if (address(rewardToken) == address(pool.lpToken)) {
            // Add a check to prevent stealing from users'funds to pay the rewards
            uint256 balance = rewardToken.balanceOf(address(this)) >
            pool.currentDepositAmount
            ? rewardToken.balanceOf(address(this)) - pool.currentDepositAmount
            : 0;
            uint256 transferAmount = Math.min(balance, _amount);
            rewardToken.transfer(_to, transferAmount);
        } else {
            uint256 balance = rewardToken.balanceOf(address(this));
            uint256 transferAmount = Math.min(balance, _amount);
            if (_convert) {
                rewardToken.transfer(_to, transferAmount);
                // We swap and send the result
                address[] memory path;
                path[0] = address(rewardToken);
                path[1] = wrappedNativeAddress;
                path[2] = address(pool.lpToken);

                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    transferAmount,
                    0,
                    path,
                    _to,
                    block.timestamp + 60
                );
            } else {
                rewardToken.transfer(_to, transferAmount);
            }
        }
    }

    //For unwrapping native tokens
    receive() external payable {}

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, "safeTransferETH: ETH_TRANSFER_FAILED");
    }

    function updateEmissionSettings(
        uint256 denomination,
        uint256 minimum,
        uint256 maximum
    ) external onlyOwner {
        updatePool();
        denominationEmitAmount = denomination;
        minimumEmitAmount = minimum;
        maximumEmitAmount = maximum;
        updateEmissionRate();

        emit UpdateEmissionSettings(
            msg.sender,
            denomination,
            minimum,
            maximum,
            rewardsPerBlock
        );
    }

    function rescueToken(address token, address addressForReceive, uint amount)
    external
    onlyOwner
    {
        IERC20(token).safeTransfer(addressForReceive, amount);
        emit RescueTokens(msg.sender, token, amount);
    }

    function updateHandler(address _handler) external onlyOwner {
        handler = _handler;
    }

}