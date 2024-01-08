// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";

contract SHFLFarmer is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 staked; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 claimed; // Tracks the amount of CARDS claimed by the user.
    }

    struct PoolInfo {
        IERC20 token; // Address of token contract.
        IERC20 lpToken; // Address of LP token contract.
        uint256 apr; // Fixed APR for the pool. Determines how many CARDS to distribute per block.
        uint256 lastRewardBlock; // Last block number that CARDS rewards were distributed.
        uint256 accCardsPerShare; // Accumulated CARDS per share, times 1e12. See below.
    }

    IERC20 cards; 
    IERC20 internal weth;
    IERC20 internal usdc;
    address internal usdcPoolAddress;
    address internal cardsPoolAddress;
    address internal rewardSource;
    PoolInfo[] public poolInfo;
    mapping(address => bool) public existingPools;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping(address => bool) public contractWhitelist;
    uint256 public startBlock;
    uint256 internal constant APPROX_BLOCKS_PER_YEAR  = uint256(uint256(365 days) / uint256(13 seconds));
    uint256 lockPeriod = 30*24*60*60;
    uint256 burnPercent = 5;
    mapping (address => uint256) public lockTime;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 option);
    event Claim(address indexed user, uint256 indexed pid, uint256 cardsAmount);
    event ClaimAll(address indexed user, uint256 cardsAmount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(address _cards, address _weth, address _usdc, address _usdcPoolAddress, address _cardsPoolAddress, address _rewardSource, uint256 _startBlock) public {
        weth = IERC20(_weth); 
        usdc = IERC20(_usdc);
        usdcPoolAddress = _usdcPoolAddress;
        cardsPoolAddress = _cardsPoolAddress;
        rewardSource = _rewardSource;
        cards = IERC20(_cards);
        startBlock = _startBlock;
    }

    function addPool(address _token, address _lpToken, uint256 _apr) public onlyOwner {
        require(existingPools[_lpToken] != true, "pool exists");

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;

        poolInfo.push(
            PoolInfo({
                token: IERC20(_token),
                lpToken: IERC20(_lpToken),
                apr: _apr,
                lastRewardBlock: lastRewardBlock,
                accCardsPerShare: 0
            })
        );

        existingPools[_lpToken] = true;
    }

    function pendingCards(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accCardsPerShare = pool.accCardsPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 cardsReward = _calculateCardsReward(_pid, lpSupply);
            accCardsPerShare = accCardsPerShare.add(cardsReward.mul(1e12).div(lpSupply));
        }
        return user.staked.mul(accCardsPerShare).div(1e12).sub(user.rewardDebt);
    }

    function _calculateCardsReward(uint256 _pid, uint256 _lpSupply) internal view returns (uint256 cardsReward) {
        PoolInfo memory pool = poolInfo[_pid];
        uint256 multiplier = block.number.sub(pool.lastRewardBlock);
        
        uint256 cardsPrice = _getCardsPrice(); 
        uint256 lpTokenPrice = 10**18 * 2 * weth.balanceOf(address(pool.lpToken)) / pool.lpToken.totalSupply();
        uint256 scaledTotalLiquidityValue = _lpSupply * lpTokenPrice;
        cardsReward = multiplier * ((pool.apr * scaledTotalLiquidityValue / cardsPrice) / APPROX_BLOCKS_PER_YEAR) / 100;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function _getCardsPrice() internal view returns (uint256 cardsPrice) {
        // uint256 usdcBalance = usdc.balanceOf(usdcPoolAddress);
        // if (usdcBalance > 0) {
        //     cardsPrice = 10**4 * weth.balanceOf(usdcPoolAddress) / usdcBalance;
        // }
        uint256 cardsBalance = cards.balanceOf(cardsPoolAddress);
        if (cardsBalance > 0) {
            cardsPrice = 10**18 * weth.balanceOf(cardsPoolAddress) / cardsBalance;
        }
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        require(msg.sender == tx.origin || msg.sender == owner() || contractWhitelist[msg.sender] == true, "no contracts");
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number <= pool.lastRewardBlock) { return; }
        if (lpSupply == 0) { pool.lastRewardBlock = block.number; }
        uint256 cardsReward = _calculateCardsReward(_pid, lpSupply);
        if (cardsReward > 0) {
            // cards.mint(address(this), cardsReward);
            cards.transferFrom(rewardSource, address(this), cardsReward);
            pool.accCardsPerShare  = pool.accCardsPerShare.add(cardsReward.mul(1e12).div(lpSupply));
            pool.lastRewardBlock = block.number;
        }
    }

    function deposit(uint256 _pid, uint256 _amount, uint256 _option) external {
        require(msg.sender == tx.origin || contractWhitelist[msg.sender] == true, "no contracts");
        require(_option == 1 || _option == 2, "Invalid Option");
        require(_amount > 0, "amount cannot be 0");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 burnAmount;
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        if (_option == 1) {
            burnAmount = _amount.mul(burnPercent).div(100);
            pool.lpToken.safeTransfer(rewardSource, burnAmount);
            _amount = _amount.sub(burnAmount);
        } else if (_option == 2) {
            lockTime[msg.sender] = now.add(lockPeriod);
        }
        uint256 userCardsPending = user.staked.mul(pool.accCardsPerShare).div(1e12).sub(user.rewardDebt);
        if (userCardsPending > 0) {
            user.claimed += userCardsPending;
            _safeCardsTransfer(msg.sender, userCardsPending);
            emit Claim(msg.sender, _pid, userCardsPending);
        }
        user.staked = user.staked.add(_amount);
        user.rewardDebt = user.staked.mul(pool.accCardsPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount, _option);
    }

    function claim(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 userCardsPending = user.staked.mul(pool.accCardsPerShare).div(1e12).sub(user.rewardDebt);
        if (userCardsPending > 0) {
            user.claimed += userCardsPending;
            _safeCardsTransfer(msg.sender, userCardsPending);
            emit Claim(msg.sender, _pid, userCardsPending);
        }
        user.rewardDebt = user.staked.mul(pool.accCardsPerShare).div(1e12);
    }

    function claimAll() public {
        uint256 totalPendingCards = 0;
        for(uint256 pid=0; pid < poolInfo.length; ++pid) {
            UserInfo storage user = userInfo[pid][msg.sender];
            if (user.staked > 0) {
                updatePool(pid);
                PoolInfo storage pool = poolInfo[pid];
                uint256 accCardsPerShare = pool.accCardsPerShare;
                uint256 pendingPoolCardsRewards = user.staked.mul(accCardsPerShare).div(1e12).sub(user.rewardDebt);
                user.claimed = user.claimed.add(pendingPoolCardsRewards);
                totalPendingCards = totalPendingCards.add(pendingPoolCardsRewards);
                user.rewardDebt = user.staked.mul(accCardsPerShare).div(1e12);
            }
        }

        require(totalPendingCards > 0, "no claimable cards");
        _safeCardsTransfer(msg.sender, totalPendingCards);
        emit ClaimAll(msg.sender, totalPendingCards);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        require(lockTime[msg.sender] <= now, "withdraw: stake is locked");
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0 && user.staked >= _amount, "withdraw: not enough balance");
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);
        uint256 userCardsPending = user.staked.mul(pool.accCardsPerShare).div(1e12).sub(user.rewardDebt);
        if (userCardsPending > 0) {
            user.claimed += userCardsPending;
            _safeCardsTransfer(msg.sender, userCardsPending);
            emit Claim(msg.sender, _pid, userCardsPending);
        }
        user.staked = user.staked.sub(_amount);
        user.rewardDebt = user.staked.mul(pool.accCardsPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 staked = user.staked;
        require(staked > 0, "no stake");
        user.staked = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), staked);
        emit EmergencyWithdraw(msg.sender, _pid, staked);
    }

    function _safeCardsTransfer(address _to, uint256 _amount) internal {
        uint256 cardsBalance = cards.balanceOf(address(this));
        if (_amount > cardsBalance) _amount = cardsBalance;
        cards.transfer(_to, _amount);
    }

    function setApr(uint256 _pid, uint256 _apr) external onlyOwner {
        updatePool(_pid);
        poolInfo[_pid].apr = _apr;
    }

    function setBurnPercent(uint256 _burnPercent) external onlyOwner {
        burnPercent = _burnPercent;
    }

    function setLockPeriod(uint256 _lockPeriod) external onlyOwner {
        lockPeriod = _lockPeriod;
    }

    function addToWhitelist(address _contractAddress) public onlyOwner {
        contractWhitelist[_contractAddress] = true;
    }

    function removeFromWhitelist(address _contractAddress) public onlyOwner {
        contractWhitelist[_contractAddress] = false;
    }

    function getPoolInfo(uint256 _pid) external view returns (address, address, uint256, uint256, uint256, uint256, uint256, uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        uint256 lpTokenPrice = 10**18 * 2 * weth.balanceOf(address(pool.lpToken)) / pool.lpToken.totalSupply();
        uint256 usdcBalance = usdc.balanceOf(usdcPoolAddress);
        uint256 ethPrice = 10**6 * weth.balanceOf(usdcPoolAddress) / usdcBalance;
        return (address(pool.token), address(pool.lpToken), pool.apr, pool.lpToken.balanceOf(address(this)), lpTokenPrice, ethPrice, pool.lastRewardBlock, pool.accCardsPerShare);
    }

    function getUserInfo(uint256 _pid, address _account) external view returns(uint256, uint256, uint256) {
        UserInfo memory user = userInfo[_pid][_account];
        PoolInfo memory pool = poolInfo[_pid];
        uint256 rewards = pendingCards(_pid, _account);
        uint256 lpTokenPrice = 10**18 * 2 * weth.balanceOf(address(pool.lpToken)) / pool.lpToken.totalSupply();
        return (user.staked, rewards, lpTokenPrice);
    }
}