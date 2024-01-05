// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Bridge is ReentrancyGuard, Ownable {

    using SafeMath for uint;
    using Math for uint;
    using SafeERC20 for IERC20;

    // Can't change hold time rates before 1st May 2021
    uint public constant changeHoldTimeOptions = 1619827200;
    uint public constant DECIMAL_PRECISION_MULTIPLIER = 10**32;
    uint public constant DECIMAL_PRECISION = 10000;
    uint public constant MAX_STAKING_BONUS = 6;
    uint public immutable monthCount;
    uint public nonce;

    struct HoldTimeOption {
        uint endDate;
        uint rate; // Starts on April 2021 till January 2022
        uint16[MAX_STAKING_BONUS] stakingBonusInBP;
    }

    event Stake(
        address indexed user,
        uint amount,
        uint indexed holdTimeOption,
        uint stakeTime,
        uint id
    );

    address immutable token;

    HoldTimeOption[] holdTimeOptions;

    constructor(address _token) public {
        token = _token;
        holdTimeOptions.push(HoldTimeOption(1621814400, DECIMAL_PRECISION_MULTIPLIER.mul(10), [0, 500, 700, 1200, 2500, 6000])); // Before 24th May 2021
        holdTimeOptions.push(HoldTimeOption(1624492800, DECIMAL_PRECISION_MULTIPLIER.mul(9), [0, 400, 500, 1000, 2000, 5000])); // Before 24th June 2021
        holdTimeOptions.push(HoldTimeOption(1627084800, DECIMAL_PRECISION_MULTIPLIER.mul(8), [0, 300, 400, 900, 1800, 4500])); // Before 24th July 2021
        holdTimeOptions.push(HoldTimeOption(1629763200, DECIMAL_PRECISION_MULTIPLIER.mul(7), [0, 200, 400, 800, 1600, 4000])); // Before 24th August 2021
        holdTimeOptions.push(HoldTimeOption(1632441600, DECIMAL_PRECISION_MULTIPLIER.mul(6), [0, 100, 300, 600, 1400, 3500])); // Before 24th September 2021
        holdTimeOptions.push(HoldTimeOption(1635033600, DECIMAL_PRECISION_MULTIPLIER.mul(5), [0, 100, 200, 500, 1200, 3000])); // Before 24th October 2021
        holdTimeOptions.push(HoldTimeOption(1637712000, DECIMAL_PRECISION_MULTIPLIER.mul(4), [0, 100, 100, 400, 1100, 2500])); // Before 24th November 2021
        holdTimeOptions.push(HoldTimeOption(1640304000, DECIMAL_PRECISION_MULTIPLIER.mul(3), [0, 100, 100, 300, 1000, 2000])); // Before 24th December 2021
        holdTimeOptions.push(HoldTimeOption(1642982400, DECIMAL_PRECISION_MULTIPLIER.mul(2), [0, 100, 100, 200, 900, 1500])); // Before 24th January 2022
        holdTimeOptions.push(HoldTimeOption(1645660800, DECIMAL_PRECISION_MULTIPLIER.mul(1), [0, 100, 100, 100, 800, 1000])); // All time after (this time never use)
        monthCount = holdTimeOptions.length;
    }

    function holdTimeOptionsForMonth(uint _month) public view returns (uint endDate, uint optionRate, uint16[6] memory options) {
        uint actualMonth = Math.min(holdTimeOptions.length - 1, _month);
        HoldTimeOption storage timeOption = holdTimeOptions[actualMonth];
        endDate = timeOption.endDate;
        optionRate = timeOption.rate;
        options = timeOption.stakingBonusInBP;
    }

    function monthFromStart(uint time) public view returns (uint) {
        for (uint i; i < holdTimeOptions.length; i++) {
            if (time < holdTimeOptions[i].endDate) {
                return i;
            }
        }
        return holdTimeOptions.length - 1;
    }

    function setHoldTimeOptions(uint _month, uint _endDate, uint _rate, uint16[6] calldata _holdTimeOptions) external onlyOwner {
        require(now >= changeHoldTimeOptions, "Bridge: TOO_EARLY");
        holdTimeOptions[_month] = HoldTimeOption(_endDate, _rate, _holdTimeOptions);
    }

    function convert(uint _stakeTimeOption, uint _amount) external nonReentrant {
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        uint month = monthFromStart(now);
        uint percent = DECIMAL_PRECISION.add(_stakeTimeOptionForMonth(month, _stakeTimeOption));
        uint amountDSCP = _amount.mul(percent) / DECIMAL_PRECISION;
        uint amountDSCPL = amountDSCP.mul(_rate(month)) / DECIMAL_PRECISION_MULTIPLIER;
        nonce++;
        emit Stake(msg.sender, amountDSCPL, _stakeTimeOption, now, nonce);
    }

    function _stakeTimeOptionForMonth(uint _month, uint _stakeTimeOption) private view returns (uint) {
        HoldTimeOption storage timeOption = holdTimeOptions[_month];
        return timeOption.stakingBonusInBP[_stakeTimeOption];
    }

    function _rate(uint _monthFromStart) private view returns (uint) {
        return holdTimeOptions[Math.min(holdTimeOptions.length - 1, _monthFromStart)].rate;
    }
}
