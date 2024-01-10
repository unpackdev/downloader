// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./ListingRewardDistributorV2.sol";
import "./IStakeFor.sol";

contract ListingRewardDistributorV2Controller is AccessControl {
    using SafeERC20 for IERC20;

    uint256 public lastRoundUpdatedAt;
    uint256 public minRoundUpdateDelay = 18 hours;

    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    ListingRewardDistributorV2 public immutable lrd;

    constructor(
        ListingRewardDistributorV2 _lrd,
        address _operator,
        address _admin
    ) {
        lrd = _lrd;

        if (_admin == address(0)) {
            _admin = msg.sender;
        }
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, _admin);

        if (_operator != address(0)) {
            _grantRole(OPERATOR_ROLE, msg.sender);
        }
    }

    function transferUnderlyingOwnership(address to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(to != address(0), 'Controller: illegal new owner');
        lrd.transferOwnership(to);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        lrd.pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        lrd.unpause();
    }

    function updateSigners(address[] memory toAdd, address[] memory toRemove)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lrd.updateSigners(toAdd, toRemove);
    }

    function operatorWithdraw(
        IERC20 token,
        uint256 amount,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(to != address(0), 'Controller: illegal recipient');
        lrd.operatorWithdraw(token, amount);
        token.safeTransfer(to, amount);
    }

    function updateSetting(uint256 _maxReward, uint256 _maxRound)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lrd.updateSetting(_maxReward, _maxRound);
    }

    function updateStakingPool(IStakeFor pool_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lrd.updateStakingPool(pool_);
    }

    function updateMinRoundUpdateDelay(uint256 newDelay) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newDelay > 0, 'Controller: newDelay > 0');
        minRoundUpdateDelay = newDelay;
    }

    function updateRound(uint256 newRound) external onlyRole(OPERATOR_ROLE) {
        require(
            block.timestamp > lastRoundUpdatedAt + minRoundUpdateDelay,
            'Controller: update too soon, wait for the delay'
        );
        lastRoundUpdatedAt = block.timestamp;
        lrd.updateRound(newRound);
    }

    function currentRound() external view returns (uint256) {
        return lrd.currentRound();
    }
}
