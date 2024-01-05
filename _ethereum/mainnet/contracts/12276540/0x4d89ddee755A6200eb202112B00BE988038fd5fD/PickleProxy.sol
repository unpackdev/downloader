// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./Distribution.sol";
import "./IPool.sol";
import "./PoolStore.sol";
import "./Operator.sol";

contract PickleProxy is Operator, ERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public pool;
    uint256 public pid;
    address public shareToken;
    address public rewardToken;

    constructor() ERC20('Vault Proxy Token', 'VPT') {}

    /* ================= GOV - OWNER ONLY ================= */

    function setPool(address _newPool) public onlyOwner {
        pool = _newPool;
    }

    function setPid(uint256 _newPid) public onlyOwner {
        pid = _newPid;
    }

    function setShareToken(address _token) public onlyOwner {
        shareToken = _token;
    }

    function setRewardToken(address _token) public onlyOwner {
        rewardToken = _token;
    }

    function depositShare(uint256 _amount) public onlyOwner {
        _mint(address(this), _amount);
        approve(pool, _amount);
        IPool(pool).deposit(pid, _amount);
    }

    function withdrawShare(uint256 _amount) public onlyOwner {
        IPool(pool).withdraw(pid, _amount);
        _burn(address(this), _amount);
    }

    function balanceOf(address) public view override returns (uint256) {
        return IERC20(IPool(pool).tokenOf(pid)).balanceOf(address(this));
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
