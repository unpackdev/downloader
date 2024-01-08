// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IPool.sol";
import "./Operator.sol";

contract PoolProxy is Operator, ERC20 {
    using SafeERC20 for IERC20;

    address public pool;
    uint256 public pid;
    address public rewardToken;

    constructor() ERC20('Pool Proxy Token', 'PPT') {}

    /* ================= GOV - OWNER ONLY ================= */

    function setPool(address _newPool) public onlyOwner {
        pool = _newPool;
        _approve(address(this), _newPool, type(uint256).max);
    }

    function setPid(uint256 _newPid) public onlyOwner {
        pid = _newPid;
    }

    function setRewardToken(address _token) public onlyOwner {
        rewardToken = _token;
    }

    function deposit(uint256 _amount) public onlyOwner {
        _mint(address(this), _amount);
        IPool(pool).deposit(pid, _amount);
    }

    function withdraw(uint256 _amount) public onlyOwner {
        IPool(pool).withdraw(pid, _amount);
        _burn(address(this), _amount);
    }

    /* ================= TXNS - OPERATOR ONLY ================= */

    function collect() external onlyOperator returns (address, uint256) {
        IPool(pool).claimReward(pid);

        uint256 amount = IERC20(rewardToken).balanceOf(address(this));

        IERC20(rewardToken).safeTransfer(_msgSender(), amount);

        return (rewardToken, amount);
    }
}
