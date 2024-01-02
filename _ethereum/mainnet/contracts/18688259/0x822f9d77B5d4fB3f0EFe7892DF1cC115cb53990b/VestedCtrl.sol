// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./SafeERC20.sol";

contract VestedCTRL is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Claim(address indexed claimer, uint256 initialAmount);

    uint16[] public cumulativeScheduleInBPS;
    uint256 public immutable timePeriodInSeconds;
    uint256 public immutable startTime;

    mapping(address => uint128) public claimedByAccount;

    IERC20 public immutable ctrl;

    constructor(
        IERC20 ctrl_,
        uint16[] memory cumulativeScheduleInBPS_,
        uint256 timePeriodInDays
    ) ERC20("vCTRL", "VCTRL") {
        ctrl = ctrl_;
        startTime = block.timestamp;
        cumulativeScheduleInBPS = cumulativeScheduleInBPS_;
        timePeriodInSeconds = timePeriodInDays * 1 days;
    }

    function multiMint(
        address[] calldata accounts,
        uint256[] calldata initialAmounts
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            mint(accounts[i], initialAmounts[i]);
        }
    }

    function mint(address account, uint256 initialAmount) public onlyOwner {
        _mint(account, initialAmount);
    }

    function burn(address account, uint256 initialAmount) public onlyOwner {
        _burn(account, initialAmount);
    }

    function _claim(address account) private returns (uint128 claimable) {
        claimable = uint128(claimableOf(account));
        if (claimable > 0) {
            claimedByAccount[account] += claimable;
            _burn(account, claimable);
            emit Claim(account, claimable);
        }
    }

    function _vestingSnapshot(
        address account
    ) internal view returns (uint256, uint256, uint256) {
        uint128 claimed = claimedByAccount[account];
        uint256 balance = balanceOf(account);
        uint256 initialAllocation = balance + claimed;
        return (
            _totalVestedOf(initialAllocation, block.timestamp),
            claimed,
            balance
        );
    }

    function claim(address recipient) external nonReentrant {
        uint256 claimable = _claim(recipient);
        require(claimable > 0, "VMEOWL/ZERO_VESTED");
        ctrl.transfer(recipient, claimable);
    }

    function _totalVestedOf(
        uint256 initialAllocation,
        uint256 currentTime
    ) internal view returns (uint256 total) {
        if (currentTime <= startTime) {
            return 0;
        }
        uint16[] memory _cumulativeScheduleInBPS = cumulativeScheduleInBPS;
        uint256 elapsed = Math.min(
            currentTime - startTime,
            _cumulativeScheduleInBPS.length * timePeriodInSeconds
        );
        uint256 currentPeriod = elapsed / timePeriodInSeconds;
        uint256 elapsedInCurrentPeriod = elapsed % timePeriodInSeconds;
        uint256 cumulativeMultiplierPast = 0;

        if (currentPeriod > 0) {
            cumulativeMultiplierPast = _cumulativeScheduleInBPS[
                currentPeriod - 1
            ];
            total = (initialAllocation * cumulativeMultiplierPast) / 10000;
        }

        if (elapsedInCurrentPeriod > 0) {
            uint256 currentMultiplier = _cumulativeScheduleInBPS[
                currentPeriod
            ] - cumulativeMultiplierPast;
            uint256 periodAllocation = (initialAllocation * currentMultiplier) /
                10000;
            total +=
                (periodAllocation * elapsedInCurrentPeriod) /
                timePeriodInSeconds;
        }
    }

    function vestedOf(address account) external view returns (uint256) {
        (uint256 vested, , ) = _vestingSnapshot(account);
        return vested;
    }

    function claimableOf(address account) public view returns (uint256) {
        (uint256 vested, uint256 claimed, uint256 balance) = _vestingSnapshot(
            account
        );
        return Math.min(vested - claimed, balance);
    }

    function rescue() external onlyOwner {
        require(
            block.timestamp >
                startTime +
                    (cumulativeScheduleInBPS.length * timePeriodInSeconds),
            "vMEOWL/RESCUE_BEFORE_END"
        );
        ctrl.transfer(owner(), ctrl.balanceOf(address(this)));
    }
}
