// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMathInt.sol";

contract Disbursement is Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    IERC20 public debase = IERC20(0x9248c485b0B80f76DA451f167A8db30F33C70907);
    address public policy = 0x989Edd2e87B1706AB25b2E8d9D9480DE3Cc383eD;
    address public claimant = 0xf038C1cfaDAce2C0E5963Ab5C0794B9575e1D2c2;

    uint256 public claimPercentage;

    function setClaimPercentage(uint256 claimPercentage_) external onlyOwner {
        claimPercentage = claimPercentage_;
    }

    function setClaimant(address claimant_) external onlyOwner {
        claimant = claimant_;
    }

    constructor(uint256 claimPercentage_) public {
        claimPercentage = claimPercentage_;
    }

    function checkStabilizerAndGetReward(
        int256 supplyDelta_,
        int256 rebaseLag_,
        uint256 exchangeRate_,
        uint256 debasePolicyBalance
    ) external returns (uint256 rewardAmount_) {
        require(
            msg.sender == policy,
            "Only debase policy contract can call this"
        );

        if (claimPercentage != 0) {
            uint256 rewardToClaim =
                debasePolicyBalance.mul(claimPercentage).div(10**18);

            claimPercentage = 0;
            return rewardToClaim;
        }

        return 0;
    }

    function claimantClaimReward() external onlyOwner {
        uint256 claimable = debase.balanceOf(address(this));
        if (claimable != 0) {
            debase.transfer(claimant, claimable);
        }
    }
}
