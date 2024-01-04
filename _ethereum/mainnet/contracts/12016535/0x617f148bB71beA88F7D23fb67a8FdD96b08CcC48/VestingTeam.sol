//"SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract VestingTeam is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public startTime = 0;
    uint256 public lastClaimTime = 0;
    uint256 private constant CLAIM_DELAY = 30 days;
    uint256 private constant RELEASEAMOUNT = 187500 ether;
    uint256 private immutable END_DAY;
    uint256 public epoch;
    address private beneficiary = 0x27E4618E9136191410a0DF348ab881BF57551Af9; // team multisig to claim tokens
    IERC20 private immutable KeytangoToken;
    event Claimed(uint256 amount, uint256 epoch);

    constructor(address _KeytangoTokenAddress, uint256 _startTime) public {
        KeytangoToken = IERC20(_KeytangoTokenAddress);
        startTime = _startTime;
        END_DAY = _startTime.add(1440 days); //48 months, 1 month == 30 days
    }

    function getCurrentEpoch() public view returns (uint256) {
        uint256 currentEpoch = block.timestamp.sub(startTime).div(CLAIM_DELAY); // get current epoch
        return currentEpoch;
    }

    function claimTokens() external {
        require(block.timestamp >= startTime, "start time not set");
        require(
            block.timestamp >= lastClaimTime.add(CLAIM_DELAY),
            "delay since last claim not passed"
        );
        if (block.timestamp > END_DAY) {
            claimDust();
        } else {
            uint256 currentEpoch = getCurrentEpoch(); // get current epoch
            if (currentEpoch > epoch) {
                uint256 multiplier = currentEpoch.sub(epoch);
                KeytangoToken.safeTransfer(
                    beneficiary,
                    RELEASEAMOUNT.mul(multiplier)
                );
                epoch = epoch.add(multiplier);
            } else {
                KeytangoToken.safeTransfer(beneficiary, RELEASEAMOUNT);
                epoch = epoch.add(1);
            }
            lastClaimTime = block.timestamp;
            emit Claimed(RELEASEAMOUNT, epoch);
        }
    }

    function getClaimAmount() public view returns (uint256) {
        uint256 currentEpoch = getCurrentEpoch(); // get current epoch
        if (currentEpoch > epoch) {
            uint256 multiplier = currentEpoch.sub(epoch);
            return RELEASEAMOUNT.mul(multiplier);
        } else {
            return RELEASEAMOUNT;
        }
    }

    function claimDust() public {
        require(block.timestamp >= END_DAY, "Vesting not yet finished");
        KeytangoToken.safeTransfer(
            beneficiary,
            KeytangoToken.balanceOf(address(this))
        );
    }

    function setBeneficiary(address _addy) external {
        require(msg.sender == beneficiary);
        beneficiary = _addy;
    }
}
