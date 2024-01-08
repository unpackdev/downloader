// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract Vesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant NUMBER_OF_EPOCHS = 100;
    uint256 public constant EPOCH_DURATION = 604800; // 1 week duration
    IERC20 private _reign;

    uint256 public lastClaimedEpoch;
    uint256 private _startTime;
    uint256 public totalDistributedBalance;

    constructor(
        address newOwner,
        address reignTokenAddress,
        uint256 startTime,
        uint256 totalBalance
    ) public {
        transferOwnership(newOwner);
        _reign = IERC20(reignTokenAddress);
        _startTime = startTime;
        totalDistributedBalance = totalBalance;
    }

    function claim() public nonReentrant {
        uint256 balance;
        uint256 currentEpoch = getCurrentEpoch();
        if (currentEpoch > NUMBER_OF_EPOCHS + 1) {
            lastClaimedEpoch = NUMBER_OF_EPOCHS;
            _reign.transfer(owner(), _reign.balanceOf(address(this)));
            return;
        }

        if (currentEpoch > lastClaimedEpoch) {
            balance =
                ((currentEpoch - 1 - lastClaimedEpoch) *
                    totalDistributedBalance) /
                NUMBER_OF_EPOCHS;
        }
        lastClaimedEpoch = currentEpoch - 1;
        if (balance > 0) {
            _reign.transfer(owner(), balance);
        }
    }

    function balance() public view returns (uint256) {
        return _reign.balanceOf(address(this));
    }

    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp < _startTime) return 0;
        return (block.timestamp - _startTime) / EPOCH_DURATION + 1;
    }

    // default
    fallback() external {
        claim();
    }
}
