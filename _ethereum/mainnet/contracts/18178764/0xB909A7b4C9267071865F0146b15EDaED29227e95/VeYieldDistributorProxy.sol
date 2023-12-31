// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IVeHakaDaoYieldDistributor.sol";

contract NotifyRewardProxy is AccessControl {
    using SafeERC20 for IERC20;

    event ApyUpdated(uint256 apy);
    event NotifyRewardExecuted(address indexed user, uint256 amount);

    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    uint256 public constant APY_BASE = 10000; // APY should be provided as per this base to get ratio, 60% should 6000
    uint256 public constant SECONDS_IN_YEAR = 31536000;

    IVeHakaDaoYieldDistributor public immutable yieldDistributor;
    IERC20 public immutable haka;
    IERC20 public immutable veHaka;
    uint256 public apy;

    constructor(IVeHakaDaoYieldDistributor _yieldDistributor, IERC20 _haka, IERC20 _veHaka, address _admin) {
        yieldDistributor = _yieldDistributor;
        haka = _haka;
        veHaka = _veHaka;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function updateApy(uint256 _apy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_apy <= APY_BASE, "NotifyRewardProxy: invalid APY");
        apy = _apy;
        emit ApyUpdated(_apy);
    }

    function execNotifyReward(address _user) external onlyRole(EXECUTOR_ROLE) {
        uint256 amount = getRewardAmount();
        require(amount != 0, "NotifyRewardProxy: zero reward");
        haka.safeTransferFrom(_user, address(this), amount);
        haka.approve(address(yieldDistributor), amount);
        yieldDistributor.notifyRewardAmount(amount);
        emit NotifyRewardExecuted(_user, amount);
    }

    function getRewardAmount() public view returns (uint256 reward) {
        uint256 veTotalSupply = veHaka.totalSupply();
        uint256 duration = yieldDistributor.yieldDuration();
        reward = (veTotalSupply * apy * duration) / (APY_BASE * SECONDS_IN_YEAR);
    }
}
