pragma solidity >=0.6.6;

import "./SafeMath.sol";
import "./Math.sol";

library FixedAmountVestingLibrary {
    
    using SafeMath for uint;

    uint constant DECIMAL_SCALING_FACTOR = 10**18;

    struct Data {
        // uint32 in seconds = 136 years 
        uint32 cliffEnd;
        uint32 vestingInterval;
    }

    function initialize(
        Data storage self,
        uint32 cliffEnd,
        uint32 vestingInterval
    ) internal {
        // cliff may have zero duration to instantaneously unlock percentage of funds
        self.cliffEnd = cliffEnd;
        self.vestingInterval = vestingInterval;
    }

    function availableInputAmount(
        Data storage self, 
        uint totalAmount, 
        uint input, 
        uint vestedAmountPerInterval, 
        uint cliffAmount
    ) internal view returns (uint) {
        // input = amount_unlocked + amount_vested
        if (now < self.cliffEnd) {
            return 0; // no unlock or vesting yet
        }
        uint totalVested = totalAmount.sub(cliffAmount);
        if (input == 0) {
            return _vested(self, 0, totalVested, vestedAmountPerInterval).add(cliffAmount);
        } else {
            // amount_vested = input - amount_unlocked
            uint vested = input.sub(cliffAmount);
            return _vested(self, vested, totalVested, vestedAmountPerInterval);
        }
    }

    function _vested(
        Data storage self, 
        uint vested, 
        uint totalVested, 
        uint vestedPerInterval
    ) private view returns (uint) {
        if (totalVested == vested) {
            return 0;
        }
        if (self.vestingInterval == 0) {
            // when maxVested is too small or vestingDuration is too large, vesting reward is too small to even be distributed
            return totalVested.sub(vested);
        }
        uint lastVesting = (vested / vestedPerInterval).mul(self.vestingInterval).add(self.cliffEnd);
        uint available = now.sub(lastVesting).div(self.vestingInterval).mul(vestedPerInterval);
        return Math.min(available, totalVested.sub(vested));
    }
}
