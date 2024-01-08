// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IPoolAccountant.sol";
import "./VFRPool.sol";

// solhint-disable no-empty-blocks
contract VFRStablePool is VFRPool {
    string public constant VERSION = "3.0.4";

    uint256 public targetAPY;
    uint256 public startTime;
    uint256 public initialPricePerShare;

    uint256 public predictedAPY;
    uint256 public tolerance;
    bool public depositsHalted;

    event ToleranceSet(uint256 tolerance);
    event Retarget(uint256 targetAPY, uint256 tolerance);

    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) VFRPool(_name, _symbol, _token) {}

    function setTolerance(uint256 _tolerance) external onlyGovernor {
        require(_tolerance != 0, "tolerance-value-is-zero");
        require(_tolerance != tolerance, "same-tolerance-value");
        tolerance = _tolerance;
        emit ToleranceSet(_tolerance);
    }

    function retarget(uint256 _apy, uint256 _tolerance) external onlyGovernor {
        // eg. 100% APY -> 1 * 1e18 = 1e18
        //     5% APY -> 0.05 * 1e18 = 5e16
        targetAPY = _apy;
        startTime = block.timestamp;
        initialPricePerShare = pricePerShare();
        predictedAPY = _apy;
        // Only allow deposits if at the last rebalance the pool's actual APY
        // was not behind the target APY for more than 'tolerance'. Probably
        // a better way to set this is dynamically based on how long the pool
        // has been running for.
        tolerance = _tolerance;
        emit Retarget(_apy, _tolerance);
    }

    function checkpoint() external onlyKeeper {
        address[] memory strategies = getStrategies();

        uint256 profits;
        for (uint256 i = 0; i < strategies.length; i++) {
            (, uint256 fee, , , uint256 totalDebt, , , ) = IPoolAccountant(poolAccountant).strategy(strategies[i]);
            uint256 totalValue = IStrategy(strategies[i]).totalValueCurrent();
            if (totalValue > totalDebt) {
                uint256 totalProfits = totalValue - totalDebt;
                uint256 actualProfits = totalProfits - ((totalProfits * fee) / MAX_BPS);
                profits += actualProfits;
            }
        }

        if (buffer != address(0)) {
            // This should take into account that an interest fee is taken from the amount in the buffer
            // (however, the interest fee depends on which strategy will request funds from the buffer)
            profits += token.balanceOf(buffer);
        }

        // Calculate the price per share if the above profits were to be reported
        uint256 predictedPricePerShare;
        if (totalSupply() == 0 || totalValue() == 0) {
            predictedPricePerShare = convertFrom18(1e18);
        } else {
            predictedPricePerShare = ((totalValue() + profits) * 1e18) / totalSupply();
        }

        // Predict the APY based on the unreported profits of all strategies
        predictedAPY =
            ((predictedPricePerShare - initialPricePerShare) * (1e18 * 365 * 24 * 3600)) /
            (initialPricePerShare * (block.timestamp - startTime));

        // Although the predicted APY can be greater than the target APY due to the funds
        // available in the buffer, the strategies will make sure to never send more funds
        // to the pool than the amount needed to cover the target APY
        predictedAPY = predictedAPY > targetAPY ? targetAPY : predictedAPY;

        // The predicted APY must be within the target APY by no more than the current tolerance
        depositsHalted = targetAPY - predictedAPY > tolerance;
    }

    function targetPricePerShare() public view returns (uint256) {
        return
            initialPricePerShare +
            ((initialPricePerShare * targetAPY * (block.timestamp - startTime)) / (1e18 * 365 * 24 * 3600));
    }

    function amountToReachTarget(address _strategy) public view returns (uint256) {
        uint256 fromPricePerShare = pricePerShare();
        uint256 toPricePerShare = targetPricePerShare();
        if (fromPricePerShare < toPricePerShare) {
            (, uint256 fee, , , , , , ) = IPoolAccountant(poolAccountant).strategy(_strategy);
            uint256 fromTotalValue = (fromPricePerShare * totalSupply()) / 1e18;
            uint256 toTotalValue = (toPricePerShare * totalSupply()) / 1e18;
            uint256 amountWithoutFee = toTotalValue - fromTotalValue;
            // Take into account the performance fee of the strategy
            return (amountWithoutFee * MAX_BPS) / (MAX_BPS - fee);
        }
        return 0;
    }

    function _deposit(uint256 _amount) internal override {
        require(!depositsHalted, "pool-under-target");
        super._deposit(_amount);
    }
}
