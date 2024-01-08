// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ILottery.sol";

contract LotteryReward is Initializable, Ownable {
    using SafeERC20 for IERC20;

    ILottery public lottery;
    IERC20 public trade;

    function initialize(
        ILottery _lottery,
        IERC20 _trade
    ) external initializer {
        __Ownable_init();
        lottery = _lottery;
        trade = _trade;
    }

    event Inject(uint256 amount);
    event Withdraw(uint256 amount);

    uint8[4] private nullTicket = [0,0,0,0];

    function inject(uint256 _amount) external onlyOwner {
        trade.safeApprove(address(lottery), _amount);
        lottery.buy(_amount, nullTicket);
        emit Inject(_amount);
    }

    function adminWithdraw(uint256 _amount) external onlyOwner {
        trade.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(_amount);
    }

}