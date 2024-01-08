// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract Vesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public immutable numberOfEpochs;
    uint256 public immutable epochDuration;

    IERC20 public rewardToken;

    uint256 public lastClaimedEpoch;
    uint256 public startTime;
    uint256 public totalDistributedAmount;

    constructor(address newOwner, address _rewardToken, uint256 _startTime, uint256 _numberOfEpochs, uint256 _epochDuration, uint256 _totalDistributedAmount) {
        transferOwnership(newOwner);

        rewardToken = IERC20(_rewardToken);
        startTime = _startTime;
        numberOfEpochs = _numberOfEpochs;
        epochDuration = _epochDuration;
        totalDistributedAmount = _totalDistributedAmount;
    }

    function claim() public virtual nonReentrant {
        claimInternal(owner());
    }

    function claimInternal(address to) internal {
        uint256 currentEpoch = getCurrentEpoch();
        if (currentEpoch > numberOfEpochs + 1) {
            lastClaimedEpoch = numberOfEpochs;
            rewardToken.safeTransfer(to, rewardToken.balanceOf(address(this)));
            return;
        }

        uint256 amountOwed;
        if (currentEpoch > lastClaimedEpoch) {
            amountOwed = (currentEpoch - 1 - lastClaimedEpoch) * totalDistributedAmount / numberOfEpochs;
        }

        lastClaimedEpoch = currentEpoch - 1;
        if (amountOwed > 0) {
            rewardToken.safeTransfer(to, amountOwed);
        }
    }

    function balance() public view returns (uint256){
        return rewardToken.balanceOf(address(this));
    }

    function getCurrentEpoch() public view returns (uint256){
        if (block.timestamp < startTime) return 0;
        return (block.timestamp - startTime) / epochDuration + 1;
    }

    // default
    fallback() external {claim();}
}
