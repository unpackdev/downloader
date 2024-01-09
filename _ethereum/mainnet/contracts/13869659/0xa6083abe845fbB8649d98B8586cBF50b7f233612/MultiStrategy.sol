// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ISwapManager.sol";
import "./IController.sol";
import "./IStrategy.sol";
import "./IVesperPool.sol";
import "./IAddressListExt.sol";
import "./IAddressListFactory.sol";
import "./Strategy.sol";

contract MultiStrategy is Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address[] strategies;
    uint numStrategies;

    constructor(
        address _controller,
        address _pool,
        address _receiptToken
    ) public Strategy(_controller, _pool, _receiptToken) {
    }

    function addNewStrategy(address strategy) public {
        strategies.push(strategy);
        ++numStrategies;
    }

    function rebalance() external override {
        //Strategy(strategy);
    }

    function beforeWithdraw() external override {

    }

    function interestEarned() external view virtual override returns (uint256) {
        return 0;
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return false;
    }

    function totalLocked() public view virtual override returns (uint256) {
        return 0;
    }

    function _handleFee(uint256 _fee) internal virtual override {
    }

    function _deposit(uint256 _amount) internal virtual override {

    }

    function _withdraw(uint256 _amount) internal virtual override {

    }

    function _approveToken(uint256 _amount) internal virtual override {

    }

    function _updatePendingFee() internal virtual override {

    }

    function _withdrawAll() internal virtual override {

    }

    function _migrateIn() internal virtual override {

    }

    function _migrateOut() internal virtual override {

    }

    function _claimReward() internal virtual override {

    }
}
