//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import "./LibUniswapV3Stake.sol";
import "./INonfungiblePositionManager.sol";

/// @title The base storage of stakeContract
contract StakeUniswapV3Storage {
    /// @dev reward token : TOS
    address public token;

    /// @dev registry
    address public stakeRegistry;

    /// @dev A vault that holds tos rewards.
    address public vault;

    /// @dev the total minied amount
    uint256 public miningAmountTotal;

    /// @dev Rewards have been allocated,
    ///      but liquidity is lost, and burned amount .
    uint256 public nonMiningAmountTotal;

    /// @dev the total staked amount
    uint256 public totalStakedAmount;

    /// @dev user's tokenIds
    mapping(address => uint256[]) public userStakedTokenIds;

    /// @dev  Deposited token ID information
    mapping(uint256 => LibUniswapV3Stake.StakeLiquidity) public depositTokens;

    /// @dev Amount that Token ID put into Coinage
    mapping(uint256 => LibUniswapV3Stake.StakedTokenAmount)
        public stakedCoinageTokens;

    /// @dev Total staked information of users
    mapping(address => LibUniswapV3Stake.StakedTotalTokenAmount)
        public userTotalStaked;

    /// @dev total stakers
    uint256 public totalStakers;

    /// @dev lock
    uint256 internal _lock;

    /// @dev flag for pause proxy
    bool public pauseProxy;

    /// @dev stakeStartTime is set when staking for the first time
    uint256 public stakeStartTime;

    /// @dev saleStartTime
    uint256 public saleStartTime;

    /// @dev Mining interval can be given to save gas cost.
    uint256 public miningIntervalSeconds;

    /// @dev pools's token
    address public poolToken0;
    address public poolToken1;
    address public poolAddress;
    uint256 public poolFee;

    /// @dev Rewards per second liquidity inside (3년간 8000000 TOS)
    /// uint256 internal MINING_PER_SECOND = 84559445290038900;

    /// @dev UniswapV3 Nonfungible position manager
    INonfungiblePositionManager public nonfungiblePositionManager;

    /// @dev UniswapV3 pool factory
    address public uniswapV3FactoryAddress;

    /// @dev coinage for reward 리워드 계산을 위한 코인에이지
    address public coinage;

    /// @dev  recently mined time (in seconds)
    uint256 public coinageLastMintBlockTimetamp;

    /// @dev total tokenIds
    uint256 public totalTokens;

    ///@dev for migrate L2
    bool public migratedL2;

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "StakeUniswapV3Storage: zero address");
        _;
    }
    modifier lock() {
        require(_lock == 0, "StakeUniswapV3Storage: LOCKED");
        _lock = 1;
        _;
        _lock = 0;
    }
}
