// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.19;

import "./SafeERC20.sol";
import "./Ownable.sol";

contract MultiPlanVesting is Ownable {
    using SafeERC20 for IERC20;

    uint constant TGE_UNLOCK_BASE = 1000;

    struct Plan {
        IERC20 token;
        uint startTime;
        uint duration;
        uint tgeUnlock;
        mapping(address => uint) allocation;
        mapping(address => uint) claimed;
        uint totalAllocation;
        uint totalClaimed;
    }

    mapping(string => Plan) public vestingPlans;

    constructor() {}

    function createVesting(
        string memory planKey_,
        address tokenAddress_,
        uint startTime_,
        uint duration_,
        uint tgeUnlock_,
        address[] memory recipients_,
        uint[] memory allocations_
    ) external {
        // not existed
        require(
            vestingPlans[planKey_].totalAllocation == 0,
            "Vesting Plan Existed!"
        );
        require(tgeUnlock_ < TGE_UNLOCK_BASE, "Cannot unlock full at TGE");

        Plan storage vestingPlan = vestingPlans[planKey_];
        vestingPlan.token = IERC20(tokenAddress_);
        vestingPlan.startTime = startTime_;
        vestingPlan.duration = duration_;
        vestingPlan.tgeUnlock = tgeUnlock_;

        // vestingPlans[planKey_] = vestingPlan;

        addAllocations(planKey_, recipients_, allocations_);
    }

    function claim(string memory planKey_) external {
        Plan storage vestingPlan = vestingPlans[planKey_];
        require(
            address(vestingPlan.token) != address(0),
            "Vesting Plan Not Existed!"
        );
        require(
            block.timestamp >= vestingPlan.startTime,
            "LinearVesting: has not started"
        );
        // claim
        uint amount = _available(msg.sender, vestingPlan);
        require(amount > 0, "Unavailable Token to Claim");
        vestingPlan.token.safeTransfer(msg.sender, amount);
        vestingPlan.claimed[msg.sender] += amount;
        vestingPlan.totalClaimed += amount;
    }

    function available(
        string memory planKey_,
        address address_
    ) external view returns (uint) {
        Plan storage vestingPlan = vestingPlans[planKey_];
        return _available(address_, vestingPlan);
    }

    function released(
        string memory planKey_,
        address address_
    ) external view returns (uint) {
        Plan storage vestingPlan = vestingPlans[planKey_];
        return _released(address_, vestingPlan);
    }

    function outstanding(
        string memory planKey_,
        address address_
    ) external view returns (uint) {
        Plan storage vestingPlan = vestingPlans[planKey_];
        return
            vestingPlan.allocation[address_] - _released(address_, vestingPlan);
    }

    function allocation(
        string memory planKey_,
        address address_
    ) external view returns (uint) {
        Plan storage vestingPlan = vestingPlans[planKey_];
        return vestingPlan.allocation[address_];
    }

    function claimed(
        string memory planKey_,
        address address_
    ) external view returns (uint) {
        Plan storage vestingPlan = vestingPlans[planKey_];
        return vestingPlan.claimed[address_];
    }

    // Add vesting allocation by anyone.
    // The caller need approve for vesting contract to spend token first
    // Only add more allocation, cannot update existed allocation
    function addAllocations(
        string memory planKey_,
        address[] memory recipients_,
        uint[] memory allocations_
    ) public {
        Plan storage vestingPlan = vestingPlans[planKey_];
        require(
            address(vestingPlan.token) != address(0),
            "Vesting Plan Not Existed!"
        );

        uint newTotalAllocation;
        for (uint i = 0; i < recipients_.length; i++) {
            newTotalAllocation = newTotalAllocation + allocations_[i];
            vestingPlan.allocation[recipients_[i]] += allocations_[i];
        }

        // transfer newTotalAllocation from caller to this contract
        vestingPlan.token.safeTransferFrom(
            msg.sender,
            address(this),
            newTotalAllocation
        );

        vestingPlan.totalAllocation += newTotalAllocation;
    }

    function getPlan(
        string memory planKey_
    )
        external
        view
        returns (
            address token,
            uint startTime,
            uint duration,
            uint tgeUnlock,
            uint totalAllocation,
            uint totalClaimed
        )
    {
        Plan storage vestingPlan = vestingPlans[planKey_];
        token = address(vestingPlan.token);
        startTime = vestingPlan.startTime;
        duration = vestingPlan.duration;
        tgeUnlock = vestingPlan.tgeUnlock;
        totalAllocation = vestingPlan.totalAllocation;
        totalClaimed = vestingPlan.totalClaimed;
    }

    // get stuck token
    function withdrawStuckToken(
        address _token,
        address _to
    ) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function _available(
        address address_,
        Plan storage vestingPlan
    ) internal view returns (uint) {
        return _released(address_, vestingPlan) - vestingPlan.claimed[address_];
    }

    function _released(
        address address_,
        Plan storage vestingPlan
    ) internal view returns (uint) {
        if (block.timestamp < vestingPlan.startTime) {
            return 0;
        } else {
            if (
                block.timestamp >= vestingPlan.startTime + vestingPlan.duration
            ) {
                return vestingPlan.allocation[address_];
            } else {
                uint unlockedAtTGE = (vestingPlan.allocation[address_] *
                    vestingPlan.tgeUnlock) / TGE_UNLOCK_BASE;
                uint lockedAtTGE = vestingPlan.allocation[address_] -
                    unlockedAtTGE;

                return
                    unlockedAtTGE +
                    (lockedAtTGE * (block.timestamp - vestingPlan.startTime)) /
                    vestingPlan.duration;
            }
        }
    }
}
