// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./IBaseReward.sol";
import "./ISupplyBooster.sol";

interface ISupplyPoolExtraReward {
    function addExtraReward( uint256 _pid, address _lpToken, address _virtualBalance, bool _isErc20) external;
    function toggleShutdownPool(uint256 _pid, bool _state) external;
    function getRewards(uint256 _pid,address _for) external;
    function beforeStake(uint256 _pid, address _for) external;
    function afterStake(uint256 _pid, address _for) external;
    function beforeWithdraw(uint256 _pid, address _for) external;
    function afterWithdraw(uint256 _pid, address _for) external;
    function notifyRewardAmount( uint256 _pid, address _underlyToken, uint256 _amount) external payable;
}

interface ISupplyTreasuryFund {
    function initialize(address _virtualBalance, address _underlyToken, bool _isErc20) external;
    function depositFor(address _for) external payable;
    function depositFor(address _for, uint256 _amount) external;
    function withdrawFor(address _to, uint256 _amount) external  returns (uint256);
    function borrow(address _to, uint256 _lendingAmount,uint256 _lendingInterest) external returns (uint256);
    function repayBorrow() external payable;
    function repayBorrow(uint256 _lendingAmount) external;
    function claimComp(address _comp, address _comptroller, address _to) external returns (uint256, bool);
    function getBalance() external view returns (uint256);
    function getBorrowRatePerBlock() external view returns (uint256);
    function claim() external returns(uint256);
    function migrate(address _newTreasuryFund, bool _setReward) external returns(uint256);
    function getReward(address _for) external;
}

interface ISupplyRewardFactory {
    function createReward(
        address _rewardToken,
        address _virtualBalance,
        address _owner
    ) external returns (address);
}
