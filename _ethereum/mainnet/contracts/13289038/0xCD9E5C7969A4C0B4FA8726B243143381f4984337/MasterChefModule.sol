// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./IMasterChefModule.sol";

abstract contract MasterChefModule is Ownable, IMasterChefModule {
    IUniswapV2Pair public immutable override lpToken;

    IERC20 public immutable override sushi;
    IMasterChef public override sushiMasterChef;
    uint256 public override masterChefPid;
    uint256 public override sushiLastRewardBlock;
    uint256 public override accSushiPerShare;
    bool private initialDeposited;

    constructor(IUniswapV2Pair _lpToken, IERC20 _sushi) {
        lpToken = _lpToken;
        sushi = _sushi;
    }

    function _depositModule(
        uint256 _pid,
        uint256 depositAmount,
        uint256 supportedLPTokenAmount,
        uint256 sushiRewardDebt
    ) internal returns (uint256 newRewardDebt) {
        uint256 _totalSupportedLPTokenAmount = sushiMasterChef.userInfo(_pid, address(this)).amount;
        uint256 _accSushiPerShare = _depositToSushiMasterChef(_pid, depositAmount, _totalSupportedLPTokenAmount);
        uint256 pending = (supportedLPTokenAmount * _accSushiPerShare) / 1e18 - sushiRewardDebt;
        if (pending > 0) safeSushiTransfer(msg.sender, pending);
        return ((supportedLPTokenAmount + depositAmount) * _accSushiPerShare) / 1e18;
    }

    function _withdrawModule(
        uint256 _pid,
        uint256 withdrawalAmount,
        uint256 supportedLPTokenAmount,
        uint256 sushiRewardDebt
    ) internal returns (uint256 newRewardDebt) {
        uint256 _totalSupportedLPTokenAmount = sushiMasterChef.userInfo(_pid, address(this)).amount;
        uint256 _accSushiPerShare = _withdrawFromSushiMasterChef(_pid, withdrawalAmount, _totalSupportedLPTokenAmount);
        uint256 pending = (supportedLPTokenAmount * _accSushiPerShare) / 1e18 - sushiRewardDebt;
        if (pending > 0) safeSushiTransfer(msg.sender, pending);
        return ((supportedLPTokenAmount - withdrawalAmount) * _accSushiPerShare) / 1e18;
    }

    function _claimSushiReward(uint256 supportedLPTokenAmount, uint256 sushiRewardDebt)
        internal
        returns (uint256 newRewardDebt)
    {
        uint256 _pid = masterChefPid;
        require(_pid > 0, "MasterChefModule: Unclaimable");

        uint256 _totalSupportedLPTokenAmount = sushiMasterChef.userInfo(_pid, address(this)).amount;
        uint256 _accSushiPerShare = _depositToSushiMasterChef(_pid, 0, _totalSupportedLPTokenAmount);
        uint256 pending = (supportedLPTokenAmount * _accSushiPerShare) / 1e18 - sushiRewardDebt;
        require(pending > 0, "MasterChefModule: Nothing can be claimed");
        safeSushiTransfer(msg.sender, pending);
        return (supportedLPTokenAmount * _accSushiPerShare) / 1e18;
    }

    function _pendingSushiReward(uint256 supportedLPTokenAmount, uint256 sushiRewardDebt)
        internal
        view
        returns (uint256)
    {
        uint256 _pid = masterChefPid;
        if (_pid == 0) return 0;
        uint256 _totalSupportedLPTokenAmount = sushiMasterChef.userInfo(_pid, address(this)).amount;

        uint256 _accSushiPerShare = accSushiPerShare;
        if (block.number > sushiLastRewardBlock && _totalSupportedLPTokenAmount != 0) {
            uint256 reward = sushiMasterChef.pendingSushi(masterChefPid, address(this));
            _accSushiPerShare += ((reward * 1e18) / _totalSupportedLPTokenAmount);
        }

        return (supportedLPTokenAmount * _accSushiPerShare) / 1e18 - sushiRewardDebt;
    }

    function setSushiMasterChef(IMasterChef _masterChef, uint256 _pid) external onlyOwner {
        require(address(_masterChef.poolInfo(_pid).lpToken) == address(lpToken), "MasterChefModule: Invalid pid");
        if (!initialDeposited) {
            initialDeposited = true;
            lpToken.approve(address(_masterChef), type(uint256).max);

            sushiMasterChef = _masterChef;
            masterChefPid = _pid;
            _depositToSushiMasterChef(_pid, lpToken.balanceOf(address(this)), 0);
        } else {
            IMasterChef oldChef = sushiMasterChef;
            uint256 oldpid = masterChefPid;
            _withdrawFromSushiMasterChef(oldpid, oldChef.userInfo(oldpid, address(this)).amount, 0);
            if (_masterChef != oldChef) {
                lpToken.approve(address(oldChef), 0);
                lpToken.approve(address(_masterChef), type(uint256).max);
            }

            sushiMasterChef = _masterChef;
            masterChefPid = _pid;
            _depositToSushiMasterChef(_pid, lpToken.balanceOf(address(this)), 0);
        }
    }

    function _depositToSushiMasterChef(
        uint256 _pid,
        uint256 _amount,
        uint256 _totalSupportedLPTokenAmount
    ) internal returns (uint256 _accSushiPerShare) {
        return _toSushiMasterChef(true, _pid, _amount, _totalSupportedLPTokenAmount);
    }

    function _withdrawFromSushiMasterChef(
        uint256 _pid,
        uint256 _amount,
        uint256 _totalSupportedLPTokenAmount
    ) internal returns (uint256 _accSushiPerShare) {
        return _toSushiMasterChef(false, _pid, _amount, _totalSupportedLPTokenAmount);
    }

    function _toSushiMasterChef(
        bool deposit,
        uint256 _pid,
        uint256 _amount,
        uint256 _totalSupportedLPTokenAmount
    ) internal returns (uint256) {
        uint256 reward;
        if (block.number <= sushiLastRewardBlock) {
            if (deposit) sushiMasterChef.deposit(_pid, _amount);
            else sushiMasterChef.withdraw(_pid, _amount);
            return accSushiPerShare;
        } else {
            uint256 balance0 = sushi.balanceOf(address(this));
            if (deposit) sushiMasterChef.deposit(_pid, _amount);
            else sushiMasterChef.withdraw(_pid, _amount);
            uint256 balance1 = sushi.balanceOf(address(this));
            reward = balance1 - balance0;
        }
        sushiLastRewardBlock = block.number;
        if (_totalSupportedLPTokenAmount > 0 && reward > 0) {
            uint256 _accSushiPerShare = accSushiPerShare + ((reward * 1e18) / _totalSupportedLPTokenAmount);
            accSushiPerShare = _accSushiPerShare;
            return _accSushiPerShare;
        } else {
            return accSushiPerShare;
        }
    }

    function safeSushiTransfer(address _to, uint256 _amount) internal {
        uint256 sushiBal = sushi.balanceOf(address(this));
        if (_amount > sushiBal) {
            sushi.transfer(_to, sushiBal);
        } else {
            sushi.transfer(_to, _amount);
        }
    }
}
