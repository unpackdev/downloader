// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20.sol";

import "./IVFRCoveragePool.sol";
import "./IVFRStablePool.sol";
import "./IVesperPool.sol";

contract VFRBuffer {
    address public token;
    address public stablePool;
    address public coveragePool;
    // Specifies for how long (in seconds) the buffer should be
    // able to cover the stable pool's target APY requirements
    uint256 public coverageTime;

    event CoverageTimeUpdated(uint256 oldCoverageTime, uint256 newCoverageTime);

    constructor(
        address _stablePool,
        address _coveragePool,
        uint256 _coverageTime
    ) {
        address stablePoolToken = address(IVesperPool(_stablePool).token());
        address coveragePoolToken = address(IVesperPool(_coveragePool).token());
        require(stablePoolToken == coveragePoolToken, "non-matching-tokens");

        token = stablePoolToken;
        stablePool = _stablePool;
        coveragePool = _coveragePool;
        coverageTime = _coverageTime;
    }

    function target() external view returns (uint256 amount) {
        uint256 targetAPY = IVFRStablePool(stablePool).targetAPY();
        // Get the current price per share
        uint256 fromPricePerShare = IVFRStablePool(stablePool).pricePerShare();
        // Get the price per share that would cover the stable pool's APY requirements
        uint256 toPricePerShare =
            fromPricePerShare + (fromPricePerShare * targetAPY * coverageTime) / (365 * 24 * 3600 * 1e18);
        // Get the amount needed to increase the current price per share to the coverage target
        uint256 totalSupply = IVFRStablePool(stablePool).totalSupply();
        uint256 fromTotalValue = (fromPricePerShare * totalSupply) / 1e18;
        uint256 toTotalValue = (toPricePerShare * totalSupply) / 1e18;
        if (toTotalValue > fromTotalValue) {
            amount = toTotalValue - fromTotalValue;
        }
    }

    function request(uint256 _amount) public {
        // Make sure the requester is a valid strategy (either a stable pool one or a coverage pool one)
        (bool activeInStablePool, , , , , , , ) = IVFRStablePool(stablePool).strategy(msg.sender);
        (bool activeInCoveragePool, , , , , , , ) = IVFRCoveragePool(coveragePool).strategy(msg.sender);
        require(activeInStablePool || activeInCoveragePool, "invalid-strategy");
        // Make sure enough funds are available
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= _amount, "insufficient-balance");
        IERC20(token).transfer(msg.sender, _amount);
    }

    function flush() public {
        require(IVFRStablePool(stablePool).keepers().contains(msg.sender), "not-a-keeper");
        // Transfer any outstanding funds to the coverage pool
        IERC20(token).transfer(coveragePool, IERC20(token).balanceOf(address(this)));
    }

    function updateCoverageTime(uint256 _coverageTime) external {
        require(IVFRStablePool(stablePool).keepers().contains(msg.sender), "not-a-keeper");
        emit CoverageTimeUpdated(coverageTime, _coverageTime);
        coverageTime = _coverageTime;
    }
}
