// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./Distribution.sol";
import "./IPool.sol";
import "./PoolStore.sol";
import "./Operator.sol";

contract PickleProxy is Operator {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public pool;
    uint256 public pid;

    // shareToken -> proxyToken -> rewardToken
    address public proxyToken;
    address public shareToken;
    address public rewardToken;

    /* ================= GOV - OWNER ONLY ================= */

    function setPool(address _newPool) public onlyOwner {
        pool = _newPool;
        IERC20(proxyToken).safeIncreaseAllowance(_newPool, type(uint256).max);
    }

    function setPid(uint256 _newPid) public onlyOwner {
        pid = _newPid;
    }

    function setProxyToken(address _token) public onlyOwner {
        proxyToken = _token;
    }

    function setShareToken(address _token) public onlyOwner {
        shareToken = _token;
    }

    function setRewardToken(address _token) public onlyOwner {
        rewardToken = _token;
    }

    function depositProxy(uint256 _amount) public onlyOwner {
        IERC20(proxyToken).safeTransferFrom(msg.sender, address(this), _amount);
        IPool(pool).deposit(pid, _amount);
    }

    function withdrawProxy(uint256 _amount) public onlyOwner {
        IPool(pool).withdraw(pid, _amount);
        IERC20(proxyToken).safeTransfer(msg.sender, _amount);
    }

    /* ================= GOV - OWNER ONLY ================= */

    function balanceOf(address) public view returns (uint256) {
        return IERC20(shareToken).balanceOf(address(this));
    }

    function earned(address) public view returns (uint256) {
        return IPool(pool).rewardEarned(pid, address(this));
    }

    function stake(uint256 _amount) public onlyOperator {
        IERC20(shareToken).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _amount) public onlyOperator {
        IERC20(shareToken).safeTransfer(msg.sender, _amount);
    }

    function getReward() public onlyOperator {
        IPool(pool).claimReward(pid);
        uint256 amount = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransfer(msg.sender, amount);
    }
}
