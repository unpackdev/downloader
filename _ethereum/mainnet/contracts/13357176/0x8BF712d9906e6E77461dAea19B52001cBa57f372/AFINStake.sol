// "SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.8.7;

import "./AccessControlEnumerable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract AFINStake is AccessControlEnumerable
{
    using SafeMath for uint256;

    event Stake(
        address indexed user,
        uint256 indexed poolId,
        string btcWallet
    );

    event Unstake(
        address indexed user,
        uint256 indexed poolId
    );

    struct StakeInfo {
        uint256 poolId;
        uint256 timestamp;
        string btcWallet;
        bool locked;
    }

    struct PoolInfo {
        uint256 btcRewardAmount;
        uint256 afinStakeAmount;
        uint256 stakeLimit;
        uint256 stakeCount;
    }

    IERC20 public afin;
    IERC20 public btc;

    uint256 public lockupPeriod;

    // pool id => pool id
    mapping(uint256 => PoolInfo) public pools;

    // wallet address => stake info
    mapping(address => StakeInfo) public stakes;

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    constructor(
        address _admin, 
        address _afin, 
        address _btc)  
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        afin = IERC20(_afin);
        btc = IERC20(_btc);

        lockupPeriod = 180 days; // 6 months

        // pool 0
        pools[0] = PoolInfo(
            1e18,          // 1 BTC
            1000000 * 1e8, // 1M AFIN
            10,            // limited to 10 users
            0
        );
        
        // pool 1
        pools[1] = PoolInfo(
            1e17,          // 0.1 BTC
            150000 * 1e8,  // 150K AFIN
            200,           // limited to 200 users
            0
        );
    }

    function stake(uint256 poolId, string calldata btcWallet) external
    {
        PoolInfo storage poolInfo = pools[poolId];
        require(poolInfo.stakeLimit > 0, "invalid pool id");
        require(poolInfo.stakeLimit > poolInfo.stakeCount, "exceed stake limit");

        StakeInfo memory stakeInfo = stakes[msg.sender];
        require(stakeInfo.timestamp == 0, "already staked");

        stakes[msg.sender] = StakeInfo(poolId, currentTime(), btcWallet, true);

        poolInfo.stakeCount = poolInfo.stakeCount.add(1);

        afin.transferFrom(msg.sender, address(this), poolInfo.afinStakeAmount);
        btc.transfer(msg.sender, poolInfo.btcRewardAmount);

        emit Stake(msg.sender, poolId, btcWallet);
    }

    function unstake() external
    {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.timestamp > 0, "no stake");
        require(stakeInfo.locked, "already unstaked");

        uint256 timeDelta = currentTime().sub(stakeInfo.timestamp);
        require(timeDelta >= lockupPeriod, "locked");

        stakeInfo.locked = false;

        PoolInfo memory poolInfo = pools[stakeInfo.poolId];
        afin.transfer(msg.sender, poolInfo.afinStakeAmount);

        emit Unstake(msg.sender, stakeInfo.poolId);
    }

    function claimTokens(address token) external onlyAdmin
    {
        require(token != address(afin));
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, amount);
    }

    function currentTime() internal virtual view returns (uint256)
    {
        return block.timestamp;
    }
}