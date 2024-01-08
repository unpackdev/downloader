//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Interfaces

// Libraries
import "./SafeMath.sol";

library PoolInfoLib {
    using SafeMath for uint256;

    // Info of each pool.
    struct PoolInfo {
        uint256 totalDeposit;
        address token; // Address of token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that tokens distribution occurs.
        uint256 accTokenPerShare; // Accumulated tokens per share, times 1e12. See below.
        bool isPaused;
    }

    function setIsPaused(PoolInfo storage self, bool newIsPaused) internal {
        self.isPaused = newIsPaused;
    }

    function requireIsNotPaused(PoolInfo storage self) internal view {
        require(!self.isPaused, "POOL_IS_PAUSED");
    }

    function requireIsPaused(PoolInfo storage self) internal view {
        require(self.isPaused, "POOL_ISNT_PAUSED");
    }

    function stake(PoolInfo storage self, uint256 valuedAmount) internal {
        self.totalDeposit = self.totalDeposit.add(valuedAmount);
    }

    function unstake(PoolInfo storage self, uint256 valuedAmount) internal {
        self.totalDeposit = self.totalDeposit.sub(valuedAmount);
    }
}
