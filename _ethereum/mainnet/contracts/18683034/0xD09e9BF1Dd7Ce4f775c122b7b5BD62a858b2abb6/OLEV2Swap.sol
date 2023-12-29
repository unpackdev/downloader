// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./Adminable.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";

contract OLEV2Swap is Adminable, ReentrancyGuard {
    using TransferHelper for IERC20;

    IERC20 public immutable oleV1;
    IERC20 public immutable oleV2;
    uint64 public immutable expireTime;

    event Swapped (address account, uint amount);

    constructor (IERC20 _oleV1, IERC20 _oleV2, uint64 _expireTime){
        admin = payable(msg.sender);
        oleV1 = _oleV1;
        oleV2 = _oleV2;
        expireTime = _expireTime;
    }

    function swap(uint256 _amount) external nonReentrant(){
        require(expireTime > block.timestamp, 'Expired');
        uint oleV2BalanceBefore = oleV2.balanceOf(address(this));
        require(oleV2BalanceBefore >= _amount, 'NE');

        uint oleV1BalanceBefore = oleV1.balanceOf(address(this));
        oleV1.safeTransferFrom(msg.sender, address(this), _amount);
        uint oleV1BalanceAfter = oleV1.balanceOf(address(this));
        require(oleV1BalanceAfter - oleV1BalanceBefore == _amount, "CKP1");

        oleV2.safeTransfer(msg.sender, _amount);
        uint oleV2BalanceAfter = oleV2.balanceOf(address(this));
        require(oleV2BalanceBefore - oleV2BalanceAfter == _amount, "CKP2");
        emit Swapped(msg.sender, _amount);
    }

    function recycle(address _account, uint256 _amount) external onlyAdmin {
        require(oleV2.balanceOf(address(this)) >= _amount, "NE");
        oleV2.safeTransfer(_account, _amount);
    }

}