// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IEmiERC20.sol";
import "./IEmiRouter.sol";
import "./IEmiswap.sol";

contract EmiStaking02 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //-----------------------------------------------------------------------------------
    // Data Structures
    //-----------------------------------------------------------------------------------
    struct LockRecord {
        uint256 amountLocked; // Amount of locked tokens in total
        uint64 lockDate; // when lock is made
        uint64 unlockDate; // when lock is made
        uint128 isWithdrawn; // whether or not it is withdrawn already
        uint256 id;
    }

    event StartStaking(
        address wallet,
        uint256 startDate,
        uint256 stopDate,
        uint256 stakeID,
        address token,
        uint256 amount
    );

    event StakesClaimed(address indexed beneficiary, uint256 stakeId, uint256 amount);
    event LockPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);

    //-----------------------------------------------------------------------------------
    // Variables, Instances, Mappings
    //-----------------------------------------------------------------------------------
    /* Real beneficiary address is a param to this mapping */
    mapping(address => LockRecord[]) private locksTable;

    address public lockToken;
    uint256 public lockPeriod;
    uint256 public stakingEndDate;
    uint256 public stakingLastUnlock;
    uint256 public maxUSDStakes;

    address public emiRouter;
    address[] public pathToStables;
    uint8 public tokenMode; // 0 = simple ERC20 token, 1 = Emiswap LP-token

    /**
     * @dev Constructor for the smartcontract
     * @param _token Token to stake
     * @param _lockPeriod Amount of days to stake (30 days, 60 days etc.)
     * @param _maxUSDValue Maximum stakes value in USD per single staker (value in $)
     * @param _router EmiRouter address
     * @param _path Path to stable coins from stake token
     */
    constructor(
        address _token,
        uint256 _lockPeriod,
        uint256 _maxUSDValue,
        address _router,
        address [] memory _path
    ) public {
        require(_token != address(0), "Token address cannot be empty");
        require(_router != address(0), "Router address cannot be empty");
        require(_path.length > 0, "Path to stable coins must exist");
        require(_lockPeriod > 0, "Lock period cannot be 0");
        lockToken = _token;
        stakingEndDate = block.timestamp + _lockPeriod;
        lockPeriod = _lockPeriod;
        emiRouter = _router;
        stakingLastUnlock = stakingEndDate + _lockPeriod;
        pathToStables = _path;
        maxUSDStakes = _maxUSDValue; // 100000 by default
        tokenMode = 0; // simple ERC20 token by default
    }

    /**
     * @dev Stake tokens to contract
     * @param amount Amount of tokens to stake
     */
    function stake(uint256 amount) external {
        require(block.timestamp < stakingEndDate, "Staking is over");
        require(_checkMaxUSDCondition(msg.sender, amount) == true, "Max stakes values in USD reached");
        IERC20(lockToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256 stakeId = uint256(
            keccak256(abi.encodePacked("Emiswap", block.timestamp, block.difficulty, block.gaslimit))
        );
        locksTable[msg.sender].push(
            LockRecord({
                amountLocked: amount,
                lockDate: uint64(block.timestamp),
                unlockDate: uint64(block.timestamp + lockPeriod),
                id: stakeId,
                isWithdrawn: 0
            })
        );
        emit StartStaking(msg.sender, block.timestamp, block.timestamp + lockPeriod, stakeId, lockToken, amount);
    }

    /**
     * @dev Withdraw all unlocked tokens not withdrawn already
     */
    function withdraw() external {
        LockRecord[] memory t = locksTable[msg.sender];
        uint256 _bal;

        for (uint256 i = 0; i < t.length; i++) {
            if (t[i].isWithdrawn == 0 && (block.timestamp >= t[i].unlockDate || block.timestamp >= stakingLastUnlock)) {
                _bal = _bal.add(t[i].amountLocked);
                locksTable[msg.sender][i].isWithdrawn = 1;
                emit StakesClaimed(msg.sender, t[i].id, t[i].amountLocked);
            }
        }

        require(_bal > 0, "No stakes to withdraw");

        IERC20(lockToken).safeTransfer(msg.sender, _bal);
    }

    /**
     * @dev Return length of stakers' stake array. Admin only
     * @param staker Address of staker to pull data for
     */
    function getStakesLen(address staker) external view onlyOwner returns (uint256) {
        return locksTable[staker].length;
    }

    /**
     * @dev Return stake record for the specified staker. Admin only
     * @param staker Address of staker to pull data for
     * @param idx Index of stake record in array
     */
    function getStake(address staker, uint256 idx) external view onlyOwner returns (LockRecord memory) {
        require(idx < locksTable[staker].length, "Idx is wrong");

        return locksTable[staker][idx];
    }

    /**
     * @dev Return length of callee stake array.
     */
    function getMyStakesLen() external view returns (uint256) {
        return locksTable[msg.sender].length;
    }

    /**
     * @dev Return stake record for the callee.
     * @param idx Index of stake record in array
     */
    function getMyStake(uint256 idx) external view returns (LockRecord memory) {
        require(idx < locksTable[msg.sender].length, "Idx is wrong");

        return locksTable[msg.sender][idx];
    }

    /**
     * @dev Return amount of unlocked tokens ready to be claimed for the specified staker. Admin only
     * @param staker Address of staker to pull data for
     */
    function unlockedBalanceOf(address staker) external view onlyOwner returns (uint256, uint256) {
        uint256 _bal = _getBalance(staker, true);
        return (_bal, _getUSDValue(_bal));
    }

    /**
     * @dev Return amount of all staked tokens for the callee staker.
     */
    function balanceOf() external view returns (uint256, uint256) {
        uint256 _bal = _getBalance(msg.sender, false);
        return (_bal, _getUSDValue(_bal));
    }

    /**
     * @dev Return amount of unlocked tokens ready to be claimed by the callee
     */
    function myUnlockedBalance() external view returns (uint256, uint256) {
        uint256 _bal = _getBalance(msg.sender, true);
        return (_bal, _getUSDValue(_bal));
    }

    /**
     * @dev Return amount of unlocked tokens ready to be claimed for the specified staker
     * @param staker Address of staker to pull data for
     * @param unlockedOnly Only count unlocked balance ready to be withdrawn
     */
    function _getBalance(address staker, bool unlockedOnly) internal view returns (uint256) {
        LockRecord[] memory t = locksTable[staker];
        uint256 _bal;

        for (uint256 i = 0; i < t.length; i++) {
            if (t[i].isWithdrawn == 0) {
                if (!unlockedOnly || (unlockedOnly && (block.timestamp >= t[i].unlockDate || block.timestamp >= stakingLastUnlock))) {
                  _bal = _bal.add(t[i].amountLocked);
                }
            }
        }
        return _bal;
    }

    /**
     * @dev Checks whether USD value of all staker stakes exceed MaxUSD condition
     * @param staker Address of staker to pull data for
     * @param amount Amount of tokens to make a new stake
     */
    function _checkMaxUSDCondition(address staker, uint256 amount) internal view returns (bool) {
       // calc total token balance for staker
        LockRecord[] memory t = locksTable[staker];
        uint256 _bal;

        for (uint256 i = 0; i < t.length; i++) {
            if (t[i].isWithdrawn == 0) { // count only existing tokens -- both locked and unlocked
                _bal = _bal.add(t[i].amountLocked);
            }
        }

        return (_getUSDValue(_bal.add(amount)) <= maxUSDStakes);
    }

    
    function getTotals() external view returns (uint256, uint256)
    {
      uint256 _bal = IERC20(lockToken).balanceOf(address(this));
      return (_bal, _getUSDValue(_bal));
    }

    /**
     * @dev Checks whether USD value of all staker stakes exceed MaxUSD condition
     * @param amount Amount of tokens to make a new stake
     */
    function _getUSDValue(uint256 amount) internal view returns (uint256 stakesTotal) {
        if (tokenMode==0) { // straight token
          uint256 tokenDec = IEmiERC20(pathToStables[pathToStables.length-1]).decimals();
          uint256 [] memory tokenAmounts = IEmiRouter(emiRouter).getAmountsOut(amount, pathToStables);
          stakesTotal = tokenAmounts[tokenAmounts.length-1].div(10**tokenDec);
        } else if (tokenMode==1) {
          stakesTotal = _getStakesForLPToken(amount);
        } else {
          return 0;
        }
    }

    /**
     * @dev Return price of all stakes calculated by LP token scheme: price(token0)*2
     * @param amount Amount of tokens to stake
     */
    function _getStakesForLPToken(uint256 amount) internal view returns(uint256)
    {
       uint256 lpFraction = amount.mul(10**18).div(IERC20(lockToken).totalSupply());
       uint256 tokenIdx = 0;

       if (pathToStables[0]!=address(IEmiswap(lockToken).tokens(0))) {
         tokenIdx = 1;
       }

       uint256 rsv = IEmiswap(lockToken).getBalanceForAddition(
            IEmiswap(lockToken).tokens(tokenIdx)
       );

       uint256 tokenSrcDec = IEmiERC20(pathToStables[0]).decimals();
       uint256 tokenDstDec = IEmiERC20(pathToStables[pathToStables.length-1]).decimals();

       uint256 [] memory tokenAmounts = IEmiRouter(emiRouter).getAmountsOut(10**tokenSrcDec, pathToStables);
       return tokenAmounts[tokenAmounts.length-1].mul(rsv).mul(2).mul(lpFraction).div(10**(18+tokenSrcDec+tokenDstDec));
    }

    /**
     * @dev Return lock records ready to be unlocked
     * @param staker Address of staker to pull data for
     */
    function getUnlockedRecords(address staker) external view onlyOwner returns (LockRecord[] memory) {
        LockRecord[] memory t = locksTable[staker];
        uint256 l;

        for (uint256 i = 0; i < t.length; i++) {
            if (t[i].isWithdrawn == 0 && (block.timestamp >= t[i].unlockDate  || block.timestamp >= stakingLastUnlock)) {
                l++;
            }
        }
        if (l==0) {
          return new LockRecord[](0);
        }
        LockRecord[] memory r = new LockRecord[](l);
        uint256 j = 0;
        for (uint256 i = 0; i < t.length; i++) {
            if (t[i].isWithdrawn == 0 && (block.timestamp >= t[i].unlockDate  || block.timestamp >= stakingLastUnlock)) {
                r[j++] = t[i];
            }
        }

        return r;
    }

    /**
     * @dev Update lock period
     * @param _lockPeriod Lock period to set (is seconds)
     */
    function updateLockPeriod(uint256 _lockPeriod) external onlyOwner {
        emit LockPeriodUpdated(lockPeriod, _lockPeriod);
        lockPeriod = _lockPeriod;
    }

    /**
     * @dev Update last unlock date
     * @param _unlockTime Last unlock time (unix timestamp)
     */
    function updateLastUnlock(uint256 _unlockTime) external onlyOwner {
        stakingLastUnlock = _unlockTime;
    }

    /**
     * @dev Update path to stables
     * @param _path Path to stable coins
     */
    function updatePathToStables(address [] calldata _path) external onlyOwner {
        pathToStables = _path;
    }

    /**
     * @dev Update maxUSD value
     * @param _value Max USD value in USD (ex. 40000 for $40000)
     */
    function updateMaxUSD(uint256 _value) external onlyOwner {
        maxUSDStakes = _value;
    }

    /**
     * @dev Update tokenMode
     * @param _mode Token mode to set (0 for ERC20 token, 1 for Emiswap LP-token)
     */
    function updateTokenMode(uint8 _mode) external onlyOwner {
        require(_mode < 2, "Wrong token mode");
        tokenMode = _mode;
    }

    // ------------------------------------------------------------------------
    //
    // ------------------------------------------------------------------------
    /**
     * @dev Owner can transfer out any accidentally sent ERC20 tokens
     * @param tokenAddress Address of ERC-20 token to transfer
     * @param beneficiary Address to transfer to
     * @param tokens Amount of tokens to transfer
     */
    function transferAnyERC20Token(
        address tokenAddress,
        address beneficiary,
        uint256 tokens
    ) external onlyOwner returns (bool success) {
        require(tokenAddress != address(0), "Token address cannot be 0");
        require(tokenAddress != lockToken, "Token cannot be ours");

        return IERC20(tokenAddress).transfer(beneficiary, tokens);
    }
}
