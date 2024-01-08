// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeCast.sol";
import "./ILiquidityMining.sol";
import "./IEmission.sol";

contract Emission is IEmission, Ownable, ReentrancyGuard, Initializable {
    using SafeCast for uint;
    using SafeERC20 for IERC20;

    address public token; // 160
    uint64 public lastWithdrawalTimestamp; // 160 + 64 = 224
    address public liquidityMining;

    uint constant INITIAL_QUANTITY = 10000;
    
    uint public override distributedPerInterval;
    uint public override distributionInterval;
    
    function initialize(address _token, address _liquidityMining, uint _distributionInterval, uint _distributedPerInterval) public initializer {
        require(_token != address(0), "Emission: ZERO");
        token = _token;
        liquidityMining = _liquidityMining;
        distributionInterval = _distributionInterval;
        distributedPerInterval = _distributedPerInterval;
        lastWithdrawalTimestamp = block.timestamp.toUint64();
    }

    function setDistribution(uint _distributionInterval, uint _distributedPerInterval) external override onlyOwner {
        _withdraw();
        distributionInterval = _distributionInterval;
        distributedPerInterval = _distributedPerInterval;
        emit SetDistribution(distributionInterval, distributedPerInterval);
    }

    function withdraw() external override nonReentrant {
        _withdraw();
    }

    function withdrawable() external view override returns (uint) {
        uint balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) {
            return 0;
        }
        uint intervalPassed = (block.timestamp - lastWithdrawalTimestamp) / distributionInterval;
        return Math.min(balance, intervalPassed * distributedPerInterval);
    }

    function _withdraw() private {
        uint balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) {
            lastWithdrawalTimestamp = block.timestamp.toUint64(); // increment last withdrawal time when there is no funds to reduce time delta
            return;
        }
        uint intervalPassed = (block.timestamp - lastWithdrawalTimestamp) / distributionInterval;
        if (intervalPassed == 0) {
            return;
        }
        uint amount = Math.min(balance, intervalPassed * distributedPerInterval);
        lastWithdrawalTimestamp += (intervalPassed * distributionInterval).toUint64();
        IERC20(token).safeTransfer(liquidityMining, amount);
    }
}