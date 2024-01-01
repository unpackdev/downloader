//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract LPFarmingVesting is Ownable  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Claimed(address vestingAddress, uint256 claimAmount);

    struct VestingInfo {
        address wallet;
        uint256 amountTokenAllocation;
        uint256 amountTGE;
        uint256 durationLock;
        uint256 numberOfClaims;
    }

    struct VestingSchedule {
        uint256 amountOfGrant;
        uint256 amountClaimed;
        uint256 numberOfClaimed;
    }

    uint256 public constant SECONDS_PER_BLOCK = 12;
    uint256 public constant BLOCKS_IN_MONTH = 216000;

    address public xox;
    uint256 public TIME_TOKEN_LAUNCH; //August 20 - at 12:00PM UTC ~ 1692532800
    uint256 public ONE_TIME_UNLOCK; // month = 2592000, year = 31536000
    uint256 public _ONE_MONTH = 2592000;

    uint256 private amountVesting;

    VestingInfo public vestingInfo;
    VestingSchedule public vestingSchedule;

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address xox_,
        VestingInfo memory vestingInfo_,
        uint256 one_time_unlock_
    ) {
        TIME_TOKEN_LAUNCH = 1700913600;
        require(xox_ != address(0), "Cannot zero address");
        xox = xox_;
        ONE_TIME_UNLOCK = one_time_unlock_;
        require(vestingInfo_.wallet != address(0), "Cannot zero address");
        require(vestingInfo_.amountTokenAllocation > 0, "Cannot zero address");
        vestingInfo = vestingInfo_;
        vestingSchedule = VestingSchedule(
            vestingInfo_.amountTokenAllocation,
            0,
            0
        );
        amountVesting = vestingInfo_.amountTokenAllocation.sub(
            vestingInfo_.amountTGE
        );
        _transferOwnership(0x9A29b081E91471302dD7522B211775d90a1622C1);
    }

    /**
     * @dev Withdraw the token out this contract by beneficiary
     */
    function claim() external {
        require(
            msg.sender == vestingInfo.wallet,
            "caller is not the beneficiary"
        );
        require(block.timestamp >= TIME_TOKEN_LAUNCH, "Not Launchtime yet");
        uint256 amountClaim = getPendingAmount(msg.sender);
        require(amountClaim > 0, "nothing to claim");
        IERC20(xox).transfer(msg.sender, amountClaim);
        vestingSchedule.amountClaimed = vestingSchedule.amountClaimed.add(
            amountClaim
        );
        vestingSchedule.numberOfClaimed = _getNumberofClaims();
        emit Claimed(msg.sender, amountClaim);
    }

    /**
     * @dev  View function to see pending amount on frontend
     */
    function getPendingAmount(address account) public view returns (uint256) {
        if (block.timestamp < TIME_TOKEN_LAUNCH) return 0;
        if (account != vestingInfo.wallet) return 0;
        (, uint256 vestedAmount) = _getVestedInfo(
            vestingInfo.amountTGE,
            TIME_TOKEN_LAUNCH
        );
        if (block.timestamp < getCliffTimeLaunch()) {
            return vestedAmount.sub(vestingSchedule.amountClaimed);
        }
        uint256 numberClaimCurrent = _getNumberofClaims();
        if (numberClaimCurrent == 0)
            return vestingInfo.amountTGE.sub(vestingSchedule.amountClaimed);
        if (numberClaimCurrent >= vestingInfo.numberOfClaims)
            return
                vestingSchedule.amountOfGrant.sub(
                    vestingSchedule.amountClaimed
                );
        uint256 remainingAmountTGE = vestedAmount.sub(
            vestingSchedule.amountClaimed
        );
        return
            _calculatorAmountClaim(
                numberClaimCurrent.sub(vestingSchedule.numberOfClaimed),
                vestingInfo.numberOfClaims
            ).add(remainingAmountTGE);
    }

    /**
     * @dev Return claimable amount
     */
    function _calculatorAmountClaim(
        uint256 _part,
        uint256 _distribution
    ) private view returns (uint256) {
        return amountVesting.mul(_part).div(_distribution);
    }

    /**
     * @dev Pre function to calculate What far it's been
     */
    function _getNumberofClaims() private view returns (uint256) {
        return (block.timestamp.sub(TIME_TOKEN_LAUNCH)).div(ONE_TIME_UNLOCK);
    }

    function _getVestedInfo(
        uint256 _grantedAmount,
        uint256 _startTime
    ) internal view returns (uint256 notVestedAmount, uint256 vestedAmount) {
        if (_grantedAmount == 0) return (0, 0);
        // Compute the exact number of seconds vested.
        uint256 secondsVested = block.timestamp - _startTime;
        uint256 blocksVested = secondsVested.div(SECONDS_PER_BLOCK);
        vestedAmount = _grantedAmount.mul(blocksVested).div(BLOCKS_IN_MONTH);
        if (vestedAmount > _grantedAmount) {
            vestedAmount = _grantedAmount;
        }
        return (_grantedAmount - vestedAmount, vestedAmount);
    }

    /**
     * @dev cliff 20% for first month
     */
    function getCliffTimeLaunch() private view returns (uint256) {
        return TIME_TOKEN_LAUNCH.add(_ONE_MONTH);
    }

    // dev environment
    function changeTimeLaunch(uint256 _time) external onlyOwner {
        TIME_TOKEN_LAUNCH = _time;
    }
}
