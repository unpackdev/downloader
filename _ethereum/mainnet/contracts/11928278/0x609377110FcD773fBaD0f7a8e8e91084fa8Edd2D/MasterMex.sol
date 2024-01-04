// SPDX-License-Identifier: MIT
/**
 *  DexMex Prediction Pool
 * 

           ,-.
       ,--' ~.).
     ,'         `.
    ; (((__   __)))
    ;  ( (#) ( (#)
    |   \_/___\_/|
   ,"  ,-'    `__".
  (   ( ._   ____`.)--._        _
   `._ `-.`-' \(`-'  _  `-. _,-' `-/`.
    ,')   `.`._))  ,' `.   `.  ,','  ;
  .'  .     `--'  /     ).   `.      ;
 ;     `-  1ucky /     '  )         ;
 \                       ')       ,'
  \                     ,'       ;
   \               `~~~'       ,'
    `.                      _,'
      `.                ,--'
        `-._________,--'
  *
*/

pragma solidity ^0.7.0;

import "./IUniswapV2Pair.sol";
import "./IMasterMex.sol";

contract MasterMex is IMasterMex {
    using SafeMath for uint256;

    event Deposit(address indexed sender, uint256 poolId, uint256 amount);
    event Withdraw(address indexed sender, uint256 poolId, uint256 amount);
    event FundAdded(address indexed user, uint256 amount);
    event FundRemoved(address indexed user, uint256 amount);
    event Profit(address indexed receiver, uint256 amount);
    event Loss(address indexed receiver, uint256 amount);

    constructor(
        address payable stakingVault,
        address payable treasuryVault,
        address payable buybackVault,
        uint256 stakeFee,
        uint256 treasuryFee,
        uint256 buybackFee
    ) {
        STAKING_VAULT = stakingVault;
        TREASURY_VAULT = treasuryVault;
        BUYBACK_VAULT = buybackVault;

        TREASURY_FEE = treasuryFee;
        STAKING_FEE = stakeFee;
        BUYBACK_FEE = buybackFee;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setPool(address uniPair, uint256 maxChangeRatio, uint256 minFund) external onlyOwner {
        poolInfo.push(PoolInfo({
            tokenPair: uniPair,
            prevReserved: 0,
            maxChangeRatio: maxChangeRatio,
            minFund: minFund
        }));

        uint256 length = poolInfo.length;

        groupInfo[length - 1][GroupType.Up] = GroupInfo({
            deposit: 0,
            holding: 0,
            shareProfitPerETH: 0,
            shareLossPerETH: 0
        });
        groupInfo[length - 1][GroupType.Down] = GroupInfo({
            deposit: 0,
            holding: 0,
            shareProfitPerETH: 0,
            shareLossPerETH: 0
        });
    }

    function setFeeDistribution(
        address payable stakingVault,
        address payable treasuryVault,
        address payable buybackVault,
        uint256 stakeFee,
        uint256 treasuryFee,
        uint256 buybackFee
    ) external onlyOwner {
        STAKING_VAULT = stakingVault;
        TREASURY_VAULT = treasuryVault;
        BUYBACK_VAULT = buybackVault;

        TREASURY_FEE = treasuryFee;
        STAKING_FEE = stakeFee;
        BUYBACK_FEE = buybackFee;
    }

    receive() external payable {
        _registerPendingUser(msg.value);
    }

    function _registerPendingUser(uint256 amount) internal {
        require(msg.sender != address(0));
        UserInfo storage user = pendingUserInfo[msg.sender];

        user.amount = user.amount.add(amount);
        user.voteGroup = GroupType.Up;
        emit FundAdded(msg.sender, amount);
    }

    function setPendingUserGroup(GroupType voteGroup) external {
        UserInfo storage user = pendingUserInfo[msg.sender];
        require(user.amount > 0, "No pending amount");

        user.voteGroup = voteGroup;
    }

    function withdrawPendingAmount(uint256 amount) external nonReentrant {
        require(msg.sender != address(0));
        UserInfo storage user = pendingUserInfo[msg.sender];
        require(user.amount >= amount, "Insufficient pending amount");
        
        user.amount = user.amount.sub(amount);
        _safeEthTransfer(msg.sender, amount);
        emit FundRemoved(msg.sender, amount);
    }

    function depositIntoPool(uint256 poolId, uint256 amount) external  {
        require(poolId < poolInfo.length, "No pool");
        UserInfo storage pendingUser = pendingUserInfo[msg.sender];
        require(pendingUser.amount >= amount, "Insufficient pending amount");

        UserInfo storage user = userInfo[poolId][msg.sender];
        if (user.amount > 0 && user.voteGroup != pendingUser.voteGroup) {
            return;
        }
        user.voteGroup = pendingUser.voteGroup;
        pendingUser.amount = pendingUser.amount.sub(amount);
        GroupInfo storage group = groupInfo[poolId][user.voteGroup];

        updatePool(poolId);

        if (user.amount > 0) {
            _claim(poolId);
        }

        user.amount = user.amount.add(amount);
        group.deposit = group.deposit.add(amount);
        group.holding = group.holding.add(amount);
        user.profitDebt = user.amount.mul(group.shareProfitPerETH).div(10**decimals);
        user.lossDebt = user.amount.mul(group.shareLossPerETH).div(10**decimals);
        emit Deposit(msg.sender, poolId, amount);
    }

    function withdrawFromPool(uint256 poolId, uint256 amount) external nonReentrant {
        require(poolId < poolInfo.length, "No pool");
        UserInfo storage user = userInfo[poolId][msg.sender];
        GroupInfo storage group = groupInfo[poolId][user.voteGroup];
        require(user.amount >= amount, "Withdraw over than deposit");

        updatePool(poolId);
        _claim(poolId);

        if (amount > 0) {
            if (user.amount < amount) {
                amount = user.amount;
            }
            user.amount = user.amount.sub(amount);
            group.deposit = group.deposit.sub(amount);
            group.holding = group.holding.sub(amount);
            _safeEthTransfer(msg.sender, amount);
        }
        user.profitDebt = user.amount.mul(group.shareProfitPerETH).div(10**decimals);
        user.lossDebt = user.amount.mul(group.shareLossPerETH).div(10**decimals);
        emit Withdraw(msg.sender, poolId, amount);
    }

    function claim(uint256 poolId) external nonReentrant {
        require(poolId < poolInfo.length, "No pool");
        updatePool(poolId);
        _claim(poolId);
    }

    function updatePool(uint256 poolId) public {
        require(poolId < poolInfo.length, "No pool");

        PoolInfo storage pool = poolInfo[poolId];
        GroupInfo storage upGroup = groupInfo[poolId][GroupType.Up];
        GroupInfo storage downGroup = groupInfo[poolId][GroupType.Down];
        uint256 reserved = _getPrice(pool.tokenPair);

        if (upGroup.holding >= pool.minFund && downGroup.holding >= pool.minFund) {
            uint256 rewardAmt = 0;
            uint256 lossAmt = 0;
            uint256 fee = 0;
            uint256 changedRatio = 0;
            uint256 changedReserved = 0;
            if (reserved > pool.prevReserved) {
                changedReserved = reserved.sub(pool.prevReserved);
                changedRatio = changedReserved.mul(10**decimals).div(pool.prevReserved);

                if (changedRatio > pool.maxChangeRatio) {
                    changedRatio = pool.maxChangeRatio;
                }
                lossAmt = changedRatio.mul(downGroup.holding);
                fee = _distributeFee(lossAmt);
                rewardAmt = lossAmt.sub(fee);
                
                _updateGroup(poolId, GroupType.Up, rewardAmt, false);
                _updateGroup(poolId, GroupType.Down, lossAmt, true);
            } else {
                changedReserved = pool.prevReserved.sub(reserved);
                changedRatio = changedReserved.mul(10**decimals).div(pool.prevReserved);

                if (changedRatio > pool.maxChangeRatio) {
                    changedRatio = pool.maxChangeRatio;
                }

                lossAmt = changedRatio.mul(upGroup.holding);
                fee = _distributeFee(lossAmt);
                rewardAmt = lossAmt.sub(fee);

                _updateGroup(poolId, GroupType.Down, rewardAmt, false);
                _updateGroup(poolId, GroupType.Up, lossAmt, true);
            }
        }
        pool.prevReserved = reserved;
    }

    function _getPrice(address tokenPair) internal view returns(uint256) {
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(tokenPair).getReserves();
        address token0 = IUniswapV2Pair(tokenPair).token0();

        uint256 ratio = 0;
        if (token0 == WETH) {
            ratio = reserve0.mul(10**decimals).div(reserve1);
        } else {
            ratio = reserve1.mul(10**decimals).div(reserve0);
        }

        return ratio;
    }

    function _safeEthTransfer(address to, uint256 amount) internal {
        uint256 remain = address(this).balance;
        if (remain < amount) {
            amount = remain;
        }
        payable(to).transfer(amount);
    }

    function _updateGroup(uint256 poolId, GroupType groupType, uint256 amount, bool loss) internal {
        GroupInfo storage group = groupInfo[poolId][groupType];
        uint256 volumeSharePerETH = amount.div(group.deposit);
        amount = amount.div(10**decimals);
        if (loss) {
            group.holding = group.holding.sub(amount);
            group.shareLossPerETH = group.shareLossPerETH.add(volumeSharePerETH);
        } else {
            group.holding = group.holding.add(amount);
            group.shareProfitPerETH = group.shareProfitPerETH.add(volumeSharePerETH);
        }
    }

    function _claim(uint256 poolId) internal {
        UserInfo storage user = userInfo[poolId][msg.sender];
        GroupInfo storage group = groupInfo[poolId][user.voteGroup];
        
        uint256 pendingProfit = 0;
        uint256 pendingLoss = 0;
        if (user.amount > 0) {
            pendingProfit = user.amount.mul(group.shareProfitPerETH).div(10**decimals).sub(user.profitDebt);

            pendingLoss = user.amount.mul(group.shareLossPerETH).div(10**decimals).sub(user.lossDebt);
        }

        user.amount = user.amount.add(pendingProfit);
        user.amount = user.amount.sub(pendingLoss);

        if (pendingProfit > pendingLoss) {
            uint256 volume = pendingProfit.sub(pendingLoss);
            group.holding = group.holding.sub(volume);
            _safeEthTransfer(msg.sender, volume);
            emit Profit(msg.sender, volume);
        } else if (pendingProfit < pendingLoss) {
            uint256 volume = pendingLoss.sub(pendingProfit);
            group.deposit = group.deposit.sub(volume);
            emit Loss(msg.sender, volume);
        }
    }

    function _distributeFee(uint256 amount) internal returns(uint256) {
        uint256 totalFee = STAKING_FEE.add(TREASURY_FEE).add(BUYBACK_FEE);
        uint256 feeAmt = amount.mul(totalFee).div(10**decimals);

        uint256 partialFeeAmt = feeAmt.mul(STAKING_FEE).div(totalFee).div(10**decimals);
        _safeEthTransfer(STAKING_VAULT, partialFeeAmt);

        partialFeeAmt = feeAmt.mul(TREASURY_FEE).div(totalFee).div(10**decimals);
        _safeEthTransfer(TREASURY_VAULT, partialFeeAmt);
        
        partialFeeAmt = feeAmt.mul(BUYBACK_FEE).div(totalFee).div(10**decimals);
        _safeEthTransfer(BUYBACK_VAULT, partialFeeAmt);

        return feeAmt;
    }
}